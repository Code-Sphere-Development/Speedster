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

  group('Farbbaender', () {
    final ramp = SpeedGauge.rampFor(SpeedsterTheme.dark.colorScheme,
        UnitSystem.kmh);

    test('jedes Band hat seine eigene Farbe', () {
      // Der Punkt der Uebung: der Bogen war vorher auf ganzer Laenge rot,
      // ein Tempo war vom naechsten nicht zu unterscheiden.
      final baender = [
        ramp.colorAt(15),
        ramp.colorAt(40),
        ramp.colorAt(90),
        ramp.colorAt(200),
      ];

      expect(baender.toSet(), hasLength(4));
    });

    test('innerhalb eines Bandes bleibt die Farbe gleich', () {
      // Harte Kanten statt Verlauf: zwischen den Schwellen aendert sich
      // nichts, sonst liest man wieder nur einen Farbton.
      expect(ramp.colorAt(5), ramp.colorAt(29));
      expect(ramp.colorAt(31), ramp.colorAt(49));
      expect(ramp.colorAt(51), ramp.colorAt(119));
      expect(ramp.colorAt(131), ramp.colorAt(300));
    });

    test('ueber 130 ist rot, darunter nicht', () {
      expect(ramp.colorAt(140), SpeedsterTheme.dark.colorScheme.primary);
      expect(ramp.colorAt(100),
          isNot(SpeedsterTheme.dark.colorScheme.primary));
    });

    test('unterhalb und oberhalb der Skala bleibt es bei den Randfarben', () {
      expect(ramp.colorAt(-10), ramp.colorAt(0));
      expect(ramp.colorAt(9999), ramp.colorAt(320));
    });

    test('in Meilen liegen die Schwellen umgerechnet', () {
      final mph =
          SpeedGauge.rampFor(SpeedsterTheme.dark.colorScheme, UnitSystem.mph);

      // 80 mph entsprechen rund 130 km/h -- dieselbe Farbe, andere Zahl.
      expect(mph.colorAt(90), ramp.colorAt(140));
      expect(mph.colorAt(15), ramp.colorAt(20));
    });

    test('der Verlauf wird ueber das Tempo abgetastet, nicht geklemmt', () {
      // Bei kleiner Skala lagen frueher alle Schwellen zusammengedraengt
      // am Ende: 120 sah dann so heiss aus wie 200.
      final kleine = ramp.colorsFor(120);
      final grosse = ramp.colorsFor(320);

      expect(kleine.last, ramp.colorAt(120));
      expect(grosse.last, ramp.colorAt(320));
      expect(kleine.last, isNot(grosse.last));
    });
  });
}
