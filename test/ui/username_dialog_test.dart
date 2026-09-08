import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/cloud/account_repository.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';
import 'package:speedster/ui/username_dialog.dart';

class MockAccounts extends Mock implements AccountRepository {}

CloudAccount account({String? username = 'collin', DateTime? changeableAt}) =>
    CloudAccount(
      name: 'Collin',
      username: username,
      email: 'a@b.c',
      usernameChangeableAt: changeableAt,
    );

Future<void> pumpDialog(
  WidgetTester tester,
  CloudAccount value, {
  AccountRepository? repo,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (repo != null) accountRepositoryProvider.overrideWithValue(repo),
        cloudAccountProvider.overrideWith((ref) async => value),
      ],
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: UsernameDialog(account: value)),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('beginnt mit dem heutigen Namen', (tester) async {
    await pumpDialog(tester, account());

    expect(find.widgetWithText(TextField, 'collin'), findsOneWidget);
  });

  testWidgets('faengt einen Formatfehler ab, ohne zu senden', (tester) async {
    // Sonst kommt der Tippfehler erst nach einem Netzwerk-Roundtrip
    // zurueck.
    final repo = MockAccounts();
    await pumpDialog(tester, account(), repo: repo);

    await tester.enterText(find.byType(TextField), 'AB');
    await tester.tap(find.text('Speichern'));
    await tester.pump();

    expect(find.textContaining('3 bis 30 Zeichen'), findsOneWidget);
    verifyNever(() => repo.changeUsername(any()));
  });

  testWidgets('sendet den normalisierten Namen', (tester) async {
    final repo = MockAccounts();
    when(() => repo.changeUsername(any()))
        .thenAnswer((_) async => account(username: 'coho04'));

    await pumpDialog(tester, account(), repo: repo);
    await tester.enterText(find.byType(TextField), '  CoHo04 ');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    verify(() => repo.changeUsername('coho04')).called(1);
  });

  testWidgets('zeigt die Meldung des Servers woertlich', (tester) async {
    // Der Server unterscheidet "vergeben" von "erst kuerzlich
    // gewechselt" -- eine eigene Meldung waere ungenauer.
    final repo = MockAccounts();
    when(() => repo.changeUsername(any())).thenThrow(
      const AccountException('Dieser Benutzername ist bereits vergeben.'),
    );

    await pumpDialog(tester, account(), repo: repo);
    await tester.enterText(find.byType(TextField), 'belegt');
    await tester.tap(find.text('Speichern'));
    await tester.pump();

    expect(find.text('Dieser Benutzername ist bereits vergeben.'),
        findsOneWidget);
  });

  testWidgets('faellt ohne Antwort auf einen eigenen Text zurueck',
      (tester) async {
    final repo = MockAccounts();
    when(() => repo.changeUsername(any()))
        .thenThrow(const AccountException(null));

    await pumpDialog(tester, account(), repo: repo);
    await tester.enterText(find.byType(TextField), 'coho04');
    await tester.tap(find.text('Speichern'));
    await tester.pump();

    expect(find.textContaining('Verbindung'), findsOneWidget);
  });

  testWidgets('sperrt das Feld und nennt den Grund', (tester) async {
    // Ein gesperrtes Feld ohne Begruendung liest sich wie ein Fehler.
    await pumpDialog(
      tester,
      account(changeableAt: DateTime.now().add(const Duration(days: 12))),
    );

    expect(find.textContaining('Wechsel wieder möglich am'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).enabled,
      isFalse,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('laesst eine abgelaufene Sperre wieder zu', (tester) async {
    await pumpDialog(
      tester,
      account(changeableAt: DateTime.now().subtract(const Duration(days: 1))),
    );

    expect(
      tester.widget<TextField>(find.byType(TextField)).enabled,
      isTrue,
    );
  });
}
