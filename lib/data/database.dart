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

@DriftDatabase(tables: [Trips, TrackPoints])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// In-memory database for tests.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(trips, trips.clientUuid);
            await m.addColumn(trips, trips.syncedAt);
          }
        },
      );
}
