import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/data/backup_service.dart';
import 'package:speedster/data/database.dart';

Future<int> addTrip(
  AppDatabase db, {
  required String uuid,
  String? purpose,
  int points = 2,
}) async {
  final id = await db.into(db.trips).insert(
        TripsCompanion.insert(
          startTime: DateTime(2026, 8, 17, 17, 42),
          endTime: const Value.absent(),
          distance: const Value(42300),
          maxSpeed: const Value(44.4),
          clientUuid: Value(uuid),
          purpose: Value(purpose),
        ),
      );

  for (var i = 0; i < points; i++) {
    await db.into(db.trackPoints).insert(
          TrackPointsCompanion.insert(
            tripId: id,
            lat: 51 + i / 1000,
            lng: 6.9,
            speed: 20,
            altitude: 40,
            accuracy: 3,
            timestamp: DateTime(2026, 8, 17, 17, 42 + i),
          ),
        );
  }

  return id;
}

void main() {
  late AppDatabase db;
  late Directory dir;
  late BackupService backup;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dir = Directory.systemTemp.createTempSync('speedster-backup');
    backup = BackupService(db, dir);
  });

  tearDown(() async {
    await db.close();
    dir.deleteSync(recursive: true);
  });

  test('schreibt Fahrten samt Punkten in eine lesbare Datei', () async {
    // JSON und nicht die Datenbankdatei: die traegt ein Schema, das sich
    // aendert, und laesst sich nicht ansehen.
    await addTrip(db, uuid: 'fahrt-1', purpose: 'commute');

    final file = await backup.export(now: DateTime(2026, 9, 9));

    expect(file.path, endsWith('speedster-sicherung-2026-09-09.json'));
    final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(data['version'], BackupService.formatVersion);
    expect((data['trips'] as List).single['client_uuid'], 'fahrt-1');
    expect((data['trips'] as List).single['purpose'], 'commute');
    expect(((data['trips'] as List).single['points'] as List), hasLength(2));
  });

  test('liest eine Sicherung auf ein leeres Geraet ein', () async {
    await addTrip(db, uuid: 'fahrt-1');
    final file = await backup.export();

    final leer = AppDatabase.forTesting(NativeDatabase.memory());
    final result = await BackupService(leer, dir).importFrom(file);

    expect(result.imported, 1);
    expect(await leer.select(leer.trips).get(), hasLength(1));
    expect(await leer.select(leer.trackPoints).get(), hasLength(2));
    await leer.close();
  });

  test('uebergeht Fahrten, die es schon gibt', () async {
    // Zweimal einlesen darf keine doppelten Fahrten erzeugen, und eine
    // Sicherung muss sich auch auf ein Geraet mit Bestand legen lassen.
    await addTrip(db, uuid: 'fahrt-1');
    final file = await backup.export();

    final result = await backup.importFrom(file);

    expect(result.imported, 0);
    expect(result.skipped, 1);
    expect(await db.select(db.trips).get(), hasLength(1));
  });

  test('laesst die Heatmap nachfalten', () async {
    // heatFoldedAt bleibt leer -- sonst fehlten die eingelesenen Fahrten
    // dauerhaft in der Heatmap.
    await addTrip(db, uuid: 'fahrt-1');
    final file = await backup.export();

    final leer = AppDatabase.forTesting(NativeDatabase.memory());
    await BackupService(leer, dir).importFrom(file);

    final trip = (await leer.select(leer.trips).get()).single;
    expect(trip.heatFoldedAt, isNull);
    await leer.close();
  });

  test('weist eine fremde Datei ab, statt sie halb einzulesen', () async {
    final fremd = File('${dir.path}/fremd.json')
      ..writeAsStringSync('{"foo": "bar"}');

    expect(() => backup.importFrom(fremd), throwsFormatException);
  });

  test('weist eine neuere Fassung ab', () async {
    // Ein alter Stand kann eine spaetere Fassung nicht kennen; sie
    // stillschweigend halb einzulesen waere schlimmer als der Fehler.
    final neuer = File('${dir.path}/neu.json')
      ..writeAsStringSync(jsonEncode({'version': 99, 'trips': []}));

    expect(() => backup.importFrom(neuer), throwsFormatException);
  });

  test('listet vorhandene Sicherungen, neueste zuerst', () async {
    await addTrip(db, uuid: 'fahrt-1');
    await backup.export(now: DateTime(2026, 9, 1));
    await backup.export(now: DateTime(2026, 9, 9));

    final files = await backup.available();

    expect(files, hasLength(2));
    expect(files.first.path, contains('2026-09-09'));
  });
}
