import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speedster/app/app.dart';
import 'package:speedster/app/permissions.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/recording/trip_recorder.dart';
import 'package:speedster/settings/settings_controller.dart';

void main() {
  testWidgets('renders the three-tab shell when consent accepted',
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
          recorderStateProvider
              .overrideWith((ref) => const Stream<RecorderState>.empty()),
        ],
        child: const SpeedsterApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Fahrten'), findsOneWidget);
    expect(find.text('Einstellungen'), findsOneWidget);
  });
}
