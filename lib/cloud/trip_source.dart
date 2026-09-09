import 'package:dio/dio.dart';
import 'package:speedster/cloud/token_store.dart';
import 'package:speedster/data/trip_repository.dart';
import 'package:speedster/domain/track_point.dart';
import 'package:speedster/domain/trip.dart';

/// Woher die Fahrtenliste und die Punkte einer Fahrt kommen.
///
/// Gegenstueck zu `HeatSource`: bei aktiver Cloud ist der Server die
/// Wahrheit, das Geraet haelt nur einen Vorrat der zuletzt gefahrenen
/// Strecken (siehe [TripCacheService]).
abstract class TripSource {
  Future<List<Trip>> keptTrips();

  /// Punkte einer Fahrt. [localId] ist die lokale Zeilen-Id, sofern die
  /// Fahrt im Vorrat liegt; sonst null.
  ///
  /// Zwei Skalare statt der ganzen [Trip]: der Riverpod-Provider ist eine
  /// Family ueber diesen Schluessel, und `Trip` traegt keine Wertgleichheit
  /// -- die Family wuerde bei jedem Rebuild neu laden.
  Future<List<TrackPoint>> pointsFor({required String clientUuid, int? localId});
}

class LocalTripSource implements TripSource {
  LocalTripSource(this.repo);

  final TripRepository repo;

  @override
  Future<List<Trip>> keptTrips() => repo.keptTrips();

  @override
  Future<List<TrackPoint>> pointsFor({
    required String clientUuid,
    int? localId,
  }) async =>
      localId == null ? const [] : repo.pointsFor(localId);
}

class CloudTripSource implements TripSource {
  CloudTripSource(this.dio);

  final Dio dio;

  @override
  Future<List<Trip>> keptTrips() async {
    final trips = <Trip>[];
    var page = 1;
    while (true) {
      final res = await dio.get<Map<String, dynamic>>(
        '/trips',
        queryParameters: {'page': page},
      );
      final body = res.data ?? const {};
      for (final raw in (body['data'] as List? ?? const [])) {
        trips.add(tripFromJson(raw as Map<String, dynamic>));
      }
      // Laravels Paginator liefert next_page_url = null auf der letzten
      // Seite. Auf last_page zu rechnen waere fragiler: kommen waehrend
      // des Durchlaufs Fahrten hinzu, verschiebt sich die Zahl.
      if (body['next_page_url'] == null) break;
      page++;
    }
    return trips;
  }

  @override
  Future<List<TrackPoint>> pointsFor({
    required String clientUuid,
    int? localId,
  }) async {
    if (clientUuid.isEmpty) return const [];
    final res = await dio.get<Map<String, dynamic>>('/trips/$clientUuid');
    return pointsFromJson(res.data ?? const {});
  }
}

/// Waehlt die Quelle und faengt Cloud-Ausfaelle ab.
///
/// Dasselbe Muster wie `FallbackHeatSource`, inklusive der Behandlung
/// eines abgelaufenen Tokens: verwerfen, damit die Quellenwahl beim
/// naechsten Aufruf von selbst auf lokal umschaltet.
class FallbackTripSource implements TripSource {
  FallbackTripSource(this.cloud, this.local, this.tokenStore, this.repo);

  final TripSource cloud;
  final TripSource local;
  final TokenStore tokenStore;
  final TripRepository repo;

