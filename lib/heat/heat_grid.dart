import 'dart:math' as math;

import 'package:speedster/domain/track_point.dart';
import 'package:speedster/stats/stats_engine.dart';

/// Eine quantisierte Rasterzelle auf einer Pyramidenebene.
class HeatCell {
  const HeatCell(this.row, this.col);

  final int row;
  final int col;

  @override
  bool operator ==(Object other) =>
      other is HeatCell && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => 'HeatCell($row, $col)';
}

/// Ungerichtete Kante zwischen zwei benachbarten Zellen.
class HeatEdgeKey {
  const HeatEdgeKey(this.a, this.b);

  /// Sortiert die Endpunkte, damit Hin- und Rueckrichtung denselben
  /// Schluessel ergeben.
  factory HeatEdgeKey.normalized(HeatCell x, HeatCell y) {
    final xFirst = x.row < y.row || (x.row == y.row && x.col <= y.col);
    return xFirst ? HeatEdgeKey(x, y) : HeatEdgeKey(y, x);
  }

  final HeatCell a;
  final HeatCell b;

  @override
  bool operator ==(Object other) =>
      other is HeatEdgeKey && other.a == a && other.b == b;

  @override
  int get hashCode => Object.hash(a, b);

  @override
  String toString() => 'HeatEdgeKey($a -> $b)';
}

/// Laufende Summen fuer den Schwerpunkt einer Zelle.
class CellAccum {
  double latSum = 0;
  double lngSum = 0;
  int n = 0;

  void add(double lat, double lng) {
    latSum += lat;
    lngSum += lng;
    n++;
  }
}

/// Aggregat einer Fahrt auf einer Rasterebene.
class LevelFold {
  final Map<HeatCell, CellAccum> cells = {};
  final Map<HeatEdgeKey, int> edges = {};
}

/// Aggregat einer Fahrt ueber alle Rasterebenen.
class TripFold {
  TripFold() : levels = List.generate(HeatGrid.levelCount, (_) => LevelFold());

  final List<LevelFold> levels;
}

/// Reine Rasterlogik. Spiegel von `backend/app/Services/HeatGrid.php` —
/// jede Aenderung hier muss dort nachgezogen werden, sonst weicht die
/// Cloud-Heatmap sichtbar von der lokalen ab.
class HeatGrid {
  const HeatGrid._();

  static const List<double> cellMeters = [25.0, 100.0, 400.0];
  static const int levelCount = 3;
  static const double metersPerDegLat = 111320.0;
  static const double cosClamp = 0.01;
  static const double maxAccuracyMeters = 50.0;
  static const double maxGapMeters = 200.0;
  static const int maxGapSeconds = 30;
  static const double resampleMeters = 10.0;

  static double latStep(int level) => cellMeters[level] / metersPerDegLat;

  /// Quantisiert eine Koordinate. [HeatCell.row] haengt nur von [lat] ab und
  /// die Laengengrad-Schrittweite nur von der Zeile — dadurch ist die
  /// Rechnung nicht selbstbezueglich und in jeder Sprache reproduzierbar.
  static HeatCell cellFor(double lat, double lng, int level) {
    final step = latStep(level);
    final row = (lat / step).floor();
    final rowLat = (row + 0.5) * step;
    final lngStep =
        step / math.max(math.cos(rowLat * math.pi / 180.0), cosClamp);
    final col = (lng / lngStep).floor();
    return HeatCell(row, col);
  }

  /// Faltet eine Fahrt in Zell- und Kantenaggregate, fuer alle Level.
  static TripFold foldTrip(List<TrackPoint> points) {
    final fold = TripFold();
    for (final segment in _segments(points)) {
      for (var level = 0; level < levelCount; level++) {
        _foldSegment(segment, level, fold.levels[level]);
      }
    }
    return fold;
  }

  /// Wirft ungenaue Punkte weg und trennt die Spur an Mess-Luecken.
  /// Ohne die Trennung zieht ein GPS-Ausfall im Tunnel eine Gerade quer
  /// durch die Stadt, die sich bei jeder Fahrt aufsummieren wuerde.
  static List<List<TrackPoint>> _segments(List<TrackPoint> points) {
    final result = <List<TrackPoint>>[];
    var current = <TrackPoint>[];

    for (final p in points) {
      if (p.accuracy > maxAccuracyMeters) continue;
      if (current.isEmpty) {
        current.add(p);
        continue;
      }
      final prev = current.last;
      final gap =
          StatsEngine.haversineMeters(prev.lat, prev.lng, p.lat, p.lng);
      final seconds = p.timestamp.difference(prev.timestamp).inSeconds.abs();
      if (gap > maxGapMeters || seconds > maxGapSeconds) {
        if (current.length > 1) result.add(current);
        current = [p];
      } else {
        current.add(p);
      }
    }
    if (current.length > 1) result.add(current);
    return result;
  }

  static void _foldSegment(
    List<TrackPoint> segment,
    int level,
    LevelFold acc,
  ) {
    // Schwerpunkte nur aus echten Messungen.
    for (final p in segment) {
      acc.cells
          .putIfAbsent(cellFor(p.lat, p.lng, level), CellAccum.new)
          .add(p.lat, p.lng);
    }

    final path = <HeatCell>[];
    for (var i = 0; i < segment.length - 1; i++) {
      final from = segment[i];
      final to = segment[i + 1];
      _appendCell(path, cellFor(from.lat, from.lng, level));

      // Nachverdichten, damit bei hohem Tempo keine Zelle uebersprungen wird.
      final distance =
          StatsEngine.haversineMeters(from.lat, from.lng, to.lat, to.lng);
      final steps = (distance / resampleMeters).floor();
      for (var s = 1; s <= steps; s++) {
        final f = s / (steps + 1);
        _appendCell(
          path,
          cellFor(
            from.lat + (to.lat - from.lat) * f,
            from.lng + (to.lng - from.lng) * f,
            level,
          ),
        );
      }
    }
    if (segment.isNotEmpty) {
      final last = segment.last;
      _appendCell(path, cellFor(last.lat, last.lng, level));
    }

    HeatEdgeKey? previous;
    for (var i = 0; i < path.length - 1; i++) {
      final edge = HeatEdgeKey.normalized(path[i], path[i + 1]);
      // Direkt wiederholte Kante = GPS-Zittern ueber die Zellgrenze.
      if (edge == previous) continue;
      acc.edges[edge] = (acc.edges[edge] ?? 0) + 1;
      previous = edge;
    }
  }

  static void _appendCell(List<HeatCell> path, HeatCell cell) {
    if (path.isNotEmpty && path.last == cell) return;
    path.add(cell);
  }
}
