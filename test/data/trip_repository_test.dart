import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/data/database.dart' show AppDatabase;
import 'package:speedster/data/trip_repository.dart';
import 'package:speedster/domain/track_point.dart';
import 'package:speedster/domain/trip.dart';
import 'package:speedster/stats/stats_engine.dart';

Trip newTrip() => Trip(
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

void main() {
  late AppDatabase db;
  late DriftTripRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftTripRepository(db);
  });
  tearDown(() => db.close());

  test('create, add points, finalize, read back', () async {
    final id = await repo.createTrip(newTrip());
    await repo.addPoints(id, [
      TrackPoint(
        tripId: id,
        lat: 50,
        lng: 6,
        speed: 10,
        altitude: 100,
        accuracy: 3,
        timestamp: DateTime(2026),
      ),
    ]);
    await repo.finalizeTrip(
      id,
      const TripStats(
        maxSpeed: 10,
        avgSpeed: 10,
        distance: 5,
        elevationGain: 0,
        durationSeconds: 3,
        zeroToHundredSeconds: null,
      ),
      DateTime(2026, 1, 1, 12),
    );
    final trips = await repo.keptTrips();
    expect(trips.single.maxSpeed, 10);
    expect((await repo.pointsFor(id)).length, 1);
  });

  test('setKept(false) hides trip from keptTrips', () async {
    final id = await repo.createTrip(newTrip());
    await repo.setKept(id, false);
    expect(await repo.keptTrips(), isEmpty);
  });

  test('deleteAll clears trips and points', () async {
    final id = await repo.createTrip(newTrip());
    await repo.addPoints(id, [
      TrackPoint(
        tripId: id,
        lat: 50,
        lng: 6,
        speed: 10,
        altitude: 100,
        accuracy: 3,
        timestamp: DateTime(2026),
      ),
    ]);
    await repo.deleteAll();
    expect(await repo.keptTrips(), isEmpty);
    expect(await repo.pointsFor(id), isEmpty);
  });
}
