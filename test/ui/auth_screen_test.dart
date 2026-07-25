import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/ui/auth_screen.dart';

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
}
