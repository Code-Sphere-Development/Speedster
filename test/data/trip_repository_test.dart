import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/data/database.dart' show AppDatabase;
import 'package:speedster/data/trip_repository.dart';
import 'package:speedster/heat/heat_folder.dart';
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

  test('deleteAll raeumt auch die Heatmap-Aggregate', () async {
    final id = await repo.createTrip(newTrip());
    await repo.addPoints(id, [
      for (var i = 0; i < 20; i++)
        TrackPoint(
          tripId: id,
          lat: 50.0 + (i * 12) / 111320.0,
          lng: 6.0,
          speed: 20,
          altitude: 100,
          accuracy: 5,
          timestamp: DateTime.utc(2026, 1, 1).add(Duration(seconds: i)),
        ),
    ]);
    await HeatFolder(db, runner: (fn, msg) async => fn(msg)).foldPending();
    expect(await db.select(db.heatEdges).get(), isNotEmpty);

    await repo.deleteAll();

    // Sonst ueberlebt die Heatmap ein "alle Daten loeschen".
    expect(await db.select(db.heatEdges).get(), isEmpty);
    expect(await db.select(db.heatCells).get(), isEmpty);
  });

  test('setKept(false) invalidiert die Heatmap-Aggregate', () async {
    final id = await repo.createTrip(newTrip());
    await repo.addPoints(id, [
      for (var i = 0; i < 20; i++)
        TrackPoint(
          tripId: id,
          lat: 50.0 + (i * 12) / 111320.0,
          lng: 6.0,
          speed: 20,
          altitude: 100,
          accuracy: 5,
          timestamp: DateTime.utc(2026, 1, 1).add(Duration(seconds: i)),
        ),
    ]);
    await HeatFolder(db, runner: (fn, msg) async => fn(msg)).foldPending();
    expect(await db.select(db.heatEdges).get(), isNotEmpty);

    await repo.setKept(id, false);

    // Verworfene Beifahrer-Fahrten duerfen in der Heatmap nicht leuchten.
    expect(await db.select(db.heatEdges).get(), isEmpty);
  });

  group('evictSyncedBeyond', () {
    Future<int> synced(DateTime start, {String uuid = ''}) => repo.createTrip(
          Trip(
            startTime: start,
            endTime: start.add(const Duration(minutes: 10)),
            maxSpeed: 20,
            avgSpeed: 10,
            distance: 5000,
            elevationGain: 10,
            durationSeconds: 600,
            zeroToHundredSeconds: null,
            kept: true,
            clientUuid: uuid,
            syncedAt: DateTime(2026, 6),
          ),
        );

    test('loescht die Punkte der verworfenen Fahrten mit', () async {
      final alt = await synced(DateTime(2026, 1, 1), uuid: 'alt');
      await repo.addPoints(alt, [
        TrackPoint(
          tripId: alt,
          lat: 50,
          lng: 7,
          speed: 10,
          altitude: 50,
          accuracy: 5,
          timestamp: DateTime(2026, 1, 1),
        ),
      ]);
      final neu = await synced(DateTime(2026, 2, 1), uuid: 'neu');

      expect(await repo.evictSyncedBeyond(1), 1);
      expect(await repo.pointsFor(alt), isEmpty);
      expect(await repo.pointsFor(neu), isEmpty);
      expect((await repo.keptTrips()).single.clientUuid, 'neu');
    });

    test('laesst die Heatmap-Aggregate stehen', () async {
      final alt = await synced(DateTime(2026, 1, 1), uuid: 'alt');
      await repo.addPoints(alt, [
        for (var i = 0; i < 40; i++)
          TrackPoint(
            tripId: alt,
            lat: 50 + i * 0.0005,
            lng: 7,
            speed: 10,
            altitude: 50,
            accuracy: 5,
            timestamp: DateTime(2026, 1, 1).add(Duration(seconds: i)),
          ),
      ]);
      await HeatFolder(db).foldPending();
      final vorher = (await db.select(db.heatEdges).get()).length;
      expect(vorher, greaterThan(0), reason: 'sonst prueft der Test nichts');

      await synced(DateTime(2026, 2, 1), uuid: 'neu');
      expect(await repo.evictSyncedBeyond(1), 1);

      expect(
        (await db.select(db.heatEdges).get()).length,
        vorher,
        reason: 'der Vorrat darf die Heatmap nicht schmaelern',
      );
    });

    test('verschont eine noch nicht bestaetigte Fahrt', () async {
      await repo.createTrip(newTrip());
      await synced(DateTime(2026, 2, 1), uuid: 'neu');

      expect(await repo.evictSyncedBeyond(1), 0);
      expect(await repo.keptTrips(), hasLength(2));
    });

    test('tut nichts, wenn nichts jenseits der Grenze liegt', () async {
      await synced(DateTime(2026, 2, 1), uuid: 'neu');
      expect(await repo.evictSyncedBeyond(10), 0);
    });
  });
}
