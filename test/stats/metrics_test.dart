import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/domain/track_point.dart';
import 'package:speedster/stats/stats_engine.dart';

TrackPoint p(double speed, {double alt = 100, int t = 0}) => TrackPoint(
      tripId: 1,
      lat: 50,
      lng: 6,
      speed: speed,
      altitude: alt,
      accuracy: 3,
      timestamp: DateTime(2026, 1, 1, 12, 0, t),
    );

void main() {
  test('max and avg speed', () {
    final s = StatsEngine.compute([p(0, t: 0), p(10, t: 1), p(30, t: 2)]);
    expect(s.maxSpeed, 30);
    expect(s.avgSpeed, closeTo((0 + 10 + 30) / 3, 0.01));
  });

  test('elevation gain counts only ascents', () {
    final s = StatsEngine.compute([
      p(5, alt: 100, t: 0),
      p(5, alt: 120, t: 1),
      p(5, alt: 110, t: 2),
      p(5, alt: 130, t: 3),
    ]);
    expect(s.elevationGain, 40); // +20 then +20; the -10 ignored
  });

  test('zeroToHundred: seconds from first >0 to first >=27.78 m/s', () {
    final s = StatsEngine.compute([p(0, t: 0), p(5, t: 1), p(20, t: 3), p(28, t: 5)]);
    expect(s.zeroToHundredSeconds, closeTo(4, 0.001)); // t=1 (moving) .. t=5
  });

  test('zeroToHundred null when 100 never reached', () {
    final s = StatsEngine.compute([p(0, t: 0), p(10, t: 1)]);
    expect(s.zeroToHundredSeconds, isNull);
  });
}
