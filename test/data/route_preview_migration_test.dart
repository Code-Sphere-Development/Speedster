import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/data/database.dart';
import 'package:speedster/domain/route_preview.dart';

/// Baut eine Datenbank im Schemastand 7 auf -- also ohne `route_preview`.
///
/// Alles im `setup`-Rueckruf, weil drift die Migration beim ersten
/// Zugriff faehrt: was danach eingefuegt wird, sieht sie nicht mehr.
/// Der Typ des Parameters kommt aus `NativeDatabase.memory` -- benannt
/// hingeschrieben brauchte die Datei eine direkte Abhaengigkeit auf
/// `sqlite3`, die die App selbst nicht fuehrt.
///
/// Von Hand und nicht aus einem Schema-Abzug: gebraucht werden nur die
/// beiden Tabellen, die diese Migration anfasst.
void createV7(dynamic raw) {
  raw.execute('''
    CREATE TABLE trips (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      start_time INTEGER NOT NULL,
      end_time INTEGER NULL,
      max_speed REAL NOT NULL DEFAULT 0,
      avg_speed REAL NOT NULL DEFAULT 0,
      distance REAL NOT NULL DEFAULT 0,
      elevation_gain REAL NOT NULL DEFAULT 0,
      duration_seconds INTEGER NOT NULL DEFAULT 0,
      zero_to_hundred_seconds REAL NULL,
      kept INTEGER NOT NULL DEFAULT 1,
      client_uuid TEXT NOT NULL DEFAULT '',
      synced_at INTEGER NULL,
      heat_folded_at INTEGER NULL,
      cloud_vehicle_id INTEGER NULL,
      purpose TEXT NULL,
      note TEXT NULL
    )''');

  raw.execute('''
    CREATE TABLE track_points (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      trip_id INTEGER NOT NULL REFERENCES trips (id) ON DELETE CASCADE,
      lat REAL NOT NULL,
      lng REAL NOT NULL,
      speed REAL NOT NULL,
      altitude REAL NOT NULL,
      accuracy REAL NOT NULL,
      timestamp INTEGER NOT NULL
    )''');

  // Fahrt 1 hat noch ihre Punkte, Fahrt 2 nicht mehr.
  raw.execute('INSERT INTO trips (id, start_time) VALUES (1, 1767225600)');
  raw.execute('INSERT INTO trips (id, start_time) VALUES (2, 1767225600)');
  for (var i = 0; i < 5; i++) {
    raw.execute(
      'INSERT INTO track_points '
      '(trip_id, lat, lng, speed, altitude, accuracy, timestamp) '
      'VALUES (1, ?, 13.4, 10, 0, 5, ?)',
      [52.5 + i * 0.001, 1767225600 + i],
    );
  }

  raw.userVersion = 7;
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory(setup: createV7));
  });

  tearDown(() => db.close());

  test('traegt die Strecke fuer Fahrten mit Punkten nach', () async {
    // Ohne Rueckfuellung zeigte die Fahrtenliste unmittelbar nach der
    // Aktualisierung ueberall nur Platzhalter -- und das sieht aus wie
    // ein Fehler, nicht wie eine neue Funktion.
    final trips = await db.select(db.trips).get();
    expect(db.schemaVersion, 8);

    final migrated = trips.firstWhere((t) => t.id == 1);
    expect(migrated.routePreview, isNotNull);
    expect(RoutePreview.decode(migrated.routePreview), hasLength(5));

    // Fahrten, deren Punkte laengst verdraengt sind, bleiben ohne
    // Strecke: erfinden laesst sie sich nicht.
    final untouched = trips.firstWhere((t) => t.id == 2);
    expect(untouched.routePreview, isNull);
  });
}
