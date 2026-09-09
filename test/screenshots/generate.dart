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
import 'package:speedster/cloud/vehicle_repository.dart';
import 'package:speedster/ui/garage_screen.dart';
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
/// Wohin, wie gross und wie fein -- die Bilder entstehen fuer zwei Zwecke
/// zugleich.
class Target {
  const Target(this.directory, this.size, this.scale);

  final String directory;
  final Size size;
  final double scale;
}

const targets = [
  /// Fuer die Landingpage der Cloud. Dort werden sie rund 256 Punkt breit
  /// gezeigt; die App-Store-Fassung waere dafuer unnoetiger Ballast.
  ///
  /// 430 statt 390 Punkt: bei 390 bricht die Beschriftung "Einstellungen"
  /// in der Reiterleiste um, sobald "Live" den fuenften Platz belegt. Auf
  /// dem Geraet ist das hinnehmbar, auf einem Werbebild nicht.
  Target('build/screenshots', Size(430, 932), 2),

  /// Fuer App Store Connect. Verlangt wird der 6,9-Zoll-Satz mit
  /// 1320 x 2868 Punkten -- das sind 440 x 956 Punkt bei dreifacher
  /// Aufloesung, also genau ein iPhone 16 Pro Max. Die App ist
  /// iPhone-only (TARGETED_DEVICE_FAMILY = 1), ein iPad-Satz entfaellt.
  ///
  /// Vor dem Hochladen muss der Alphakanal weg -- Flutter schreibt RGBA,
  /// und App Store Connect weist Bilder damit zurueck, auch wenn sie
  /// vollstaendig deckend sind:
  ///
  ///     magick bild.png -background black -alpha remove -alpha off bild.png
  Target('build/appstore', Size(440, 956), 3),
];

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

Future<void> shoot(WidgetTester tester, Target target, String name) async {
  final boundary = tester.firstRenderObject<RenderRepaintBoundary>(
    find.byType(RepaintBoundary),
  );

  // runAsync: das Kodieren braucht echte Asynchronitaet. Ohne das steht
  // die Testuhr und toImage() kehrt nie zurueck.
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: target.scale);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('${target.directory}/$name.png');
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

Future<void> pumpScreen(WidgetTester tester, Target target, Widget app) async {
  tester.view.physicalSize = target.size * target.scale;
  tester.view.devicePixelRatio = target.scale;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(app);
  // pumpAndSettle statt einzelner Durchlaeufe: die Bildschirme lesen aus
  // FutureProvidern, deren erster Rahmen den Ladezustand zeigt, und
  // eingeblendete Bedienelemente -- der Knopf "Fahrzeug anlegen" -- sind
  // waehrend ihrer Animation noch unsichtbar. Auf einem Werbebild fehlte
  // damit ausgerechnet die Schaltflaeche, um die es geht.
  await tester.pumpAndSettle();
}

