import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/app/permissions.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/app/theme.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';
import 'package:speedster/ui/location_access_prompt.dart';

Future<FakePermissionGate> pump(
  WidgetTester tester,
  LocationAccess access, {
  LocationAccess? afterRequest,
}) async {
  final gate = FakePermissionGate(access: access);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [permissionGateProvider.overrideWithValue(gate)],
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: SpeedsterTheme.dark,
        home: const Scaffold(body: LocationAccessBanner()),
      ),
    ),
  );
  await tester.pumpAndSettle();

  if (afterRequest != null) gate.access = afterRequest;

  return gate;
}

void main() {
  testWidgets('mit "Immer" ist der Hinweis weg', (tester) async {
    await pump(tester, LocationAccess.always);

    expect(find.byType(TextButton), findsNothing);
    expect(find.textContaining('nur erfasst'), findsNothing);
  });

  testWidgets('mit "Beim Verwenden" warnt er vor stillem Verlust',
      (tester) async {
    // Der Fehlerfall ist Datenverlust ohne Fehlermeldung: die App
    // zeichnet scheinbar auf und verliert die Fahrt, sobald iOS sie
    // beendet.
    await pump(tester, LocationAccess.whileInUse);

    expect(find.textContaining('nur erfasst, solange die App läuft'),
        findsOneWidget);
  });

  testWidgets('ohne jede Freigabe sagt er das auch so', (tester) async {
    await pump(tester, LocationAccess.denied);

    expect(find.textContaining('Ohne Standortfreigabe'), findsOneWidget);
  });

  testWidgets('ohne Freigabe fuehrt der Knopf direkt in die Einstellungen',
      (tester) async {
    // Eine Anfrage liefe dort ins Leere.
    final gate = await pump(tester, LocationAccess.denied);

    await tester.tap(find.text('Beheben'));
    await tester.pumpAndSettle();

    expect(gate.settingsOpened, 1);
    expect(gate.alwaysRequests, 0);
  });

  testWidgets('bleibt es bei "Beim Verwenden", weist er den Weg',
      (tester) async {
    // iOS zeigt den Dialog hoechstens einmal je Installation. Ohne diese
    // Nachkontrolle taete der Knopf nichts und sagte nichts.
    final gate = await pump(tester, LocationAccess.whileInUse);

    await tester.tap(find.text('Beheben'));
    await tester.pumpAndSettle();

    expect(gate.alwaysRequests, 1);
    expect(find.textContaining('nur ein einziges Mal'), findsOneWidget);

    await tester.tap(find.text('Einstellungen öffnen'));
    await tester.pumpAndSettle();

    expect(gate.settingsOpened, 1);
  });

  testWidgets('hat die Anfrage gewirkt, kommt kein zweiter Dialog',
      (tester) async {
    final gate = await pump(
      tester,
      LocationAccess.whileInUse,
      afterRequest: LocationAccess.always,
    );

    await tester.tap(find.text('Beheben'));
    await tester.pumpAndSettle();

    expect(gate.alwaysRequests, 1);
    expect(find.textContaining('nur ein einziges Mal'), findsNothing);
    expect(gate.settingsOpened, 0);
  });
}
