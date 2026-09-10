import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/cloud/cloud_sync_service.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';
import 'package:speedster/settings/settings_controller.dart';
import 'package:speedster/ui/settings_screen.dart';

class MockSync extends Mock implements CloudSyncService {}

Future<void> pumpSettings(
  WidgetTester tester, {
  required bool cloud,
  CloudSyncService? sync,
  int pending = 0,
}) async {
  SharedPreferences.setMockInitialValues({'cloudEnabled': cloud});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        if (sync != null) cloudSyncServiceProvider.overrideWithValue(sync),
        pendingUploadsProvider.overrideWith((ref) async => pending),
        cloudAccountProvider.overrideWith((ref) async => null),
      ],
      child: const MaterialApp(
        locale: Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Scrollt zur Upload-Zeile.
///
/// Die Einstellungen sind eine lange ListView; sie baut nur, was in die
/// Naehe des Fensters kommt -- ohne Scrollen findet der Test die Zeile
/// nicht, obwohl sie da ist.
Future<void> scrollToPending(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.byIcon(Icons.cloud_upload_outlined),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('bleibt ohne Cloud unsichtbar', (tester) async {
    // Ohne Konto wartet nichts -- die Fahrten liegen dort, wo sie
    // hingehoeren.
    await pumpSettings(tester, cloud: false);

    expect(find.text('Warten auf Upload'), findsNothing);
  });

  testWidgets('nennt die Zahl der wartenden Fahrten', (tester) async {
    await pumpSettings(tester, cloud: true, pending: 3);
    await scrollToPending(tester);

    expect(find.text('Warten auf Upload'), findsOneWidget);
    expect(find.textContaining('3 Fahrten warten'), findsOneWidget);
  });

  testWidgets('sagt es auch, wenn alles oben ist', (tester) async {
    await pumpSettings(tester, cloud: true);
    await scrollToPending(tester);

    expect(find.textContaining('Alle Fahrten sind in der Cloud'),
        findsOneWidget);
  });

  testWidgets('meldet abgewiesene Fahrten statt sie zu verschweigen',
      (tester) async {
    // Ohne diese Auskunft ist der Upload eine Blackbox: die Fahrt fehlt,
    // und niemand kann sagen warum.
    final sync = MockSync();
    when(() => sync.pendingCount()).thenAnswer((_) async => 2);
    when(() => sync.syncOnce()).thenAnswer((_) async {});
    when(() => sync.rejected).thenReturn({'uuid-1'});

    await pumpSettings(tester, cloud: true, sync: sync, pending: 2);
    await scrollToPending(tester);
    await tester.tap(find.text('Jetzt hochladen'));
    await tester.pumpAndSettle();

    expect(find.textContaining('abgewiesen'), findsOneWidget);
  });

  testWidgets('meldet einen fehlenden Upload als Verbindungsproblem',
      (tester) async {
    final sync = MockSync();
    when(() => sync.pendingCount()).thenAnswer((_) async => 1);
    when(() => sync.syncOnce()).thenThrow(Exception('kein Netz'));
    when(() => sync.rejected).thenReturn(<String>{});

    await pumpSettings(tester, cloud: true, sync: sync, pending: 1);
    await scrollToPending(tester);
    await tester.tap(find.text('Jetzt hochladen'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Verbindung'), findsOneWidget);
  });
}
