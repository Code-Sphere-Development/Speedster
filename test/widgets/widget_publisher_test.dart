import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/data/database.dart' show AppDatabase;
import 'package:speedster/data/trip_repository.dart';
import 'package:speedster/domain/trip.dart';
import 'package:speedster/heat/heat_map.dart';
import 'package:speedster/heat/heat_source.dart';
import 'package:speedster/widgets/heat_thumbnail.dart';
import 'package:speedster/widgets/widget_publisher.dart';
import 'package:speedster/widgets/widget_store.dart';

class _StubHeat implements HeatSource {
  _StubHeat(this.map);

  final HeatMap map;

  @override
  Future<HeatMap> load(HeatQuery query) async => map;
}

class _FailingHeat implements HeatSource {
  @override
  Future<HeatMap> load(HeatQuery query) async => throw Exception('kein Netz');
}

Trip trip({
  required DateTime start,
  double distance = 10000,
  double maxSpeed = 30,
  double? zeroToHundred,
}) =>
    Trip(
      startTime: start,
      endTime: start.add(const Duration(minutes: 20)),
      maxSpeed: maxSpeed,
      avgSpeed: 15,
      distance: distance,
      elevationGain: 20,
      durationSeconds: 1200,
      zeroToHundredSeconds: zeroToHundred,
      kept: true,
    );

HeatMap sampleMap() => const HeatMap(
      edges: [
        HeatEdgeView(aLat: 50.0, aLng: 7.0, bLat: 50.01, bLng: 7.01, count: 5),
        HeatEdgeView(aLat: 50.01, aLng: 7.01, bLat: 50.02, bLng: 7.0, count: 2),
      ],
      maxCount: 5,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DriftTripRepository repo;
  late RecordingWidgetStore store;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftTripRepository(db);
    store = RecordingWidgetStore();
  });
  tearDown(() => db.close());

  WidgetPublisher publisher({HeatSource? heat}) => WidgetPublisher(
        store: store,
        trips: repo,
        heat: heat ?? _StubHeat(sampleMap()),
      );

  test('schreibt Gesamtzahlen und die letzte Fahrt', () async {
    await repo.createTrip(trip(
      start: DateTime(2026, 1, 1),
      distance: 5000,
      maxSpeed: 20,
      zeroToHundred: 9.0,
    ));
    await repo.createTrip(trip(
      start: DateTime(2026, 3, 1),
      distance: 15000,
      maxSpeed: 40,
      zeroToHundred: 7.5,
    ));

    await publisher().publish();

    expect(store.values[WidgetKeys.tripCount], 2);
    expect(store.values[WidgetKeys.totalDistance], 20000);
    expect(store.values[WidgetKeys.maxSpeed], 40);
    expect(store.values[WidgetKeys.bestZeroToHundred], 7.5);
    // keptTrips liefert absteigend -- die letzte gefahrene steht vorn.
    expect(store.values[WidgetKeys.lastTripDistance], 15000);
    expect(store.values[WidgetKeys.lastTripAt],
        DateTime(2026, 3, 1).toIso8601String());
  });

  test('kommt ohne Fahrten ohne Kennzahlen aus', () async {
    await publisher().publish();

    // Kein Eintrag statt einer Null: das Widget zeigt dann seinen
    // Hinweis, nicht "0 Fahrten, 0,0 km".
    expect(store.values.containsKey(WidgetKeys.tripCount), isFalse);
    expect(store.values.containsKey(WidgetKeys.lastTripAt), isFalse);
  });

  test('laesst die beste 0-100 weg, wenn sie nie erreicht wurde', () async {
    await repo.createTrip(trip(start: DateTime(2026)));

    await publisher().publish();

    expect(store.values[WidgetKeys.bestZeroToHundred], isNull);
  });

  test('legt das Heatmap-Bild als Base64 ab', () async {
    await publisher().publish();

    final encoded = store.values[WidgetKeys.heatmapImage] as String?;
    expect(encoded, isNotNull);
    final bytes = base64Decode(encoded!);
    // PNG-Signatur: sonst waere es irgendetwas, und das Widget zeigte
    // nichts, ohne dass es auffiele.
    expect(bytes.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
  });

  test('kommt ohne Heatmap-Quelle zurecht', () async {
    await repo.createTrip(trip(start: DateTime(2026)));

    await publisher(heat: _FailingHeat()).publish();

    // Die Kennzahlen muessen trotzdem geschrieben werden -- ein fehlendes
    // Bild darf nicht die uebrigen Widgets leeren.
    expect(store.values[WidgetKeys.tripCount], 1);
    expect(store.values.containsKey(WidgetKeys.heatmapImage), isFalse);
  });

  test('zeichnet ohne Kanten kein Bild', () async {
    await publisher(heat: _StubHeat(HeatMap.empty)).publish();

    expect(store.values.containsKey(WidgetKeys.heatmapImage), isFalse);
  });

  group('HeatThumbnail', () {
    test('liefert ein quadratisches PNG', () async {
      final png = await HeatThumbnail.render(sampleMap(), size: 128);

      expect(png, isNotNull);
      expect(png!.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
    });

    test('liefert ohne Kanten nichts', () async {
      expect(await HeatThumbnail.render(HeatMap.empty), isNull);
    });
  });
}
