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

  Future<void> syncOnce() async {
    if (await tokenStore.read() == null) return; // not logged in
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
        if (e.response?.statusCode == 401) {
          // Token invalid/expired: stop and force re-login.
          await tokenStore.clear();
          return;
        }
        // Network/5xx: leave unsynced, retry next cycle.
        return;
      }
    }
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
