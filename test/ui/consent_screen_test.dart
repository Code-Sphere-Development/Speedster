import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/ui/consent_screen.dart';

void main() {
  testWidgets('shows disclaimer and accept button', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ConsentScreen()),
      ),
    );
    expect(find.textContaining('eigene Gefahr'), findsOneWidget);
    expect(find.text('Akzeptieren'), findsOneWidget);
  });
}
