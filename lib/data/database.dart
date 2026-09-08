import 'package:drift/drift.dart';

part 'database.g.dart';

class Trips extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  RealColumn get maxSpeed => real().withDefault(const Constant(0))();
  RealColumn get avgSpeed => real().withDefault(const Constant(0))();
  RealColumn get distance => real().withDefault(const Constant(0))();
  RealColumn get elevationGain => real().withDefault(const Constant(0))();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();
  RealColumn get zeroToHundredSeconds => real().nullable()();
  BoolColumn get kept => boolean().withDefault(const Constant(true))();
  TextColumn get clientUuid => text().withDefault(const Constant(''))();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  DateTimeColumn get heatFoldedAt => dateTime().nullable()();
}

class TrackPoints extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tripId =>
      integer().references(Trips, #id, onDelete: KeyAction.cascade)();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  RealColumn get speed => real()();
  RealColumn get altitude => real()();
  RealColumn get accuracy => real()();
  DateTimeColumn get timestamp => dateTime()();
}

/// Schwerpunkt-Summen je Rasterzelle. `n` zaehlt nur real gemessene Punkte.
///
/// Bewusst `cellRow`/`cellCol` statt `row`/`col`: die Namen werden im
/// Backend gespiegelt, und `ROW` ist dort in MySQL 8 ein reserviertes Wort.
@DataClassName('HeatCellRow')
class HeatCells extends Table {
  IntColumn get level => integer()();
  IntColumn get cellRow => integer()();
  IntColumn get cellCol => integer()();
  RealColumn get latSum => real().withDefault(const Constant(0))();
  RealColumn get lngSum => real().withDefault(const Constant(0))();
  IntColumn get n => integer().withDefault(const Constant(0))();

  /// Summe der gemessenen Geschwindigkeiten in dieser Zelle, in m/s.
  ///
  /// Geteilt durch [n] ergibt sie, wie schnell hier ueblicherweise
  /// gefahren wird -- die Bezugsgroesse fuer "zu schnell" auf dem
  /// Sperrbildschirm. Die App kennt keine Tempolimits, und es gibt dafuer
  /// keine brauchbare freie Quelle; verglichen wird deshalb mit der
  /// eigenen Gewohnheit.
  ///
  /// Bewusst **nicht** Teil von `HeatGrid`: jenes ist der zeilengetreue
  /// Spiegel von `HeatGrid.php`, und eine zusaetzliche Spalte hier duerfte
  /// die Rasterparitaet zwischen Dart und PHP nicht beruehren.
  RealColumn get speedSum => real().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {level, cellRow, cellCol};
}

/// Befahrungszaehler je Zelluebergang.
@DataClassName('HeatEdgeRow')
class HeatEdges extends Table {
  IntColumn get level => integer()();
  IntColumn get aRow => integer()();
  IntColumn get aCol => integer()();
  IntColumn get bRow => integer()();
  IntColumn get bCol => integer()();
  IntColumn get count => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {level, aRow, aCol, bRow, bCol};
}

/// Zwischengespeicherte Antwort der Cloud-Heatmap, je Rasterebene und
/// Zeitraum eine Zeile.
///
/// Bei aktiver Cloud kann die Heatmap nicht mehr lokal nachgerechnet
/// werden: es liegen nur noch die zuletzt gefahrenen Strecken als Punkte
/// auf dem Geraet (siehe TripCacheService), alle aelteren nicht. Ohne Netz
/// zeigt deshalb die zuletzt erfolgreich geladene Serverantwort -- deutlich
/// naeher am Wahren als eine Heatmap aus zehn Fahrten.
///
/// Gespeichert wird nur die ungefilterte Abfrage (ohne Kartenausschnitt);
/// eine auf einen Ausschnitt beschnittene Antwort waere als Vorrat
/// wertlos, sobald der Nutzer die Karte verschiebt.
@DataClassName('HeatSnapshotRow')
class HeatSnapshots extends Table {
  IntColumn get level => integer()();
  TextColumn get range => text()();

  /// Kanten und Maximum als JSON. Ein eigenes Tabellenschema dafuer waere
  /// eine zweite, konkurrierende Darstellung derselben Kanten neben
  /// HeatEdges -- der Vorrat wird nur als Ganzes geschrieben und gelesen,
  /// nie einzeln abgefragt.
  TextColumn get payload => text()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {level, range};
}

@DriftDatabase(tables: [Trips, TrackPoints, HeatCells, HeatEdges, HeatSnapshots])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// In-memory database for tests.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(trips, trips.clientUuid);
            await m.addColumn(trips, trips.syncedAt);
          }
          if (from < 3) {
            await m.addColumn(trips, trips.heatFoldedAt);
            await m.createTable(heatCells);
            await m.createTable(heatEdges);
            // Bestandsfahrten bleiben heatFoldedAt = NULL und werden beim
            // ersten Laden der Heatmap nachgefaltet (siehe HeatFolder).
          }
          if (from < 4) {
            await m.createTable(heatSnapshots);
          }
          if (from < 5) {
            await m.addColumn(heatCells, heatCells.speedSum);
            // Bestandszellen starten bei 0 und fuellen sich, sobald wieder
            // gefahren wird. Ein Neuaufbau aus den Punkten waere moeglich,
            // aber bei aktiver Cloud liegen die Punkte aelterer Fahrten gar
            // nicht mehr auf dem Geraet (siehe TripCacheService).
          }
        },
      );
}
