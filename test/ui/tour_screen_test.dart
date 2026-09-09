import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';
import 'package:speedster/settings/settings_controller.dart';
import 'package:speedster/ui/tour_screen.dart';

Future<SharedPreferences> prefs() async {
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences.getInstance();
}

Future<void> pumpTour(WidgetTester tester, SharedPreferences p) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(p)],
      child: const MaterialApp(
        locale: Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TourScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('beginnt mit der Begruessung', (tester) async {
    await pumpTour(tester, await prefs());

    expect(find.text('Willkommen bei Speedster'), findsOneWidget);
    expect(find.text('Weiter'), findsOneWidget);
  });

  testWidgets('fuehrt durch alle Reiter und endet mit Live', (tester) async {
    // Live steht zuletzt, weil dieser Reiter beim ersten Start gar nicht
    // da ist -- ihn zwischen den anderen zu zeigen, waere verwirrend.
    final p = await prefs();
    await pumpTour(tester, p);

    for (final titel in ['Heatmap', 'Fahrten', 'Bestenliste', 'Einstellungen']) {
      await tester.tap(find.text('Weiter'));
      await tester.pumpAndSettle();
      expect(find.text(titel), findsOneWidget);
    }

    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();

    expect(find.text('Live'), findsOneWidget);
    // Auf der letzten Seite steht der Abschluss, nicht "Weiter".
    expect(find.text('Weiter'), findsNothing);
    expect(find.text("Los geht's"), findsOneWidget);
  });

  testWidgets('merkt sich den Rundgang auch beim Ueberspringen',
      (tester) async {
    // Wer ihn wegwischt, will ihn nicht beim naechsten Start wiederhaben.
    final p = await prefs();
    await pumpTour(tester, p);

    await tester.tap(find.text('Überspringen'));
    await tester.pumpAndSettle();

    expect(p.getBool('tourSeen'), isTrue);
  });

  testWidgets('merkt ihn sich am Ende ebenso', (tester) async {
    final p = await prefs();
    await pumpTour(tester, p);

    for (var i = 0; i < 5; i++) {
      await tester.tap(find.text('Weiter'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text("Los geht's"));
    await tester.pumpAndSettle();

    expect(p.getBool('tourSeen'), isTrue);
  });
}
