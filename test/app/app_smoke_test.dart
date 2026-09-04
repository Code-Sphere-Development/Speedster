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

class _EmptyHeatSource implements HeatSource {
  @override
  Future<HeatMap> load(HeatQuery query) async => HeatMap.empty;
}

void main() {
  testWidgets('renders the five-tab shell when consent accepted',
      (tester) async {
    SharedPreferences.setMockInitialValues({'consentAccepted': true});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          permissionGateProvider
              .overrideWithValue(FakePermissionGate(granted: false)),
          keptTripsProvider.overrideWith((ref) => []),
          heatSourceProvider.overrideWithValue(_EmptyHeatSource()),
          cloudActiveProvider.overrideWith((ref) async => false),
          recorderStateProvider
              .overrideWith((ref) => const Stream<RecorderState>.empty()),
        ],
        child: const SpeedsterApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Heatmap'), findsWidgets);
    expect(find.text('Live'), findsOneWidget);
    expect(find.text('Fahrten'), findsOneWidget);
    expect(find.text('Ranking'), findsOneWidget);
    expect(find.text('Einstellungen'), findsOneWidget);
  });
}
