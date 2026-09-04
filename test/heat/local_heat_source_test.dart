import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/data/database.dart';
import 'package:speedster/heat/heat_folder.dart';
import 'package:speedster/heat/heat_map.dart';
import 'package:speedster/heat/local_heat_source.dart';

void main() {
  late AppDatabase db;
  late LocalHeatSource source;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    source = LocalHeatSource(
      db,
      HeatFolder(db, runner: (fn, msg) async => fn(msg)),
    );
  });
  tearDown(() => db.close());

  Future<void> seedTrip({double startLat = 50.0}) async {
    final id = await db.into(db.trips).insert(
          TripsCompanion.insert(startTime: DateTime.utc(2026, 1, 1)),
        );
    await db.batch((b) {
      b.insertAll(db.trackPoints, [
        for (var i = 0; i < 200; i++)
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
  }

  test('leere Datenbank liefert eine leere Heatmap', () async {
    final map = await source.load(const HeatQuery(level: 0));
    expect(map.edges, isEmpty);
    expect(map.maxCount, 0);
  });

  test('faltet beim Laden nach und liefert Kanten mit Koordinaten', () async {
    await seedTrip();
    final map = await source.load(const HeatQuery(level: 0));

    expect(map.edges, isNotEmpty);
    expect(map.maxCount, 1);
    final edge = map.edges.first;
    expect(edge.aLat, closeTo(50.0, 0.05));
    expect(edge.aLng, closeTo(6.0, 0.01));
    expect(edge.count, 1);
  });

  test('zwei gleiche Fahrten heben maxCount auf 2', () async {
    await seedTrip();
    await seedTrip();
    final map = await source.load(const HeatQuery(level: 0));
    expect(map.maxCount, 2);
  });

  test('Viewport-Filter grenzt ein, maxCount bleibt global', () async {
    await seedTrip();
    await seedTrip(startLat: 51.0);

    final all = await source.load(const HeatQuery(level: 0));
    final windowed = await source.load(
      const HeatQuery(level: 0, bounds: HeatBounds(49.9, 5.9, 50.1, 6.1)),
    );

    expect(windowed.edges.length, lessThan(all.edges.length));
    expect(windowed.edges, isNotEmpty);
    expect(windowed.maxCount, all.maxCount);
  });

  test('Zeitfilter wird lokal ignoriert', () async {
    await seedTrip();
    final all = await source.load(const HeatQuery(level: 0));
    final filtered =
        await source.load(const HeatQuery(level: 0, range: HeatRange.months3));
    expect(filtered.edges.length, all.edges.length);
  });

  test('groebere Level liefern weniger Kanten', () async {
    await seedTrip();
    final fine = await source.load(const HeatQuery(level: 0));
    final coarse = await source.load(const HeatQuery(level: 2));
    expect(coarse.edges.length, lessThan(fine.edges.length));
  });

  test('Zoom wird auf das richtige Level abgebildet', () {
    expect(HeatGridZoom.levelForZoom(16), 0);
    expect(HeatGridZoom.levelForZoom(14), 0);
    expect(HeatGridZoom.levelForZoom(12), 1);
    expect(HeatGridZoom.levelForZoom(10), 2);
    expect(HeatGridZoom.levelForZoom(3), 2);
  });
}
