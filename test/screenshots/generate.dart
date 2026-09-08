import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speedster/app/app.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/app/theme.dart';
import 'package:speedster/cloud/ranking_repository.dart';
import 'package:speedster/domain/sample.dart';
import 'package:speedster/domain/trip.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';
import 'package:speedster/recording/trip_recorder.dart';
import 'package:speedster/settings/settings_controller.dart';
import 'package:speedster/ui/live_screen.dart';
import 'package:speedster/ui/ranking_screen.dart';
import 'package:speedster/ui/trip_list_screen.dart';

/// Erzeugt die Screenshots fuer die Landingpage der Cloud.
///
/// Kein gewoehnlicher Test: er schreibt Dateien und laeuft deshalb nur auf
/// Zuruf --
///
///     flutter test test/screenshots/generate.dart
///
/// Der Dateiname endet nicht auf _test.dart -- `flutter test` sammelt ihn
/// deshalb nicht von selbst ein, nimmt ihn aber, wenn man ihn ausdruecklich
/// nennt. Ausserhalb von test/ waere er ebenfalls uebersprungen worden,
/// aber dort haelt der Analyzer ihn nicht mehr fuer Testcode und
/// beanstandet jede nur fuer Tests gedachte Schnittstelle. Ein Tag mit
/// `skip` waere ebenfalls falsch: der greift auch dann, wenn man den Tag
/// ausdruecklich anfordert.
///
/// Die Bilder altern mit jeder Aenderung an den gezeigten Bildschirmen.
/// Das ist der Preis dafuer, dass sie echt sind und nicht nachgestellt:
/// wer die Oberflaeche aendert, laesst sie neu erzeugen.
const outputDirectory = 'build/screenshots';

/// Ein Handy-Format, nicht das Standard-Testfenster (800x600): die Cloud
/// zeigt die Bilder als Handy, und ein Querformat sae dort falsch aus.
///
/// 430 statt 390 Punkt: bei 390 bricht die Beschriftung "Einstellungen" in
/// der Reiterleiste um, sobald "Live" den fuenften Platz belegt. Auf dem
/// Geraet ist das hinnehmbar, auf einem Werbebild nicht.
const phone = Size(430, 932);
const scale = 2.0;

/// Die Bilder entstehen in jeder Sprache, die die Oberflaeche spricht.
/// Sonst steht auf der englischen Seite ein deutsches Handy.
const locales = ['de', 'en'];

/// Wo das Flutter-SDK seine Schriften liegen hat.
///
/// Ohne sie zeichnet der Test jeden Buchstaben als schwarzen Kasten --
/// flutter_test laedt von sich aus keine echte Schrift.
String flutterRoot() {
  final fromEnv = Platform.environment['FLUTTER_ROOT'];
  if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
  // .../flutter/bin/cache/dart-sdk/bin/dart -- vier Ebenen hoch.
  var dir = Directory(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 4; i++) {
    dir = dir.parent;
  }

  return dir.path;
}

Future<void> loadFonts() async {
  final fonts = '${flutterRoot()}/bin/cache/artifacts/material_fonts';
  const families = {
    'Roboto': ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf'],
    'MaterialIcons': ['MaterialIcons-Regular.otf'],
  };

  for (final family in families.entries) {
    final loader = FontLoader(family.key);
    for (final file in family.value) {
      loader.addFont(
        File('$fonts/$file').readAsBytes().then((b) => b.buffer.asByteData()),
      );
    }
    await loader.load();
  }
}

Future<void> shoot(WidgetTester tester, String name) async {
  final boundary = tester.firstRenderObject<RenderRepaintBoundary>(
    find.byType(RepaintBoundary),
  );

  // runAsync: das Kodieren braucht echte Asynchronitaet. Ohne das steht
  // die Testuhr und toImage() kehrt nie zurueck.
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: scale);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$outputDirectory/$name.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

/// Rahmen um jeden Bildschirm: Titelleiste und Reiter wie in der App.
///
/// Die eigentliche Huelle (HomeShell) laesst sich hier nicht verwenden --
/// sie braucht Datenbank, Aufzeichnung und Cloud. Nachgebaut ist deshalb
/// nur das Geruest; Beschriftungen und Symbole der Reiter kommen aus
/// AppTab und damit aus derselben Quelle wie in der App. Aendert sich dort
/// ein Name, aendert er sich auch auf den Bildern.
///
/// Die Liste der Overrides wird bewusst nicht durchgereicht -- ihr Typ
/// `Override` ist von flutter_riverpod nicht exportiert. Deshalb setzt
/// jeder Aufruf seinen ProviderScope selbst und gibt hier nur das fertige
/// Stueck herein.
Widget frame(Widget screen, {required AppTab tab, required String locale}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: SpeedsterTheme.light,
      darkTheme: SpeedsterTheme.dark,
      themeMode: ThemeMode.dark,
      home: Builder(
        builder: (context) {
          final l = AppLocalizations.of(context);
          // "Live" erscheint in der App nur waehrend einer Fahrt -- auf
          // den Bildern also genauso.
          final tabs = [
            for (final t in AppTab.values)
              if (t != AppTab.live || tab == AppTab.live) t,
          ];

          return Scaffold(
            appBar: AppBar(title: Text(tab.title(l))),
            body: screen,
            bottomNavigationBar: NavigationBar(
              selectedIndex: tabs.indexOf(tab),
              onDestinationSelected: (_) {},
              destinations: [
                for (final t in tabs)
                  NavigationDestination(icon: Icon(t.icon), label: t.title(l)),
              ],
            ),
          );
        },
      ),
    );

