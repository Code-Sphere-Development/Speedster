import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speedster/app/app.dart';
import 'package:speedster/app/theme.dart';
import 'package:speedster/settings/settings_controller.dart';
import 'package:speedster/ui/consent_screen.dart';
import 'package:speedster/ui/map_tiles.dart';

Future<Widget> app() async {
  SharedPreferences.setMockInitialValues({'consentAccepted': false});
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const SpeedsterApp(),
  );
}

Brightness shownBrightness(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(ConsentScreen))).brightness;

void main() {
  testWidgets('uebernimmt den hellen Systemmodus', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(await app());
    await tester.pump();

    expect(shownBrightness(tester), Brightness.light);
  });

  testWidgets('uebernimmt den dunklen Systemmodus', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(await app());
    await tester.pump();

    expect(shownBrightness(tester), Brightness.dark);
  });

  test('beide Helligkeiten sind definiert', () {
    expect(SpeedsterTheme.light.colorScheme.brightness, Brightness.light);
    expect(SpeedsterTheme.dark.colorScheme.brightness, Brightness.dark);
    expect(SpeedsterTheme.brandRed, const Color(0xFFE21C23));
  });

  test('Flaechen bleiben neutral, ohne Farbstich', () {
    for (final brightness in Brightness.values) {
      final surface = SpeedsterTheme.scheme(brightness).surface;
      // Material 3 faerbt Flaechen sonst mit der Saatfarbe ein; hier muessen
      // die Kanaele nahezu gleich sein.
      final spread = [surface.r, surface.g, surface.b];
      expect(
        spread.reduce((a, b) => a > b ? a : b) -
            spread.reduce((a, b) => a < b ? a : b),
        lessThan(0.02),
        reason: 'Flaeche bei $brightness hat einen Farbstich: $surface',
      );
    }
  });

  test('der Akzent bleibt ein kraeftiges Rot', () {
    // Der abgeleitete Akzent waere im Dunkelmodus ein blasses Lachsrosa.
    final dark = SpeedsterTheme.scheme(Brightness.dark).primary;
    expect(dark.r, greaterThan(0.9));
    expect(dark.g, lessThan(0.4));

    final light = SpeedsterTheme.scheme(Brightness.light).primary;
    expect(light.r, greaterThan(0.7));
    expect(light.g, lessThan(0.2));
  });

  Future<void> pumpMap(WidgetTester tester, ThemeData theme) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const FlutterMap(
          options: MapOptions(),
          children: [OsmTileLayer(), OsmAttribution()],
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('Karte bleibt in beiden Helligkeiten unveraendert',
      (tester) async {
    // Der fruehere Abdunkelungsfilter wirkte fahl und ist entfallen.
    for (final theme in [SpeedsterTheme.light, SpeedsterTheme.dark]) {
      await pumpMap(tester, theme);
      expect(find.byType(ColorFiltered), findsNothing);
    }
  });

  testWidgets('Karte nennt ihre Quelle', (tester) async {
    // Die Nutzungsrichtlinie von OpenStreetMap verlangt die Angabe.
    await pumpMap(tester, SpeedsterTheme.light);
    expect(find.textContaining('OpenStreetMap'), findsOneWidget);
  });
}
