import 'package:dio/dio.dart';
import 'package:speedster/data/trip_repository.dart';
import 'package:speedster/domain/trip.dart';
import 'package:speedster/cloud/token_store.dart';

/// Pushes locally-kept, not-yet-synced trips to the cloud. Idempotent on the
/// server via client_uuid, so a failed/retried upload never duplicates.
class CloudSyncService {
  CloudSyncService({
    required this.dio,
    required this.repo,
    required this.tokenStore,
  });

  final Dio dio;
  final TripRepository repo;
  final TokenStore tokenStore;

  /// Fahrten, die der Server in diesem Lauf zurueckgewiesen hat.
  ///
  /// Nur zur Auskunft nach aussen -- gespeichert wird nichts: beim
  /// naechsten Lauf wird es erneut versucht, denn die Ursache kann
  /// behoben sein (ein Serverstand, der das Format inzwischen annimmt).
  final rejected = <String>{};

  Future<void> syncOnce() async {
    if (await tokenStore.read() == null) return; // not logged in
    rejected.clear();
    final pending = await repo.unsyncedTrips();

    for (final trip in pending) {
      try {
        final points = await repo.pointsFor(trip.id!);
        final res = await dio.post('/trips', data: _payload(trip, points));
        final code = res.statusCode ?? 0;
        if (code >= 200 && code < 300) {
          await repo.markSynced(trip.clientUuid);
        }
      } on DioException catch (e) {
        final status = e.response?.statusCode;

        if (status == 401) {
          // Token ungueltig oder abgelaufen: anhalten und neu anmelden
          // lassen. Weitere Versuche waeren alle vergeblich.
          await tokenStore.clear();
          return;
        }

        // Weist der Server die Fahrt selbst zurueck (4xx), hilft kein
        // erneuter Versuch -- sie bleibt liegen, aber die naechste kommt
        // dran.
        //
        // Vorher brach die Schleife bei jedem Fehler ab. Eine einzige
        // Fahrt, die der Server nicht annimmt, hielt damit alle spaeteren
        // dauerhaft und lautlos auf: in der Bestenliste stand weiterhin
        // ein alter Wert, obwohl laengst schneller gefahren worden war.
        if (status != null && status >= 400 && status < 500) {
          rejected.add(trip.clientUuid);
          continue;
        }

        // Netzfehler oder 5xx: der naechste Lauf versucht es erneut, und
        // zwar wieder von vorn -- die Reihenfolge bleibt so erhalten.
        break;
      }
    }
  }

  /// Traegt Zweck und Notiz einer bereits hochgeladenen Fahrt nach.
  ///
  /// Eigener Endpunkt statt eines erneuten Hochladens: der Zweck steht
  /// oft erst nach der Fahrt fest, und die gesamte Strecke noch einmal zu
  /// senden waere fuer zwei Felder verschwendet.
  ///
  /// Ohne Anmeldung geschieht nichts -- ohne Cloud gibt es dort keine
  /// Fahrt, die sich aendern liesse.
  Future<void> updatePurpose(
    String clientUuid,
    String? purpose,
    String? note,
  ) async {
    if (await tokenStore.read() == null) return;

    await dio.patch('/trips/$clientUuid', data: {
      'purpose': purpose,
      'note': note,
    });
  }

  Map<String, dynamic> _payload(Trip trip, List points) => {
        'client_uuid': trip.clientUuid,
        'start_time': trip.startTime.toUtc().toIso8601String(),
        'end_time': trip.endTime?.toUtc().toIso8601String(),
        'max_speed': trip.maxSpeed,
        'avg_speed': trip.avgSpeed,
        'distance': trip.distance,
        'duration_seconds': trip.durationSeconds,
        'zero_to_hundred_seconds': trip.zeroToHundredSeconds,
        'purpose': trip.purpose,
        'note': trip.note,
        // Beim Fahrtende festgehalten, nicht hier bestimmt: wer
        // zwischendurch das Standardfahrzeug wechselt, saehe seine
        // wartenden Fahrten sonst am neuen Auto haengen.
        'vehicle_id': trip.cloudVehicleId,
        'elevation_gain': trip.elevationGain,
        'points': [
          for (final p in points)
            {
              'lat': p.lat,
              'lng': p.lng,
              'speed': p.speed,
              'altitude': p.altitude,
              'accuracy': p.accuracy,
              't': p.timestamp.toUtc().toIso8601String(),
            },
        ],
      };
}
