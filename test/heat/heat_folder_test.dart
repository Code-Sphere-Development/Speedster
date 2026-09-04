import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/data/database.dart';
import 'package:speedster/heat/heat_folder.dart';

void main() {
  late AppDatabase db;
  late HeatFolder folder;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // Synchroner Runner: kein echtes Isolate im Test.
    folder = HeatFolder(db, runner: (fn, msg) async => fn(msg));
  });
  tearDown(() => db.close());

  Future<int> seedTrip({double startLat = 50.0, bool kept = true}) async {
    final id = await db.into(db.trips).insert(
          TripsCompanion.insert(
            startTime: DateTime.utc(2026, 1, 1),
            kept: Value(kept),
          ),
        );
    await db.batch((b) {
      b.insertAll(db.trackPoints, [
        for (var i = 0; i < 20; i++)
          TrackPointsCompanion.insert(
            tripId: id,
            lat: startLat + (i * 12) / 111320.0,
            lng: 6.0,
            speed: 20,
            altitude: 100,
            accuracy: 5,
            timestamp: DateTime.utc(2026, 1, 1).add(Duration(seconds: i)),
          ),
      ]);
    });
    return id;
  }

  Future<int> edgeCount() async => (await db.select(db.heatEdges).get()).length;

  Future<int> maxCount() async {
    final rows =
        await (db.select(db.heatEdges)..where((e) => e.level.equals(0))).get();
    return rows.map((r) => r.count).fold<int>(0, (a, b) => a > b ? a : b);
  }

  test('faltet offene Fahrten und markiert sie', () async {
    final id = await seedTrip();
    expect(await folder.foldPending(), 1);
    expect(await edgeCount(), greaterThan(0));

    final trip =
        await (db.select(db.trips)..where((t) => t.id.equals(id))).getSingle();
    expect(trip.heatFoldedAt, isNotNull);
  });

  test('faltet dieselbe Fahrt nicht zweimal', () async {
    await seedTrip();
    await folder.foldPending();
    final after = await edgeCount();
    expect(await folder.foldPending(), 0);
    expect(await edgeCount(), after);
    expect(await maxCount(), 1);
  });

  test('zwei Fahrten ueber dieselbe Strecke ergeben count 2', () async {
    await seedTrip();
    await seedTrip();
    await folder.foldPending();
    expect(await maxCount(), 2);
  });

  test('verworfene Fahrten werden nicht gefaltet', () async {
    await seedTrip(kept: false);
    expect(await folder.foldPending(), 0);
    expect(await edgeCount(), 0);
  });

  test('rebuild baut die Aggregate aus allen behaltenen Fahrten neu', () async {
    await seedTrip();
    await seedTrip();
    await folder.foldPending();
    final before = await maxCount();

    await folder.rebuild();
    expect(await maxCount(), before);
  });

  test('nach einer Ruecknahme faltet foldPending nur noch den Rest', () async {
    await seedTrip();
    final drop = await seedTrip();
    await folder.foldPending();
    expect(await maxCount(), 2);

    // So invalidiert das Repository (siehe DriftTripRepository.setKept).
    await (db.update(db.trips)..where((t) => t.id.equals(drop)))
        .write(const TripsCompanion(kept: Value(false)));
    await db.delete(db.heatEdges).go();
    await db.delete(db.heatCells).go();
    await db.update(db.trips).write(
          const TripsCompanion(heatFoldedAt: Value(null)),
        );

    expect(await folder.foldPending(), 1);
    expect(await maxCount(), 1);
    expect(await edgeCount(), greaterThan(0));
  });

  test('Zellschwerpunkte werden mitgeschrieben', () async {
    await seedTrip();
    await folder.foldPending();
    final cell = (await (db.select(db.heatCells)
              ..where((c) => c.level.equals(0)))
            .get())
        .first;
    expect(cell.n, greaterThan(0));
    expect(cell.latSum / cell.n, closeTo(50.0, 0.01));
  });
}
