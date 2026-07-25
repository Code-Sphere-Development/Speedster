import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/data/database.dart' show AppDatabase;
import 'package:speedster/data/trip_repository.dart';
import 'package:speedster/detection/trip_detector.dart';
import 'package:speedster/domain/sample.dart';
import 'package:speedster/recording/trip_recorder.dart';
import 'package:speedster/sensors/location_service.dart';

Sample s(double speed, int sec) => Sample(
      lat: 50,
      lng: 6,
      speed: speed,
      altitude: 100,
      accuracy: 3,
      timestamp: DateTime(2026, 1, 1, 12, 0, sec),
    );

void main() {
  test('records a full trip from motion to stop', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repo = DriftTripRepository(db);
    final source = FakeSampleSource([
      s(10, 0), s(10, 6), // start
      s(20, 10), s(28, 14), // driving
      s(0, 20), s(0, 70), // stop after stopWindow
    ]);
    final rec = TripRecorder(
      source: source,
      detector: TripDetector(const DetectorConfig()),
      repo: repo,
    );
    await rec.start();
    await rec.stop();
    final trips = await repo.keptTrips();
    expect(trips, hasLength(1));
    expect(trips.single.maxSpeed, 28);
    await db.close();
  });
}
