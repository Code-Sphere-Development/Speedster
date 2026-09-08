import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/data/database.dart' show AppDatabase;
import 'package:speedster/heat/heat_map.dart';
import 'package:speedster/heat/heat_snapshot_store.dart';

HeatMap sample() => const HeatMap(
      edges: [
        HeatEdgeView(aLat: 50.1, aLng: 7.1, bLat: 50.2, bLng: 7.2, count: 3),
        HeatEdgeView(aLat: 50.2, aLng: 7.2, bLat: 50.3, bLng: 7.3, count: 11),
      ],
      maxCount: 11,
    );

void main() {
  late AppDatabase db;
  late HeatSnapshotStore store;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    store = HeatSnapshotStore(db);
  });
  tearDown(() => db.close());

  test('gibt eine gespeicherte Karte unveraendert zurueck', () async {
    const query = HeatQuery(level: 1);
    await store.write(query, sample());

    final read = await store.read(query);

    expect(read, isNotNull);
    expect(read!.maxCount, 11);
    expect(read.edges, hasLength(2));
    expect(read.edges.first.aLat, 50.1);
    expect(read.edges.last.count, 11);
  });

  test('speichert keine auf einen Kartenausschnitt beschnittene Antwort',
      () async {
    const bounded = HeatQuery(
      level: 1,
      bounds: HeatBounds(49, 6, 51, 8),
    );
    await store.write(bounded, sample());

    expect(await store.read(bounded), isNull);
  });

  test('bedient eine Ausschnitts-Abfrage aus dem ungefilterten Vorrat',
      () async {
    await store.write(const HeatQuery(level: 1), sample());

    final read = await store.read(
      const HeatQuery(level: 1, bounds: HeatBounds(49, 6, 51, 8)),
    );

    expect(read?.edges, hasLength(2));
  });

  test('trennt Ebenen und Zeitraeume', () async {
    await store.write(const HeatQuery(level: 0), sample());

    expect(await store.read(const HeatQuery(level: 1)), isNull);
    expect(
      await store.read(const HeatQuery(level: 0, range: HeatRange.months3)),
      isNull,
    );
  });

  test('ueberschreibt denselben Schluessel statt zu haeufen', () async {
    const query = HeatQuery(level: 2, range: HeatRange.months12);
    await store.write(query, sample());
    await store.write(query, const HeatMap(edges: [], maxCount: 0));

    final read = await store.read(query);
    expect(read?.edges, isEmpty);
    expect(read?.maxCount, 0);
  });
}
