import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/data/database.dart' show AppDatabase;
import 'package:speedster/data/trip_repository.dart';
import 'package:speedster/domain/trip.dart';

/// Eine *abgeschlossene* Fahrt.
///
/// Mit Endzeit, weil das der Normalfall ist: ohne sie gilt die Fahrt als
/// noch laufend, und keptTrips wie unsyncedTrips halten sie bewusst
/// zurueck (siehe TripRepair).
Trip newTrip({bool finished = true}) => Trip(
      startTime: DateTime(2026),
      endTime: finished ? DateTime(2026, 1, 1, 0, 30) : null,
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

    // Eine noch laufende Fahrt wird gar nicht erst angeboten: sie traegt
    // die Nullen, mit denen sie angelegt wurde, und der Stempel nach dem
    // Upload machte sie dauerhaft unkorrigierbar.
    await repo.createTrip(newTrip(finished: false));
    expect(await repo.unsyncedTrips(), isEmpty);

    await db.close();
  });
}
