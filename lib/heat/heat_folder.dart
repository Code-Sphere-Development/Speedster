import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:speedster/data/database.dart';
import 'package:speedster/domain/track_point.dart' as domain;
import 'package:speedster/heat/heat_grid.dart';

/// Fuehrt die reine Faltung aus — produktiv in einem eigenen Isolate.
typedef FoldRunner = Future<TripFold> Function(
  TripFold Function(List<domain.TrackPoint>),
  List<domain.TrackPoint>,
);

/// Schreibseite der Heatmap: faltet Fahrten in die Aggregattabellen.
///
/// Die Heatmap ist der Start-Screen und darf beim Oeffnen nicht rechnen,
/// deshalb wird inkrementell pro Fahrt gefaltet statt bei jedem Aufruf
/// ueber die gesamte Punkthistorie zu aggregieren.
class HeatFolder {
  HeatFolder(this.db, {FoldRunner? runner}) : runner = runner ?? compute;

  final AppDatabase db;

  /// Die Rasterung ist der rechenintensive Teil (eine Million Punkte bei
  /// grossen Historien) und gehoert nicht auf den UI-Thread.
  final FoldRunner runner;

  /// Faltet alle behaltenen, noch nicht gefalteten Fahrten.
  /// Deckt neue Fahrten, die Migration auf v3 und verpasste Faltungen ab.
  Future<int> foldPending() async {
    final pending = await (db.select(db.trips)
          ..where((t) => t.kept.equals(true) & t.heatFoldedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
        .get();

    for (final trip in pending) {
      await _foldTrip(trip.id);
    }
    return pending.length;
  }

  /// Verwirft alle Aggregate und baut sie aus den behaltenen Fahrten neu.
  /// Einzelne Fahrten exakt herauszurechnen waere fehleranfaelliger als ein
  /// Neuaufbau, und Ruecknahmen sind selten.
  Future<void> rebuild() async {
    await db.transaction(() async {
      await db.delete(db.heatCells).go();
      await db.delete(db.heatEdges).go();
      await db.update(db.trips).write(
            const TripsCompanion(heatFoldedAt: Value(null)),
          );
    });
    await foldPending();
  }

  Future<void> _foldTrip(int tripId) async {
    final rows = await (db.select(db.trackPoints)
          ..where((p) => p.tripId.equals(tripId))
          ..orderBy([(p) => OrderingTerm.asc(p.timestamp)]))
        .get();

    final points = [
      for (final r in rows)
        domain.TrackPoint(
          tripId: r.tripId,
          lat: r.lat,
          lng: r.lng,
          speed: r.speed,
          altitude: r.altitude,
          accuracy: r.accuracy,
          timestamp: r.timestamp,
        ),
    ];

    final fold = await runner(HeatGrid.foldTrip, points);

    await db.transaction(() async {
      for (var level = 0; level < HeatGrid.levelCount; level++) {
        final lf = fold.levels[level];
        for (final entry in lf.cells.entries) {
          await _upsertCell(level, entry.key, entry.value);
        }
        for (final entry in lf.edges.entries) {
          await _upsertEdge(level, entry.key, entry.value);
        }
      }
      await (db.update(db.trips)..where((t) => t.id.equals(tripId)))
          .write(TripsCompanion(heatFoldedAt: Value(DateTime.now())));
    });
  }

  Future<void> _upsertCell(int level, HeatCell cell, CellAccum accum) async {
    await db.customStatement(
      'INSERT INTO heat_cells (level, cell_row, cell_col, lat_sum, lng_sum, n) '
      'VALUES (?, ?, ?, ?, ?, ?) '
      'ON CONFLICT(level, cell_row, cell_col) DO UPDATE SET '
      'lat_sum = lat_sum + excluded.lat_sum, '
      'lng_sum = lng_sum + excluded.lng_sum, '
      'n = n + excluded.n',
      [level, cell.row, cell.col, accum.latSum, accum.lngSum, accum.n],
    );
  }

  Future<void> _upsertEdge(int level, HeatEdgeKey edge, int count) async {
    await db.customStatement(
      'INSERT INTO heat_edges (level, a_row, a_col, b_row, b_col, count) '
      'VALUES (?, ?, ?, ?, ?, ?) '
      'ON CONFLICT(level, a_row, a_col, b_row, b_col) DO UPDATE SET '
      'count = count + excluded.count',
      [level, edge.a.row, edge.a.col, edge.b.row, edge.b.col, count],
    );
  }
}