  @override
  Future<List<Trip>> keptTrips() async {
    if (await tokenStore.read() == null) {
      return local.keptTrips();
    }
    try {
      final remote = await cloud.keptTrips();
      // Lokale Zeilen-Id nachtragen, wo die Fahrt im Vorrat liegt: nur
      // damit kann pointsFor() sie ohne Netz aus der Datenbank holen.
      // Ohne diesen Abgleich braeuchte selbst die zuletzt gefahrene
      // Strecke fuer ihre Detailansicht eine Verbindung.
      final index = await repo.clientUuidIndex();
      final known = {for (final trip in remote) trip.clientUuid};

      // Noch nicht hochgeladene Fahrten kommen dazu.
      //
      // Ohne sie verschwindet eine gerade gefahrene Strecke aus der
      // Liste, bis der Upload durch ist -- ohne Netz also womoeglich
      // tagelang. Sie liegt auf dem Geraet, und der Nutzer sieht sie
      // nicht: schlimmer als eine fehlende Fahrt ist eine, die es gibt
      // und die verschwiegen wird.
      final pending = [
        for (final trip in await repo.unsyncedTrips())
          if (!known.contains(trip.clientUuid)) trip,
      ];

      return [
        ...pending,
        for (final trip in remote)
          index.containsKey(trip.clientUuid)
              ? trip.copyWith(id: index[trip.clientUuid])
              : trip,
      ]..sort((a, b) => b.startTime.compareTo(a.startTime));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await tokenStore.clear();
      }
      return local.keptTrips();
    }
  }

  @override
  Future<List<TrackPoint>> pointsFor({
    required String clientUuid,
    int? localId,
  }) async {
    // Liegt die Fahrt im Vorrat, ist die lokale Kopie vollstaendig und
    // spart die Abfrage -- und funktioniert ohne Netz.
    if (localId != null) {
      final cached =
          await local.pointsFor(clientUuid: clientUuid, localId: localId);
      if (cached.isNotEmpty) return cached;
    }
    if (await tokenStore.read() == null) return const [];
    try {
      return await cloud.pointsFor(clientUuid: clientUuid);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await tokenStore.clear();
      }
      // Ohne Netz und ohne lokale Kopie gibt es die Punkte schlicht nicht.
      // Die Detailansicht zeigt dafuer ihren Leer-Hinweis.
      return const [];
    }
  }
}

/// Eine Fahrt aus einer Serverantwort. Die Zeitstempel kommen in UTC.
///
/// `.toLocal()` ist nicht kosmetisch: die Oberflaeche formatiert
/// [Trip.startTime] ohne eigene Umrechnung, ein UTC-Wert erschiene also um
/// den Zeitzonenversatz verschoben -- eine Fahrt um 19 Uhr staende als
/// 17-Uhr-Fahrt in der Liste.
Trip tripFromJson(Map<String, dynamic> data) => Trip(
      startTime: _time(data['start_time'])!,
      endTime: _time(data['end_time']),
      maxSpeed: _number(data['max_speed']),
      avgSpeed: _number(data['avg_speed']),
      distance: _number(data['distance']),
      elevationGain: _number(data['elevation_gain']),
      durationSeconds: (data['duration_seconds'] as num? ?? 0).toInt(),
      zeroToHundredSeconds: (data['zero_to_hundred_seconds'] as num?)
          ?.toDouble(),
      // Der Server speichert nur behaltene Fahrten: hochgeladen wird aus
      // unsyncedTrips(), und das filtert auf kept.
      kept: true,
      clientUuid: data['client_uuid'] as String? ?? '',
      // Liegt bereits in der Cloud -- ohne diese Markierung schoebe der
      // naechste Upload-Lauf eine zwischengespeicherte Fahrt wieder hoch.
      syncedAt: DateTime.now(),
    );

/// Punkte aus der Detailantwort. [tripId] bleibt 0, solange die Fahrt
/// nicht lokal geschrieben wird; der Cache setzt ihn beim Einfuegen.
List<TrackPoint> pointsFromJson(Map<String, dynamic> data, {int tripId = 0}) => [
      for (final raw in (data['points'] as List? ?? const []))
        if (raw is Map<String, dynamic>)
          TrackPoint(
            tripId: tripId,
            lat: _number(raw['lat']),
            lng: _number(raw['lng']),
            speed: _number(raw['speed']),
            altitude: _number(raw['altitude']),
            accuracy: _number(raw['accuracy']),
            timestamp: _time(raw['t'])!,
          ),
    ];

DateTime? _time(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.parse(value).toLocal();
}

/// Fehlende Zahlenwerte auf 0: Geschwindigkeit, Hoehe und Genauigkeit sind
/// serverseitig als `nullable` validiert. Die App schickt sie immer mit,
/// der Fall entsteht also nur bei Fremddaten.
double _number(Object? value) => (value as num? ?? 0).toDouble();
