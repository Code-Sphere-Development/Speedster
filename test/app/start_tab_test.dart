import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speedster/app/app.dart';
import 'package:speedster/app/permissions.dart';
import 'package:speedster/app/providers.dart';
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
      ],
      child: const MaterialApp(home: HomeShell()),
    );

Future<SharedPreferences> prefs() async {
  SharedPreferences.setMockInitialValues({'consentAccepted': true});
  return SharedPreferences.getInstance();
}

int selectedTab(WidgetTester tester) =>
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

void main() {
  testWidgets('startet auf der Heatmap, wenn nicht gefahren wird',
      (tester) async {
    await tester.pumpWidget(wrap(await prefs(), Stream.value(const RecorderState())));
    await tester.pumpAndSettle();

    expect(selectedTab(tester), HomeShell.heatmapTab);
    expect(find.text('Heatmap'), findsWidgets);
  });

  testWidgets('startet auf Live, wenn bereits gefahren wird', (tester) async {
    await tester.pumpWidget(
      wrap(await prefs(), Stream.value(const RecorderState(isDriving: true))),
    );
    await tester.pumpAndSettle();

    expect(selectedTab(tester), HomeShell.liveTab);
  });

  testWidgets('springt bei Fahrtbeginn auf Live, aber nicht zurueck',
      (tester) async {
    final controller = StreamController<RecorderState>.broadcast();
    addTearDown(controller.close);

    await tester.pumpWidget(wrap(await prefs(), controller.stream));
    controller.add(const RecorderState());
    await tester.pumpAndSettle();
    expect(selectedTab(tester), HomeShell.heatmapTab);

    controller.add(const RecorderState(isDriving: true));
    await tester.pumpAndSettle();
    expect(selectedTab(tester), HomeShell.liveTab);

    // Fahrtende darf die Ansicht nicht zurueckreissen.
    controller.add(const RecorderState());
    await tester.pumpAndSettle();
    expect(selectedTab(tester), HomeShell.liveTab);
  });
}
