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

  test('beide Themes stammen aus derselben Saatfarbe', () {
    expect(SpeedsterTheme.light.colorScheme.brightness, Brightness.light);
    expect(SpeedsterTheme.dark.colorScheme.brightness, Brightness.dark);
    // Rot aus dem Logo, nicht mehr das Flutter-Standard-Indigo.
    expect(SpeedsterTheme.seed, const Color(0xFFE21C23));
  });

  Future<void> pumpMap(WidgetTester tester, ThemeData theme) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const FlutterMap(
          options: MapOptions(),
          children: [OsmTileLayer()],
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('helle Karte bleibt im Hellmodus ungefiltert', (tester) async {
    await pumpMap(tester, SpeedsterTheme.light);
    expect(find.byKey(OsmTileLayer.darkFilterKey), findsNothing);
  });

  testWidgets('OSM-Kacheln werden im Dunkelmodus abgedunkelt', (tester) async {
    // OSM liefert nur helle Kacheln; ungefiltert waere der Start-Screen im
    // Dunkelmodus eine grosse leuchtende Flaeche.
    await pumpMap(tester, SpeedsterTheme.dark);
    expect(find.byKey(OsmTileLayer.darkFilterKey), findsOneWidget);
  });
}
