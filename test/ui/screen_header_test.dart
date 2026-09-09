import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/ui/screen_header.dart';

void main() {
  testWidgets('steht links, egal worin er steckt', (tester) async {
    // In einer Column landete er sonst mittig, in einer ListView links --
    // und die Bildschirme saehen unterschiedlich aus.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [ScreenHeader(title: 'Fahrten', subtitle: '7 Fahrten')],
          ),
        ),
      ),
    );

    final inColumn = tester.getTopLeft(find.text('Fahrten')).dx;

    // ListView ist nicht const-faehig -- es baut seine Kinder erst.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: const [
              ScreenHeader(title: 'Fahrten', subtitle: '7 Fahrten'),
            ],
          ),
        ),
      ),
    );

    expect(tester.getTopLeft(find.text('Fahrten')).dx, inColumn);
  });

  testWidgets('kommt ohne Untertitel aus', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ScreenHeader(title: 'Einstellungen')),
      ),
    );

    expect(find.text('Einstellungen'), findsOneWidget);
  });
}
