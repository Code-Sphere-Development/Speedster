import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/domain/track_point.dart';
import 'package:speedster/stats/stats_engine.dart';

void main() {
  test('haversine between two ~111m-apart points', () {
    // 0.001 deg latitude ~= 111.19 m
    final d = StatsEngine.haversineMeters(50.0, 6.0, 50.001, 6.0);
    expect(d, closeTo(111.2, 1.0));
  });

  test('compute sums distance and duration', () {
    final t0 = DateTime(2026, 1, 1, 12, 0, 0);
    final pts = [
      TrackPoint(
        tripId: 1,
        lat: 50.0,
        lng: 6.0,
        speed: 0,
        altitude: 100,
        accuracy: 3,
        timestamp: t0,
      ),
      TrackPoint(
        tripId: 1,
        lat: 50.001,
        lng: 6.0,
        speed: 20,
        altitude: 100,
        accuracy: 3,
        timestamp: t0.add(const Duration(seconds: 10)),
      ),
    ];
    final s = StatsEngine.compute(pts);
    expect(s.distance, closeTo(111.2, 1.0));
    expect(s.durationSeconds, 10);
  });
}
