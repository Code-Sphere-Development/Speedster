import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/data/database.dart' show AppDatabase;
import 'package:speedster/data/trip_repository.dart';
import 'package:speedster/domain/trip.dart';

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
  test('new trips get a client uuid, then flip synced', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repo = DriftTripRepository(db);

    await repo.createTrip(newTrip());
    final trip = (await repo.keptTrips()).single;

    expect(trip.clientUuid, isNotEmpty);
    expect(trip.syncedAt, isNull);
    expect(await repo.unsyncedTrips(), hasLength(1));

    await repo.markSynced(trip.clientUuid);
    expect(await repo.unsyncedTrips(), isEmpty);

    await db.close();
  });
}
