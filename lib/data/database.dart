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

@DriftDatabase(tables: [Trips, TrackPoints, HeatCells, HeatEdges])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// In-memory database for tests.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

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
        },
      );
}
