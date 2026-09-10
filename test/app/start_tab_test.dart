import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speedster/app/app.dart';
import 'package:speedster/app/permissions.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/notifications/trip_notifier.dart';
import 'package:speedster/cloud/trip_cache_service.dart';
import 'package:speedster/domain/trip.dart';
import 'package:speedster/heat/heat_map.dart';
import 'package:speedster/heat/heat_source.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';
import 'package:speedster/recording/trip_recorder.dart';
import 'package:speedster/settings/settings_controller.dart';

class _EmptySource implements HeatSource {
  @override
  Future<HeatMap> load(HeatQuery query) async => HeatMap.empty;
}

Widget wrap(SharedPreferences prefs, Stream<RecorderState> states) =>
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        permissionGateProvider
            .overrideWithValue(FakePermissionGate(granted: false)),
        tripNotifierProvider.overrideWithValue(RecordingTripNotifier()),
        heatSourceProvider.overrideWithValue(_EmptySource()),
        cloudActiveProvider.overrideWith((ref) async => false),
        keptTripsProvider.overrideWith((ref) => []),
        recorderStateProvider.overrideWith((ref) => states),
        tripCacheServiceProvider.overrideWithValue(_NoCache()),
      ],
      child: const MaterialApp(
        locale: Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,home: HomeShell()),
    );

/// Vorrat fuer Tests, die nicht den Rundgang meinen: er ist gesehen,
/// sonst legte er sich beim ersten Frame ueber die Reiter.
Future<SharedPreferences> prefs() async {
  SharedPreferences.setMockInitialValues({
    'consentAccepted': true,
    'tourSeen': true,
  });
  return SharedPreferences.getInstance();
}

/// Beschriftung des gewaehlten Reiters.
///
/// Bewusst nicht der Index: "Live" erscheint nur waehrend der Fahrt, die
/// Positionen verschieben sich also. Ein Index truege dann je nach
/// Fahrzustand eine andere Bedeutung.
String selectedTab(WidgetTester tester) {
  final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));

  return (bar.destinations[bar.selectedIndex] as NavigationDestination).label;
}

List<String> tabLabels(WidgetTester tester) {
  final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));

  return [
    for (final d in bar.destinations) (d as NavigationDestination).label,
  ];
}

/// Kein Cache-Lauf in diesen Tests: der Vorrat wird eigens in
/// test/cloud/trip_cache_service_test.dart geprueft, hier geht es um die
/// Tab-Auswahl. Ohne diese Umsetzung zoege der Start-Lauf Datenbank und
/// HTTP-Client in den Test.
class _NoCache implements TripCache {
  @override
  Future<CacheResult> refresh() async => CacheResult.skipped;
}

