import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/app/theme.dart';
import 'package:speedster/cloud/ranking_repository.dart';
import 'package:speedster/settings/settings_controller.dart';
import 'package:speedster/ui/ranking_screen.dart';

void main() {
  testWidgets('shows hint when cloud disabled', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(home: Scaffold(body: RankingScreen())),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Cloud-Sync findest du'), findsOneWidget);
  });

  testWidgets('renders ranking entries and own rank', (tester) async {
    SharedPreferences.setMockInitialValues({'cloudEnabled': true});
    final prefs = await SharedPreferences.getInstance();

    const board = RankingBoard(
      entries: [
        RankingEntry(rank: 1, displayName: 'Fast', country: 'DE', value: 54.2),
        RankingEntry(rank: 2, displayName: 'Slow', country: null, value: 20.0),
      ],
      me: RankingEntry(rank: 2, displayName: 'Du', country: null, value: 20.0),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          // Ohne diese Vorgabe griffe der echte SecureTokenStore auf einen
          // Plattformkanal zu, den es im Test nicht gibt.
          cloudActiveProvider.overrideWith((ref) async => true),
          rankingBoardProvider.overrideWith((ref, arg) async => board),
        ],
        child: const MaterialApp(home: Scaffold(body: RankingScreen())),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Fast'), findsOneWidget);
    expect(find.text('Slow'), findsOneWidget);
    expect(find.text('Dein Rang'), findsOneWidget);
  });

  testWidgets('bietet die Anmeldung an, wenn die Cloud an, aber niemand '
      'angemeldet ist', (tester) async {
    SharedPreferences.setMockInitialValues({'cloudEnabled': true});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          cloudActiveProvider.overrideWith((ref) async => false),
        ],
        child: const MaterialApp(home: Scaffold(body: RankingScreen())),
      ),
    );
    await tester.pump();
    await tester.pump();

    // Ein abgelaufenes Token loeschen Sync und Heatmap von selbst; die
    // Abfrage liefe danach in einen 401. Ein Fehlertext waere dafuer die
    // falsche Antwort -- fehlt nur die Anmeldung, wird sie angeboten.
    expect(find.textContaining('angemeldet sein'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Anmelden'), findsOneWidget);
  });

  testWidgets('die eigene Zeile nimmt Flaeche und Schrift aus demselben '
      'Farbpaar', (tester) async {
    SharedPreferences.setMockInitialValues({'cloudEnabled': true});
    final prefs = await SharedPreferences.getInstance();

    const board = RankingBoard(
      entries: [
        RankingEntry(rank: 1, displayName: 'Fast', country: 'DE', value: 54.2),
      ],
      me: RankingEntry(rank: 7, displayName: 'Du', country: null, value: 20.0),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          cloudActiveProvider.overrideWith((ref) async => true),
          rankingBoardProvider.overrideWith((ref, arg) async => board),
        ],
        child: MaterialApp(
          theme: SpeedsterTheme.light,
          home: const Scaffold(body: RankingScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final scheme = SpeedsterTheme.scheme(Brightness.light);

    // Der Defekt war kein falscher Farbton, sondern ein zerrissenes Paar:
    // die Flaeche kam aus primaryContainer, die Schrift blieb bei der
    // Vordergrundfarbe der gewoehnlichen Flaeche. Das ergab 1,54:1 im
    // Hellmodus und 1,14:1 im Dunkelmodus -- praktisch unsichtbar. Beide
    // Seiten muessen aus demselben Paar stammen.
    final tile = tester.widget<ListTile>(
      find.ancestor(
        of: find.text('Dein Rang'),
        matching: find.byType(ListTile),
      ),
    );
    expect(tile.textColor, scheme.onPrimaryContainer);

    final box = tester.widget<DecoratedBox>(
      find.ancestor(
        of: find.text('Dein Rang'),
        matching: find.byType(DecoratedBox),
      ).first,
    );
    expect((box.decoration as BoxDecoration).color, scheme.primaryContainer);
  });
}
