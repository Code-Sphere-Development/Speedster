import 'package:dio/dio.dart';
import 'package:speedster/cloud/token_store.dart';
import 'package:speedster/cloud/trip_source.dart';
import 'package:speedster/data/trip_repository.dart';

/// Ergebnis eines Cache-Laufs.
///
/// [complete] trennt "fertig" von "abgebrochen": bei Netzabbruch oder
/// abgelaufenem Token bleibt das bereits Geholte liegen, der Rest kommt
/// beim naechsten Start. Ohne diese Unterscheidung meldete die
/// Oberflaeche einen Teilabzug als Erfolg.
class CacheResult {
  const CacheResult({
    required this.cached,
    required this.evicted,
    required this.complete,
  });

  static const skipped = CacheResult(cached: 0, evicted: 0, complete: false);

  final int cached;
  final int evicted;
  final bool complete;
}

/// Naht fuer den Cache-Lauf beim App-Start.
///
/// Dasselbe Muster wie `HeatSource` und `TripSource`: die Oberflaeche
/// kennt nur diese Schnittstelle, Tests setzen eine leere Umsetzung ein,
/// statt eine Datenbank und einen HTTP-Client mitzuschleppen.
abstract class TripCache {
  Future<CacheResult> refresh();
}

/// Haelt lokal einen Vorrat der zuletzt gefahrenen Strecken vor.
///
/// Bei aktiver Cloud ist der Server die Wahrheit; das Geraet braucht
/// trotzdem etwas in der Hand, wenn kein Netz da ist. Der Vorrat umfasst
/// die [keepTrips] neuesten Fahrten samt Punkten -- genug fuer die
/// Detailansicht der zuletzt gefahrenen Strecken, ohne die gesamte
/// Historie doppelt vorzuhalten.
///
/// Der Lauf ist idempotent: Fahrten, deren `client_uuid` lokal schon
/// existiert, werden uebersprungen. Ein Abbruch mittendrin ist deshalb
/// folgenlos.
class TripCacheService implements TripCache {
  TripCacheService({
    required this.dio,
    required this.repo,
    required this.tokenStore,
  });

  /// Wie viele Fahrten lokal vorgehalten werden.
  static const int keepTrips = 10;

  final Dio dio;
  final TripRepository repo;
  final TokenStore tokenStore;

  @override
  Future<CacheResult> refresh() async {
    if (await tokenStore.read() == null) {
      // Ohne Cloud ist die lokale Datenbank kein Vorrat, sondern der
      // einzige Bestand -- hier darf nichts verworfen werden.
      return CacheResult.skipped;
    }

    var cached = 0;
    try {
      // Seite 1 genuegt: /trips liefert nach start_time absteigend, die
      // ersten keepTrips sind also die neuesten.
      final res = await dio.get<Map<String, dynamic>>(
        '/trips',
        queryParameters: {'page': 1},
      );
      final rows = ((res.data ?? const {})['data'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .take(keepTrips);

      final known = await repo.clientUuidIndex();
      for (final row in rows) {
        final uuid = row['client_uuid'] as String?;
        if (uuid == null || uuid.isEmpty || known.containsKey(uuid)) continue;
        await _cacheOne(uuid);
        cached++;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await tokenStore.clear();
      }
      // Abgebrochen: nicht raeumen. Was hier liegt, ist womoeglich das
      // Einzige, was der Nutzer gerade hat.
      return CacheResult(cached: cached, evicted: 0, complete: false);
    }

    final evicted = await repo.evictSyncedBeyond(keepTrips);
    return CacheResult(cached: cached, evicted: evicted, complete: true);
  }

  Future<void> _cacheOne(String clientUuid) async {
    final res = await dio.get<Map<String, dynamic>>('/trips/$clientUuid');
    final data = res.data ?? const <String, dynamic>{};

    final tripId = await repo.createTrip(tripFromJson({
      ...data,
      'client_uuid': clientUuid,
    }));

    final points = pointsFromJson(data, tripId: tripId);
    if (points.isNotEmpty) {
      await repo.addPoints(tripId, points);
    }
  }
}
