import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/cloud/auth_repository.dart';
import 'package:speedster/cloud/token_store.dart';
import 'package:speedster/ui/auth_screen.dart';

/// Merkt sich nur, ob registriert wurde — die Vorabprüfung des
/// Benutzernamens soll den Aufruf gar nicht erst auslösen.
class _RecordingAuthRepository extends AuthRepository {
  _RecordingAuthRepository()
      : super(dio: Dio(), tokenStore: InMemoryTokenStore());

  bool registerCalled = false;

  @override
  Future<void> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    registerCalled = true;
  }
}

void main() {
  testWidgets('renders login form with email and social buttons', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AuthScreen())),
    );

    expect(find.widgetWithText(TextField, 'E-Mail'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Passwort'), findsOneWidget);
    expect(find.text('Mit Apple anmelden'), findsOneWidget);
    expect(find.text('Mit Google anmelden'), findsOneWidget);
  });

  testWidgets('toggles to register mode', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AuthScreen())),
    );

    await tester.tap(find.text('Neu hier? Konto erstellen'));
    await tester.pump();

    expect(find.widgetWithText(TextField, 'Name'), findsOneWidget);
    expect(find.text('Konto erstellen'), findsWidgets);
  });

  testWidgets('register mode asks for a username', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AuthScreen())),
    );

    await tester.tap(find.text('Neu hier? Konto erstellen'));
    await tester.pump();

    expect(find.widgetWithText(TextField, 'Benutzername'), findsOneWidget);
  });

  testWidgets('an invalid username is rejected without calling the server',
      (tester) async {
    final repo = _RecordingAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: AuthScreen()),
      ),
    );

    await tester.tap(find.text('Neu hier? Konto erstellen'));
    await tester.pump();

    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Collin');
    await tester.enterText(
      find.widgetWithText(TextField, 'Benutzername'),
      'ab',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'E-Mail'),
      'a@b.c',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Passwort'),
      'secret12',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Konto erstellen'));
    await tester.pump();

    expect(repo.registerCalled, isFalse);
    expect(find.textContaining('3 bis 30'), findsOneWidget);
  });
}
