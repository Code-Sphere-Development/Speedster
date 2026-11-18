import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speedster/app/app.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/data/database.dart';
import 'package:speedster/settings/settings_controller.dart';

/// DSN der GlitchTip-Instanz (Sentry-kompatibel), per
/// `--dart-define=SENTRY_DSN=...` beim Build. Steht bewusst nicht im Code:
/// ohne DSN bleibt Sentry aus und die App startet wie zuvor.
const _sentryDsn = String.fromEnvironment('SENTRY_DSN');

/// Ueberschreibt die Umgebung, etwa fuer einen Testflight-Build.
const _sentryEnvironment = String.fromEnvironment('SENTRY_ENVIRONMENT');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_sentryDsn.isEmpty) {
    await _start();
    return;
  }

  // Der Start laeuft als appRunner, damit auch Fehler beim Oeffnen der
  // Datenbank oder beim Scharfmachen der Aufzeichnung gemeldet werden.
  await SentryFlutter.init(
    (options) {
      options.dsn = _sentryDsn;
      options.environment = _sentryEnvironment.isNotEmpty
          ? _sentryEnvironment
          : (kReleaseMode ? 'production' : 'debug');
      options.tracesSampleRate = 0.1;
      // GlitchTip versteht klassische Transaktionen, kein Span-Streaming
      // (Default ab sentry_flutter 10).
      options.traceLifecycle = SentryTraceLifecycle.static;
      // Fahrten und Orte sind personenbezogen genug -- keine IP, kein
      // Nutzer, keine Header.
      options.sendDefaultPii = false;
    },
    appRunner: _start,
  );
}

Future<void> _start() async {
  final prefs = await SharedPreferences.getInstance();
  final documents = await getApplicationDocumentsDirectory();
  final db = await _openDatabase(documents);

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      databaseProvider.overrideWithValue(db),
      // Der Ordner wird hier einmal aufgeloest statt in jedem Provider:
      // die Abfrage ist asynchron und geht ueber einen Plattformkanal,
      // den es im Test nicht gibt.
      documentsPathProvider.overrideWithValue(documents.path),
    ],
  );

  // Hat iOS die App wegen einer Ortsaenderung geweckt, wird sie
  // moeglicherweise nie gezeichnet -- und der Rueckruf nach dem ersten
  // Frame, an dem die Aufzeichnung sonst haengt, liefe nie an. Deshalb
  // hier, vor runApp.
  //
  // Nur in diesem Fall: auf einem gewoehnlichen Start legte sich der
  // Ortungsdialog sonst ueber einen noch schwarzen Bildschirm. Geweckt
  // wird die App ohnehin nur mit erteilter Berechtigung, es fragt also
  // nichts.
  if (await container.read(locationWakeProvider).launchedByLocation()) {
    await container.read(trackingArmerProvider).arm();
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const SpeedsterApp(),
    ),
  );
}

Future<AppDatabase> _openDatabase(Directory dir) async {
  final file = File(p.join(dir.path, 'speedster.sqlite'));
  return AppDatabase(NativeDatabase.createInBackground(file));
}
