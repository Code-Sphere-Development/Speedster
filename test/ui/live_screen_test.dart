import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/domain/sample.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';
import 'package:speedster/recording/trip_recorder.dart';
import 'package:speedster/settings/settings_controller.dart';
import 'package:speedster/ui/live_screen.dart';

void main() {
  testWidgets('shows current speed while driving', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          recorderStateProvider.overrideWith(
            (ref) => Stream.value(
              RecorderState(
                isDriving: true,
                activeTripId: 1,
                distanceMeters: 1500,
                elapsedSeconds: 125,
                last: Sample(
                  lat: 50,
                  lng: 6,
                  speed: 10,
                  altitude: 100,
                  accuracy: 3,
                  timestamp: DateTime(2026),
                ),
              ),
            ),
          ),
        ],
        child: const MaterialApp(
        locale: Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,home: LiveScreen()),
      ),
    );
    await tester.pump();
    // Zahl und Einheit stehen seit dem Umbau in zwei Textknoten: nur so
    // laesst sich die Zahl gross und die Einheit klein setzen.
    expect(find.text('36'), findsOneWidget);
    expect(find.text('km/h'), findsOneWidget);
    // Deutsch: Komma, nicht Punkt.
    expect(find.text('1,5'), findsOneWidget);
    expect(find.text('km'), findsOneWidget);
    expect(find.text('2m 05s'), findsOneWidget);
    // Waehrend der Fahrt, statisch: eine Warnung, die bei hohem Tempo
    // aufpoppt, zoege den Blick genau dann aufs Display, wenn er dort
    // nicht hingehoert.
    expect(find.textContaining('zulässige Höchstgeschwindigkeit'),
        findsOneWidget);
  });

  testWidgets('mahnt nicht, solange keine Fahrt laeuft', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          recorderStateProvider.overrideWith(
            (ref) => Stream.value(const RecorderState(isDriving: false)),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LiveScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('zulässige Höchstgeschwindigkeit'), findsNothing);
  });
}
