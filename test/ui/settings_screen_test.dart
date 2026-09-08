import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/cloud/token_store.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';
import 'package:speedster/settings/settings_controller.dart';
import 'package:speedster/settings/unit_system.dart';
import 'package:speedster/ui/settings_screen.dart';

void main() {
  testWidgets('toggling unit switch updates settings to mph', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
        locale: Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,home: SettingsScreen()),
      ),
    );

    expect(container.read(settingsControllerProvider).unit, UnitSystem.kmh);

    await tester.tap(find.byKey(const Key('unitSwitch')));
    await tester.pump();

    expect(container.read(settingsControllerProvider).unit, UnitSystem.mph);
  });

  testWidgets('enabling cloud while logged out opens auth screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
        ],
        child: const MaterialApp(
        locale: Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,home: SettingsScreen()),
      ),
    );

    await tester.tap(find.byKey(const Key('cloudSwitch')));
    await tester.pumpAndSettle();

    expect(find.text('Mit Apple anmelden'), findsOneWidget); // AuthScreen shown
  });
}

