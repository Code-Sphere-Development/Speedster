import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/domain/sample.dart';
import 'package:speedster/domain/trip.dart';

void main() {
  test('Sample holds SI values', () {
    final s = Sample(
      lat: 50.9,
      lng: 6.9,
      speed: 13.4,
      altitude: 55,
      accuracy: 4,
      timestamp: DateTime(2026),
      accelMagnitude: 9.9,
    );
    expect(s.speed, 13.4);
  });

  test('Trip.copyWith overrides only given fields', () {
    final t = Trip(
      startTime: DateTime(2026),
      endTime: null,
      maxSpeed: 0,
      avgSpeed: 0,
      distance: 0,
      elevationGain: 0,
      durationSeconds: 0,
      zeroToHundredSeconds: null,
      kept: true,
    );
    expect(t.copyWith(maxSpeed: 40).maxSpeed, 40);
    expect(t.copyWith(maxSpeed: 40).kept, true);
  });
}
