import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/sensors/last_known_location.dart';
import 'package:speedster/heat/heat_map.dart';
import 'package:speedster/heat/heat_source.dart';
import 'package:speedster/ui/heat_glow_layer.dart';
import 'package:speedster/ui/heatmap_screen.dart';
import 'package:speedster/ui/map_tiles.dart';

class FakeHeatSource implements HeatSource {
  FakeHeatSource(this.map);

  final HeatMap map;
  final queries = <HeatQuery>[];

  @override
  Future<HeatMap> load(HeatQuery query) async {
    queries.add(query);
    return map;
  }
}

Widget wrap(
  HeatSource source, {
  bool cloud = false,
  ({double lat, double lng})? lastKnown,
}) =>
    ProviderScope(
      overrides: [
        heatSourceProvider.overrideWithValue(source),
        cloudActiveProvider.overrideWith((ref) async => cloud),
        lastKnownLocationProvider
            .overrideWithValue(FakeLastKnownLocation(lastKnown)),
      ],
      child: const MaterialApp(home: HeatmapScreen()),
    );

const _oneEdge = HeatMap(
  edges: [
    HeatEdgeView(aLat: 50.0, aLng: 6.0, bLat: 50.001, bLng: 6.001, count: 3),
  ],
  maxCount: 3,
);

