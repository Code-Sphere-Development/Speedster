import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/domain/sample.dart';
import 'package:speedster/sensors/location_service.dart';

void main() {
  test('FakeSampleSource replays samples in order', () async {
    final samples = [
      Sample(
        lat: 50,
        lng: 6,
        speed: 0,
        altitude: 100,
        accuracy: 3,
        timestamp: DateTime(2026, 1, 1, 12, 0, 0),
      ),
      Sample(
        lat: 50,
        lng: 6,
        speed: 10,
        altitude: 100,
        accuracy: 3,
        timestamp: DateTime(2026, 1, 1, 12, 0, 1),
      ),
    ];
    final src = FakeSampleSource(samples);
    expect(await src.samples().toList(), samples);
  });
}