void main() {
  testWidgets('startet auf der Heatmap, wenn nicht gefahren wird',
      (tester) async {
    await tester.pumpWidget(wrap(await prefs(), Stream.value(const RecorderState())));
    await tester.pumpAndSettle();

    expect(selectedTab(tester), 'Heatmap');
    expect(find.text('Heatmap'), findsWidgets);
  });

  testWidgets('startet auf Live, wenn bereits gefahren wird', (tester) async {
    await tester.pumpWidget(
      wrap(await prefs(), Stream.value(const RecorderState(isDriving: true))),
    );
    await tester.pumpAndSettle();

    expect(selectedTab(tester), 'Live');
  });

  testWidgets('springt bei Fahrtbeginn auf Live und am Ende zurueck',
      (tester) async {
    final controller = StreamController<RecorderState>.broadcast();
    addTearDown(controller.close);

    await tester.pumpWidget(wrap(await prefs(), controller.stream));
    controller.add(const RecorderState());
    await tester.pumpAndSettle();
    expect(selectedTab(tester), 'Heatmap');

    controller.add(const RecorderState(isDriving: true));
    await tester.pumpAndSettle();
    expect(selectedTab(tester), 'Live');

    // Frueher blieb die Ansicht nach dem Fahrtende auf Live stehen, um sie
    // dem Nutzer nicht unter dem Finger wegzuziehen. Seit "Live" nur
    // waehrend der Fahrt erscheint, gibt es den Reiter danach nicht mehr --
    // die Auswahl muss also zurueck auf die Heatmap.
    controller.add(const RecorderState());
    await tester.pumpAndSettle();
    expect(selectedTab(tester), 'Heatmap');
  });

  testWidgets('zeigt Live nur waehrend der Fahrt', (tester) async {
    final controller = StreamController<RecorderState>.broadcast();
    addTearDown(controller.close);

    await tester.pumpWidget(wrap(await prefs(), controller.stream));
    controller.add(const RecorderState());
    await tester.pumpAndSettle();

    // Eine Tachoansicht im Stand zeigt eine Null und nimmt dauerhaft
    // einen von fuenf Plaetzen ein.
    expect(tabLabels(tester), isNot(contains('Live')));
    expect(tabLabels(tester),
        ['Heatmap', 'Fahrten', 'Garage', 'Ranking', 'Einstellungen']);

    controller.add(const RecorderState(isDriving: true));
    await tester.pumpAndSettle();

    // Live nimmt den Platz der Garage ein: fuenf Reiter sind das
    // Aeusserste, was in die Leiste passt.
    expect(
      tabLabels(tester),
      ['Heatmap', 'Live', 'Fahrten', 'Ranking', 'Einstellungen'],
      reason: 'Live sitzt zwischen Heatmap und Fahrten, nicht am Ende',
    );
  });

  testWidgets('fuehrt die Garage als eigenen Reiter', (tester) async {
    // Zweimal war sie zu versteckt -- erst in den Einstellungen, dann als
    // Symbol in der Titelleiste. Jetzt steht sie in der Leiste.
    await tester.pumpWidget(wrap(await prefs(), const Stream.empty()));
    await tester.pumpAndSettle();

    expect(find.text('Garage'), findsOneWidget);

    await tester.tap(find.text('Garage'));
    await tester.pumpAndSettle();

    expect(selectedTab(tester), 'Garage');
  });

  testWidgets('zeigt den Rundgang beim ersten Start, danach nicht mehr',
      (tester) async {
    // Er kommt nach der Einwilligung und vor dem Anfragen-Dialog -- sonst
    // beantwortet man etwas, das man noch nicht einordnen kann.
    SharedPreferences.setMockInitialValues({'consentAccepted': true});
    final first = await SharedPreferences.getInstance();

    await tester.pumpWidget(wrap(first, const Stream.empty()));
    await tester.pumpAndSettle();

    expect(find.text('Willkommen bei Speedster'), findsOneWidget);

    await tester.tap(find.text('Überspringen'));
    await tester.pumpAndSettle();

    expect(find.text('Willkommen bei Speedster'), findsNothing);

    // Zweiter Start mit demselben Vorrat: kein Rundgang mehr.
    await tester.pumpWidget(wrap(first, const Stream.empty()));
    await tester.pumpAndSettle();

    expect(find.text('Willkommen bei Speedster'), findsNothing);
  });

  testWidgets('laedt die Fahrten bei jedem Aufruf des Reiters neu',
      (tester) async {
    // Bei aktiver Cloud fuehrt sie die Liste, und seit dem letzten Blick
    // kann etwas dazugekommen sein -- von einem anderen Geraet oder aus
    // dem Web. Der IndexedStack behaelt den Bildschirm, also laed er von
    // sich aus nichts nach.
    var loads = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(await prefs()),
          permissionGateProvider
              .overrideWithValue(FakePermissionGate(granted: false)),
          tripNotifierProvider.overrideWithValue(RecordingTripNotifier()),
          heatSourceProvider.overrideWithValue(_EmptySource()),
          cloudActiveProvider.overrideWith((ref) async => false),
          recorderStateProvider.overrideWith((ref) => const Stream.empty()),
          tripCacheServiceProvider.overrideWithValue(_NoCache()),
          keptTripsProvider.overrideWith((ref) {
            loads++;

            return <Trip>[];
          }),
        ],
        child: const MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HomeShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final before = loads;

    await tester.tap(find.text('Fahrten'));
    await tester.pumpAndSettle();

    expect(loads, greaterThan(before));
  });
}
