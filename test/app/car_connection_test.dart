import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speedster/app/app.dart';
import 'package:speedster/app/car_connection.dart';
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

Widget wrap(SharedPreferences prefs, {required bool carConnected}) =>
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        permissionGateProvider
            .overrideWithValue(FakePermissionGate(granted: false)),
        heatSourceProvider.overrideWithValue(_EmptySource()),
        cloudActiveProvider.overrideWith((ref) async => false),
        keptTripsProvider.overrideWith((ref) => []),
        recorderStateProvider
            .overrideWith((ref) => Stream.value(const RecorderState())),
        carConnectedProvider.overrideWith((ref) => Stream.value(carConnected)),
        tripCacheServiceProvider.overrideWithValue(_NoCache()),
      ],
      child: const MaterialApp(home: HomeShell()),
    );

Future<SharedPreferences> prefs() async {
  SharedPreferences.setMockInitialValues({'consentAccepted': true});
  return SharedPreferences.getInstance();
}

int selectedTab(WidgetTester tester) =>
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

/// Kein Cache-Lauf in diesen Tests: der Vorrat wird eigens in
/// test/cloud/trip_cache_service_test.dart geprueft, hier geht es um die
/// Tab-Auswahl. Ohne diese Umsetzung zoege der Start-Lauf Datenbank und
/// HTTP-Client in den Test.
class _NoCache implements TripCache {
  @override
  Future<CacheResult> refresh() async => CacheResult.skipped;
}

void main() {
  test('FakeCarConnection reicht den Stream durch', () async {
    final fake = FakeCarConnection(Stream.fromIterable([false, true]));
    expect(await fake.connected.toList(), [false, true]);
  });

  testWidgets('ohne Auto-Verbindung startet die Heatmap', (tester) async {
    await tester.pumpWidget(wrap(await prefs(), carConnected: false));
    await tester.pumpAndSettle();
    expect(selectedTab(tester), HomeShell.heatmapTab);
  });

  testWidgets('mit Auto-Verbindung startet Live, auch ohne isDriving',
      (tester) async {
    await tester.pumpWidget(wrap(await prefs(), carConnected: true));
    await tester.pumpAndSettle();
    expect(selectedTab(tester), HomeShell.liveTab);
  });
}
