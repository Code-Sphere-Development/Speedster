import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speedster/settings/settings_controller.dart';
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

  testWidgets('behauptet nicht mehr, es finde kein Upload statt',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(home: ConsentScreen()),
      ),
    );

    // Der Text war die Grundlage der Einwilligung und seit Phase 2 falsch:
    // die Cloud-Synchronisierung laedt vollstaendige GPS-Spuren hoch.
    expect(find.textContaining('kein Upload'), findsNothing);

    // Nicht nur das Stichwort pruefen: die Zusicherung ist, dass der Text
    // benennt WAS uebertragen wird und WOHIN. Sonst koennte die Aussage
    // spaeter stillschweigend verwaessert werden, ohne dass ein Test bricht.
    expect(find.textContaining('Cloud-Synchronisierung'), findsOneWidget);
    expect(find.textContaining('Streckenverlauf'), findsOneWidget);
    expect(find.textContaining('übertragen'), findsOneWidget);
  });
}
