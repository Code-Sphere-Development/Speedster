import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

    expect(find.textContaining('Cloud-Sync'), findsOneWidget);
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
}
