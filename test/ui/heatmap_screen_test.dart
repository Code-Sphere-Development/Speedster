import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/heat/heat_map.dart';
import 'package:speedster/heat/heat_source.dart';
import 'package:speedster/ui/heatmap_screen.dart';

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

Widget wrap(HeatSource source, {bool cloud = false}) => ProviderScope(
      overrides: [
        heatSourceProvider.overrideWithValue(source),
        cloudActiveProvider.overrideWith((ref) async => cloud),
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
  testWidgets('zeigt einen Hinweis, wenn nichts aufgezeichnet wurde',
      (tester) async {
    await tester.pumpWidget(wrap(FakeHeatSource(HeatMap.empty)));
    await tester.pumpAndSettle();
    expect(find.text('Noch keine Strecken aufgezeichnet'), findsOneWidget);
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
}
