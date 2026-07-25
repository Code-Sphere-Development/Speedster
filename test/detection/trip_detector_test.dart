import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/detection/trip_detector.dart';
import 'package:speedster/domain/sample.dart';

Sample mv(double speed, int sec, {double acc = 5}) => Sample(
      lat: 50,
      lng: 6,
      speed: speed,
      altitude: 100,
      accuracy: acc,
      timestamp: DateTime(2026, 1, 1, 12, 0, sec),
    );

void main() {
  test('emits started after sustained motion over startWindow', () {
    final d = TripDetector(const DetectorConfig());
    expect(d.update(mv(10, 0)), isNull); // moving begins
    expect(d.update(mv(10, 3)), isNull); // still within window
    expect(d.update(mv(10, 6)), TripEvent.started); // window elapsed
    expect(d.isDriving, isTrue);
  });

  test('brief stop under stopWindow does not end trip', () {
    final d = TripDetector(const DetectorConfig());
    d
      ..update(mv(10, 0))
      ..update(mv(10, 6)); // driving
    expect(d.update(mv(0, 10)), isNull); // red light
    expect(d.update(mv(10, 20)), isNull); // moving again
    expect(d.isDriving, isTrue);
  });

  test('emits stopped after stopWindow of stillness', () {
    final d = TripDetector(const DetectorConfig());
    d
      ..update(mv(10, 0))
      ..update(mv(10, 6));
    expect(d.update(mv(0, 10)), isNull);
    expect(d.update(mv(0, 60)), TripEvent.stopped); // >45s still
    expect(d.isDriving, isFalse);
  });

  test('ignores low-accuracy samples', () {
    final d = TripDetector(const DetectorConfig());
    expect(d.update(mv(10, 0, acc: 100)), isNull);
    expect(d.update(mv(10, 6, acc: 100)), isNull);
    expect(d.isDriving, isFalse);
  });
}
