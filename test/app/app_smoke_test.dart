import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speedster/app/app.dart';
import 'package:speedster/app/permissions.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/notifications/trip_notifier.dart';
import 'package:speedster/cloud/trip_cache_service.dart';
import 'package:speedster/heat/heat_map.dart';
import 'package:speedster/heat/heat_source.dart';
import 'package:speedster/recording/trip_recorder.dart';
import 'package:speedster/settings/settings_controller.dart';

class _EmptyHeatSource implements HeatSource {
  @override
  Future<HeatMap> load(HeatQuery query) async => HeatMap.empty;
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
  testWidgets('renders the shell when consent accepted',
      (tester) async {
    // tourSeen: dieser Test meint nicht den Rundgang, und ohne den Haken
  // legte er sich beim ersten Frame ueber die Oberflaeche.
  SharedPreferences.setMockInitialValues({
    'consentAccepted': true,
    'tourSeen': true,
  });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          permissionGateProvider
              .overrideWithValue(FakePermissionGate(granted: false)),
          tripNotifierProvider.overrideWithValue(RecordingTripNotifier()),
          keptTripsProvider.overrideWith((ref) => []),
          heatSourceProvider.overrideWithValue(_EmptyHeatSource()),
          cloudActiveProvider.overrideWith((ref) async => false),
          recorderStateProvider
              .overrideWith((ref) => const Stream<RecorderState>.empty()),
          tripCacheServiceProvider.overrideWithValue(_NoCache()),
        ],
        child: const SpeedsterApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Heatmap'), findsWidgets);
    // "Live" fehlt, solange nicht gefahren wird -- siehe start_tab_test.
    expect(find.text('Live'), findsNothing);
    expect(find.text('Fahrten'), findsOneWidget);
    expect(find.text('Ranking'), findsOneWidget);
    expect(find.text('Einstellungen'), findsOneWidget);
  });
}