Future<void> pumpScreen(WidgetTester tester, Widget app) async {
  tester.view.physicalSize = phone * scale;
  tester.view.devicePixelRatio = scale;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(app);
  // Zweimal: die Bildschirme lesen aus FutureProvidern, deren erster
  // Rahmen noch den Ladezustand zeigt.
  await tester.pump();
  await tester.pump();
}

Trip demoTrip({
  required int id,
  required int day,
  required double maxSpeed,
  required double distance,
  required int seconds,
}) =>
    Trip(
      id: id,
      startTime: DateTime(2026, 8, day, 17, 42),
      endTime: DateTime(2026, 8, day, 18, 12),
      maxSpeed: maxSpeed,
      avgSpeed: distance / seconds,
      distance: distance,
      elevationGain: 120,
      durationSeconds: seconds,
      zeroToHundredSeconds: 7.4,
      kept: true,
    );

void main() {
  setUpAll(loadFonts);

  for (final locale in locales) {
    testWidgets('live ($locale)', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await pumpScreen(
        tester,
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            recorderStateProvider.overrideWith(
              (ref) => Stream.value(
                RecorderState(
                  isDriving: true,
                  activeTripId: 1,
                  distanceMeters: 24800,
                  elapsedSeconds: 1315,
                  last: Sample(
                    lat: 51.09,
                    lng: 6.89,
                    speed: 35.6,
                    altitude: 42,
                    accuracy: 3,
                    timestamp: DateTime(2026, 8, 17, 18, 4),
                  ),
                ),
              ),
            ),
          ],
          child: frame(const LiveScreen(), tab: AppTab.live, locale: locale),
        ),
      );

      await shoot(tester, 'live-$locale');
    });

    testWidgets('bestenliste ($locale)', (tester) async {
      SharedPreferences.setMockInitialValues({'cloudEnabled': true});
      final prefs = await SharedPreferences.getInstance();

      // Bewusst keine Extremwerte: die Seite mahnt an derselben Stelle,
      // keine Begrenzung zu ueberschreiten. Eine Bestenliste mit 220 km/h
      // daneben arbeitete gegen die eigene Aussage.
      const board = RankingBoard(
        entries: [
          RankingEntry(
              rank: 1, displayName: 'nordschleife', country: 'DE', value: 50.0),
          RankingEntry(rank: 2, displayName: 'mira_k', country: 'AT', value: 47.8),
          RankingEntry(rank: 3, displayName: 'coho04', country: 'DE', value: 45.8),
          RankingEntry(rank: 4, displayName: 'lenny', country: 'CH', value: 43.9),
          RankingEntry(rank: 5, displayName: 'tessa', country: 'NL', value: 41.4),
          RankingEntry(rank: 6, displayName: 'jonas_w', country: 'DE', value: 39.2),
        ],
        me: RankingEntry(rank: 3, displayName: 'coho04', country: 'DE', value: 45.8),
      );

      await pumpScreen(
        tester,
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            cloudActiveProvider.overrideWith((ref) async => true),
            rankingBoardProvider.overrideWith((ref, arg) async => board),
          ],
          child: frame(const RankingScreen(), tab: AppTab.ranking, locale: locale),
        ),
      );

      await shoot(tester, 'bestenliste-$locale');
    });

    testWidgets('fahrten ($locale)', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await pumpScreen(
        tester,
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            keptTripsProvider.overrideWith(
              (ref) => [
                demoTrip(
                    id: 1, day: 17, maxSpeed: 44.4, distance: 42300, seconds: 2410),
                demoTrip(
                    id: 2, day: 15, maxSpeed: 25.0, distance: 12800, seconds: 1180),
                demoTrip(
                    id: 3, day: 12, maxSpeed: 38.9, distance: 86200, seconds: 4020),
                demoTrip(
                    id: 4, day: 9, maxSpeed: 16.7, distance: 5600, seconds: 720),
                demoTrip(
                    id: 5, day: 6, maxSpeed: 33.3, distance: 27400, seconds: 1640),
                demoTrip(
                    id: 6, day: 4, maxSpeed: 22.2, distance: 9100, seconds: 880),
                demoTrip(
                    id: 7, day: 2, maxSpeed: 41.7, distance: 61500, seconds: 3200),
              ],
            ),
          ],
          child: frame(const TripListScreen(), tab: AppTab.trips, locale: locale),
        ),
      );

      await shoot(tester, 'fahrten-$locale');
    });
  }
}
