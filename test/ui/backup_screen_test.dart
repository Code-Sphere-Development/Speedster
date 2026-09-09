import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/data/database.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';
import 'package:speedster/ui/backup_screen.dart';
import 'package:drift/native.dart';

Future<void> pumpBackup(WidgetTester tester, Directory dir) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        documentsPathProvider.overrideWithValue(dir.path),
        keptTripsProvider.overrideWith((ref) => []),
      ],
      child: const MaterialApp(
        locale: Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BackupScreen(),
      ),
    ),
  );
  // Das Auflisten liest den Ordner -- ebenfalls echte Ein-/Ausgabe.
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sagt, wo die Datei landet, wenn keine da ist', (tester) async {
    // Eine Sicherung, die man nicht findet, sichert nichts.
    final dir = Directory.systemTemp.createTempSync('backup-ui');
    addTearDown(() => dir.deleteSync(recursive: true));

    await pumpBackup(tester, dir);

    expect(find.textContaining('Keine Sicherung gefunden'), findsOneWidget);
    expect(find.text('Sicherung schreiben'), findsOneWidget);
  });

  testWidgets('schreibt eine Sicherung und listet sie danach',
      (tester) async {
    final dir = Directory.systemTemp.createTempSync('backup-ui');
    addTearDown(() => dir.deleteSync(recursive: true));

    await pumpBackup(tester, dir);
    // runAsync um den Tipper herum: Schreiben und Datenbankzugriff laufen
    // ueber echte Asynchronitaet, nicht auf der Testuhr -- pumpAndSettle
    // allein kehrt zurueck, bevor die Datei steht.
    await tester.runAsync(() async {
      await tester.tap(find.text('Sicherung schreiben'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();

    expect(
      dir.listSync().whereType<File>().where(
            (f) => f.path.endsWith('.json'),
          ),
      hasLength(1),
    );
    expect(find.textContaining('speedster-sicherung-'), findsOneWidget);
  });

  testWidgets('meldet eine fremde Datei, statt sie halb einzulesen',
      (tester) async {
    final dir = Directory.systemTemp.createTempSync('backup-ui');
    addTearDown(() => dir.deleteSync(recursive: true));
    File('${dir.path}/fremd.json').writeAsStringSync('{"foo":"bar"}');

    await pumpBackup(tester, dir);
    await tester.runAsync(() async {
      await tester.tap(find.text('Einlesen'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();

    expect(find.textContaining('ließ sich nicht lesen'), findsOneWidget);
  });
}