Trip demoTrip({
  required int id,
  required int day,
  required double maxSpeed,
  required double distance,
  required int seconds,
}) => Trip(
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

  for (final target in targets) {
    for (final locale in locales) {
      testWidgets('live ($locale, ${target.directory})', (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        await pumpScreen(
          tester,
          target,
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

        await shoot(tester, target, 'live-$locale');
      });

      testWidgets('bestenliste ($locale, ${target.directory})', (tester) async {
        SharedPreferences.setMockInitialValues({'cloudEnabled': true});
        final prefs = await SharedPreferences.getInstance();

        // Bewusst keine Extremwerte: die Seite mahnt an derselben Stelle,
        // keine Begrenzung zu ueberschreiten. Eine Bestenliste mit 220 km/h
        // daneben arbeitete gegen die eigene Aussage.
        const board = RankingBoard(
          entries: [
            RankingEntry(
              rank: 1,
              displayName: 'nordschleife',
              country: 'DE',
              value: 50.0,
            ),
            RankingEntry(
              rank: 2,
              displayName: 'mira_k',
              country: 'AT',
              value: 47.8,
            ),
            RankingEntry(
              rank: 3,
              displayName: 'coho04',
              country: 'DE',
              value: 45.8,
            ),
            RankingEntry(
              rank: 4,
              displayName: 'lenny',
              country: 'CH',
              value: 43.9,
            ),
            RankingEntry(
              rank: 5,
              displayName: 'tessa',
              country: 'NL',
              value: 41.4,
            ),
            RankingEntry(
              rank: 6,
              displayName: 'jonas_w',
              country: 'DE',
              value: 39.2,
            ),
          ],
          me: RankingEntry(
            rank: 3,
            displayName: 'coho04',
            country: 'DE',
            value: 45.8,
          ),
        );

        await pumpScreen(
          tester,
          target,
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              cloudActiveProvider.overrideWith((ref) async => true),
              rankingBoardProvider.overrideWith((ref, arg) async => board),
            ],
            child: frame(
              const RankingScreen(),
              tab: AppTab.ranking,
              locale: locale,
            ),
          ),
        );

        await shoot(tester, target, 'bestenliste-$locale');
      });

      testWidgets('fahrten ($locale, ${target.directory})', (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        await pumpScreen(
          tester,
          target,
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              keptTripsProvider.overrideWith(
                (ref) => [
                  demoTrip(
                    id: 1,
                    day: 17,
                    maxSpeed: 44.4,
                    distance: 42300,
                    seconds: 2410,
                  ),
                  demoTrip(
                    id: 2,
                    day: 15,
                    maxSpeed: 25.0,
                    distance: 12800,
                    seconds: 1180,
                  ),
                  demoTrip(
                    id: 3,
                    day: 12,
                    maxSpeed: 38.9,
                    distance: 86200,
                    seconds: 4020,
                  ),
                  demoTrip(
                    id: 4,
                    day: 9,
                    maxSpeed: 16.7,
                    distance: 5600,
                    seconds: 720,
                  ),
                  demoTrip(
                    id: 5,
                    day: 6,
                    maxSpeed: 33.3,
                    distance: 27400,
                    seconds: 1640,
                  ),
                  demoTrip(
                    id: 6,
                    day: 4,
                    maxSpeed: 22.2,
                    distance: 9100,
                    seconds: 880,
                  ),
                  demoTrip(
                    id: 7,
                    day: 2,
                    maxSpeed: 41.7,
                    distance: 61500,
                    seconds: 3200,
                  ),
                ],
              ),
            ],
            child: frame(
              const TripListScreen(),
              tab: AppTab.trips,
              locale: locale,
            ),
          ),
        );

        await shoot(tester, target, 'fahrten-$locale');
      });

      testWidgets('garage ($locale, ${target.directory})', (tester) async {
        SharedPreferences.setMockInitialValues({'cloudEnabled': true});
        final prefs = await SharedPreferences.getInstance();

        await pumpScreen(
          tester,
          target,
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              cloudActiveProvider.overrideWith((ref) async => true),
              vehiclesProvider.overrideWith(
                (ref) async => const [
                  Vehicle(
                    id: 1,
                    name: 'Der Golf',
                    isDefault: true,
                    year: 2019,
                    powerPs: 150,
                    model: VehicleModel(
                      id: 7,
                      label: 'VW Golf VII',
                      vehicleClass: 'C-Segment',
                      fuel: 'Dieselmotor',
                    ),
                  ),
                  Vehicle(
                    id: 3,
                    name: 'Der Kombi',
                    isDefault: false,
                    year: 2021,
                    powerPs: 190,
                    model: VehicleModel(
                      id: 11,
                      label: 'VW Passat Variant',
                      vehicleClass: 'Mittelklasse',
                      fuel: 'Dieselmotor',
                    ),
                  ),
                  Vehicle(
                    id: 2,
                    name: 'Winterauto',
                    isDefault: false,
                    year: 2012,
                    powerPs: 105,
                    model: VehicleModel(
                      id: 9,
                      label: 'Škoda Octavia II',
                      vehicleClass: 'Kompaktklasse',
                      fuel: 'Benzinmotor',
                    ),
                  ),
                ],
              ),
            ],
            // Die Garage haengt in den Einstellungen und hat eine eigene
            // Titelleiste -- deshalb ohne den Reiter-Rahmen.
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              locale: Locale(locale),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: SpeedsterTheme.light,
              darkTheme: SpeedsterTheme.dark,
              themeMode: ThemeMode.dark,
              home: const GarageScreen(),
            ),
          ),
        );

        await shoot(tester, target, 'garage-$locale');
      });
    }
  }
}
