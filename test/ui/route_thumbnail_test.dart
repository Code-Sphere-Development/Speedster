import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/app/theme.dart';
import 'package:speedster/ui/components/route_thumbnail.dart';

Future<void> pump(WidgetTester tester, String? encoded) => tester.pumpWidget(
      MaterialApp(
        theme: SpeedsterTheme.light,
        home: Scaffold(body: Center(child: RouteThumbnail(encoded: encoded))),
      ),
    );

void main() {
  testWidgets('zeichnet die Strecke, wenn eine vorliegt', (tester) async {
    await pump(tester, '52.50000,13.40000;52.51000,13.41000;52.52000,13.39000');

    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.byIcon(Icons.route_outlined), findsNothing);
  });

  testWidgets('zeigt ohne Strecke einen Platzhalter', (tester) async {
    // Fahrten von einem anderen Geraet haben keine gespeicherte Strecke.
    // Eine leere Flaeche saehe dort aus wie ein Ladefehler.
    await pump(tester, null);

    expect(find.byIcon(Icons.route_outlined), findsOneWidget);
  });

  testWidgets('ein einzelner Punkt ergibt keine Linie', (tester) async {
    await pump(tester, '52.50000,13.40000');

    expect(find.byIcon(Icons.route_outlined), findsOneWidget);
  });

  testWidgets('beschaedigte Werte stuerzen nicht ab', (tester) async {
    await pump(tester, 'kaputt');

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.route_outlined), findsOneWidget);
  });

  testWidgets('eine Fahrt geradeaus teilt nicht durch null', (tester) async {
    // Nord-Sued gefahren ist die Breite der Umschliessenden exakt null.
    await pump(tester, '52.50000,13.40000;52.51000,13.40000');

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.route_outlined), findsNothing);
  });
}
