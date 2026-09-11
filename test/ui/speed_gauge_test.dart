import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/app/theme.dart';
import 'package:speedster/settings/unit_system.dart';
import 'package:speedster/ui/components/speed_gauge.dart';

Future<void> pump(WidgetTester tester, double mps, UnitSystem unit) =>
    tester.pumpWidget(
      MaterialApp(
        theme: SpeedsterTheme.dark,
        home: Scaffold(
          body: Center(child: SpeedGauge(speedMps: mps, unit: unit)),
        ),
      ),
    );

void main() {
  test('die Skala waechst mit, statt bei Vollausschlag stehenzubleiben', () {
    // Ein Bogen, der oben anschlaegt, verschweigt genau den Fall, der
    // interessiert.
    expect(SpeedGauge.scaleFor(50, UnitSystem.kmh), 60);
    expect(SpeedGauge.scaleFor(90, UnitSystem.kmh), 120);
    expect(SpeedGauge.scaleFor(160, UnitSystem.kmh), 200);
    expect(SpeedGauge.scaleFor(999, UnitSystem.kmh), 320);
  });

  test('in Meilen ist die Skala eine andere', () {
    expect(SpeedGauge.scaleFor(50, UnitSystem.mph), 80);
    expect(SpeedGauge.scaleFor(30, UnitSystem.mph), 40);
  });

  testWidgets('zeigt Zahl und Einheit getrennt', (tester) async {
    await pump(tester, 25, UnitSystem.kmh); // 25 m/s = 90 km/h

    expect(find.text('90'), findsOneWidget);
    expect(find.text('km/h'), findsOneWidget);
  });

  testWidgets('steht im Stand auf null, statt zu verschwinden',
      (tester) async {
    await pump(tester, 0, UnitSystem.kmh);

    expect(find.text('0'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('haelt auch jenseits der groessten Stufe durch', (tester) async {
    await pump(tester, 200, UnitSystem.kmh); // 720 km/h

    expect(tester.takeException(), isNull);
  });
}