void main() {
  testWidgets('zeigt die Karte auch ohne aufgezeichnete Strecken',
      (tester) async {
    await tester.pumpWidget(wrap(FakeHeatSource(HeatMap.empty)));
    await tester.pumpAndSettle();

    // Der leere Zustand ist ein Hinweis ueber der Karte, kein Ersatz dafuer.
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.text('Noch keine Strecken aufgezeichnet'), findsOneWidget);
    // Auch ohne Strecken bleiben die dunklen Kacheln und die Quellenangabe
    // stehen -- der Hinweis ueberlagert die Karte, ersetzt sie nicht.
    expect(find.byType(EsriDarkTileLayer), findsOneWidget);
    expect(find.byType(EsriDarkLabelsTileLayer), findsOneWidget);
    expect(find.byType(EsriDarkAttribution), findsOneWidget);
  });

  testWidgets('nutzt dunkle Esri-Kacheln statt heller OSM-Kacheln',
      (tester) async {
    await tester.pumpWidget(wrap(FakeHeatSource(_oneEdge)));
    await tester.pumpAndSettle();

    // Auf hellen OSM-Kacheln liest sich die dunkle Rampe wie Schmutz --
    // deshalb nur die dunkle Basiskarte auf der Heatmap, nie OSM.
    expect(find.byType(EsriDarkTileLayer), findsOneWidget);
    expect(find.byType(EsriDarkLabelsTileLayer), findsOneWidget);
    expect(find.byType(OsmTileLayer), findsNothing);

    final tileLayers =
        tester.widgetList<TileLayer>(find.byType(TileLayer)).toList();
    expect(tileLayers, hasLength(2));
    for (final layer in tileLayers) {
      // Esri erwartet {z}/{y}/{x} -- anders als OSMs {z}/{x}/{y}.
      expect(layer.urlTemplate, contains('{z}/{y}/{x}'));
      expect(layer.urlTemplate, contains('arcgisonline.com'));
    }
  });

  testWidgets('zeigt die vorgeschriebene Esri-Quellenangabe', (tester) async {
    await tester.pumpWidget(wrap(FakeHeatSource(_oneEdge)));
    await tester.pumpAndSettle();

    expect(
      find.text('© Esri, HERE, Garmin, © OpenStreetMap-Mitwirkende'),
      findsOneWidget,
    );
    expect(find.byType(OsmAttribution), findsNothing);
  });

  testWidgets('zeichnet die Strecken ueber die glow-Ebene, nicht PolylineLayer',
      (tester) async {
    await tester.pumpWidget(wrap(FakeHeatSource(_oneEdge)));
    await tester.pumpAndSettle();

    expect(find.byType(HeatGlowLayer), findsOneWidget);
    expect(find.byType(PolylineLayer), findsNothing);
  });

  testWidgets('blendet den Hinweis aus, sobald Strecken vorliegen',
      (tester) async {
    await tester.pumpWidget(wrap(FakeHeatSource(_oneEdge)));
    await tester.pumpAndSettle();

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.text('Noch keine Strecken aufgezeichnet'), findsNothing);
  });

  testWidgets('zeigt Karte und Legende, wenn Kanten vorliegen', (tester) async {
    await tester.pumpWidget(wrap(FakeHeatSource(_oneEdge)));
    await tester.pumpAndSettle();

    expect(find.text('Noch keine Strecken aufgezeichnet'), findsNothing);
    expect(find.text('selten'), findsOneWidget);
    expect(find.text('oft'), findsOneWidget);
  });

  testWidgets('ohne Cloud gibt es keine Filter', (tester) async {
    await tester.pumpWidget(wrap(FakeHeatSource(_oneEdge)));
    await tester.pumpAndSettle();
    expect(find.text('Alles'), findsNothing);
    expect(find.text('12 Monate'), findsNothing);
  });

  testWidgets('mit Cloud erscheinen die Filter und wirken', (tester) async {
    final source = FakeHeatSource(_oneEdge);
    await tester.pumpWidget(wrap(source, cloud: true));
    await tester.pumpAndSettle();

    expect(find.text('Alles'), findsOneWidget);
    expect(find.text('3 Monate'), findsOneWidget);

    await tester.tap(find.text('3 Monate'));
    await tester.pumpAndSettle();

    expect(source.queries.last.range, HeatRange.months3);
  });

  testWidgets('zentriert ohne Strecken auf die letzte bekannte Position',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        FakeHeatSource(HeatMap.empty),
        lastKnown: (lat: 50.9375, lng: 6.9603),
      ),
    );
    await tester.pumpAndSettle();

    // Kamera aus dem Kartenkontext lesen, nicht nur die Startoptionen:
    // verschoben wird erst nach dem ersten Frame.
    final camera =
        MapCamera.of(tester.element(find.byType(EsriDarkTileLayer)));
    expect(camera.center.latitude, closeTo(50.9375, 0.0001));
    expect(camera.center.longitude, closeTo(6.9603, 0.0001));
    expect(find.text('Noch keine Strecken aufgezeichnet'), findsOneWidget);
  });

  testWidgets('ohne bekannte Position bleibt die Uebersicht stehen',
      (tester) async {
    await tester.pumpWidget(wrap(FakeHeatSource(HeatMap.empty)));
    await tester.pumpAndSettle();

    final options = tester.widget<FlutterMap>(find.byType(FlutterMap)).options;
    expect(options.initialCenter, const LatLng(51.1657, 10.4515));
    expect(options.initialZoom, 5.0);
  });

  testWidgets(
      'faellt bei fehlenden Kacheln nicht auf den hellen Standardgrund '
      'zurueck', (tester) async {
    await tester.pumpWidget(wrap(FakeHeatSource(_oneEdge)));
    await tester.pumpAndSettle();

    // MapOptions.backgroundColor faellt sonst auf 0xFFE0E0E0 zurueck --
    // solange die Esri-Kacheln laden oder unerreichbar sind, waere die
    // Karte wieder dunkle Rampe auf hellem Grund. Der exakte Wert ist
    // bewusst geprueft, damit ihn niemand versehentlich fallen laesst.
    final options = tester.widget<FlutterMap>(find.byType(FlutterMap)).options;
    expect(options.backgroundColor, esriDarkBackground);
    expect(options.backgroundColor, isNot(const Color(0xFFE0E0E0)));
  });

  testWidgets('rueckt die Karte auf die vorhandenen Strecken', (tester) async {
    await tester.pumpWidget(wrap(FakeHeatSource(_oneEdge)));
    await tester.pumpAndSettle();

    // Vorher zeigte die Karte fest auf den ersten Kantenpunkt; jetzt wird der
    // gesamte Streckenbereich eingepasst.
    final camera =
        MapCamera.of(tester.element(find.byType(EsriDarkTileLayer)));
    expect(camera.center.latitude, closeTo(50.0005, 0.001));
    expect(camera.center.longitude, closeTo(6.0005, 0.001));
    expect(camera.zoom, greaterThan(5.0));
  });
}
