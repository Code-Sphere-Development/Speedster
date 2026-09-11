import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speedster/app/app.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/data/database.dart';
import 'package:speedster/settings/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
