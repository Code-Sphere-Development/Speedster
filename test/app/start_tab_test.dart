import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speedster/app/app.dart';
import 'package:speedster/app/permissions.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/cloud/trip_cache_service.dart';
import 'package:speedster/heat/heat_map.dart';
import 'package:speedster/heat/heat_source.dart';
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
        heatSourceProvider.overrideWithValue(_EmptySource()),
        cloudActiveProvider.overrideWith((ref) async => false),
        keptTripsProvider.overrideWith((ref) => []),
        recorderStateProvider.overrideWith((ref) => states),
        tripCacheServiceProvider.overrideWithValue(_NoCache()),
      ],
      child: const MaterialApp(home: HomeShell()),
    );

Future<SharedPreferences> prefs() async {
  SharedPreferences.setMockInitialValues({'consentAccepted': true});
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
    expect(tabLabels(tester), ['Heatmap', 'Fahrten', 'Ranking', 'Einstellungen']);

    controller.add(const RecorderState(isDriving: true));
    await tester.pumpAndSettle();

    expect(
      tabLabels(tester),
      ['Heatmap', 'Live', 'Fahrten', 'Ranking', 'Einstellungen'],
      reason: 'Live sitzt zwischen Heatmap und Fahrten, nicht am Ende',
    );
  });
}
