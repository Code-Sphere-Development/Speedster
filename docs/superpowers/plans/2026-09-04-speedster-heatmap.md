# Strecken-Heatmap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eine Karte, auf der jeder gefahrene Streckenabschnitt umso heller/wärmer rot leuchtet, je häufiger er befahren wurde — als Start-Tab der App, lokal ohne Filter und mit aktiver Cloud zusätzlich mit Zeitraum-Filtern.

**Architecture:** GPS-Punkte werden auf ein metrisches Raster quantisiert; gezählt werden nicht Zellen, sondern Zellübergänge (Kanten). Die Rasterfunktion existiert zweimal bit-identisch — in Dart und in PHP — damit lokale und Cloud-Heatmap dasselbe Bild ergeben. Aggregate werden inkrementell pro Fahrt gefaltet und in drei Zoomstufen (25/100/400 m) vorgehalten, damit der Start-Screen nie rechnen muss.

**Tech Stack:** Flutter 3.47 / Dart 3.13, Drift (SQLite), flutter_map 8.3.2 + OSM-Tiles, Riverpod 3.4, Laravel 12 + Pest, MySQL/SQLite.

**Spec:** `docs/superpowers/specs/2026-09-04-speedster-heatmap-design.md`

> **Nachtrag 2026-09-08:** Die Paketkennung wurde nachträglich von
> `de.mediacologne` auf `de.codesphere` geändert — mediacologne hat mit
> Speedster nichts zu tun, die Kennung stammte aus dem `flutter create
> --org` beim Anlegen des Projekts. Die Stellen unten sind entsprechend
> angepasst; zum Zeitpunkt der Ausführung stand dort `de.mediacologne`.

## Global Constraints

- **Commits nur auf ausdrückliche Ansage des Nutzers.** Die Commit-Schritte in diesem Plan bedeuten: Änderungen mit `git diff` zeigen und auf Freigabe warten. (Projektregel aus `CLAUDE.md`.)
- **Rasterkonstanten exakt, in Dart und PHP identisch:** `cellMeters = [25.0, 100.0, 400.0]`, `metersPerDegLat = 111320.0`, `maxAccuracyMeters = 50.0`, `maxGapMeters = 200.0`, `maxGapSeconds = 30`, `resampleMeters = 10.0`, `cosClamp = 0.01`.
- **Spaltennamen `cell_row` / `cell_col`, niemals `row` / `col`.** `ROW` ist in MySQL 8 ein reserviertes Wort.
- **Zoom→Level-Abbildung:** Zoom ≥ 14 → Level 0; Zoom 11–13 → Level 1; Zoom ≤ 10 → Level 2.
- **Farbstops:** `t=0.0 → #4A0E0E`, `t=0.35 → #B3261E`, `t=0.7 → #FF7A00`, `t=1.0 → #FFD54A`.
- **Range-Werte auf der Leitung:** `all` | `12m` | `3m`.
- **Alle UI-Texte deutsch**, passend zum Bestand (`'Fahrten'`, `'Keine Routendaten'`).
- **Keine neue Dependency außer** `androidx.car.app:app` (Task 16).
- Nach jeder Task: `flutter analyze` ohne Befunde und `flutter test` grün (bzw. `php artisan test` für Backend-Tasks).

---

## Dateiübersicht

| Datei | Verantwortung |
|---|---|
| `lib/heat/heat_grid.dart` | Reine Rasterung: Zellen, Segmentierung, Nachverdichtung, Kanten. Spiegel von `HeatGrid.php`. Keine I/O. |
| `lib/heat/heat_map.dart` | Domänentypen für die Anzeige: `HeatMap`, `HeatEdgeView`, `HeatBounds`, `HeatRange`, `HeatQuery`. |
| `lib/heat/heat_source.dart` | `abstract HeatSource` — eine Methode, zwei Implementierungen. |
| `lib/heat/heat_folder.dart` | Schreibseite: faltet Fahrten in die Drift-Aggregate, Rebuild. |
| `lib/heat/local_heat_source.dart` | Leseseite lokal: Viewport-Query auf die Aggregate. |
| `lib/heat/cloud_heat_source.dart` | Leseseite Cloud: `GET /heatmap`. |
| `lib/heat/heat_palette.dart` | Farbskala + logarithmische Normierung. |
| `lib/ui/heatmap_screen.dart` | Karte, Legende, Filter-Chips, Debounce auf Kartenbewegung. |
| `lib/app/car_connection.dart` | `CarConnection`-Abstraktion, Platform-Implementierung, Fake. |
| `lib/data/database.dart` | += `HeatCells`, `HeatEdges`, `Trips.heatFoldedAt`, Migration v3. |
| `lib/app/app.dart` | Tab-Reihenfolge, Start-Tab-Logik, Auto-Sprung auf Live. |
| `lib/app/providers.dart` | += Heat- und CarConnection-Provider. |
| `backend/app/Services/HeatGrid.php` | Spiegel von `heat_grid.dart`. |
| `backend/app/Services/HeatAggregator.php` | Faltung/Rücknahme einer Fahrt in die Server-Aggregate. |
| `backend/app/Http/Controllers/Api/HeatmapController.php` | `GET /api/heatmap`. |
| `backend/app/Console/Commands/HeatmapRebuild.php` | `heatmap:rebuild`. |
| `test/fixtures/heat_parity.json` | Gemeinsame Fixtures für Dart **und** PHP — der Paritätsnachweis. |

**Phasen:** A (Tasks 1–7) liefert die lauffähige lokale Heatmap als Start-Tab. B (Tasks 8–14) ergänzt Cloud und Filter. C (Tasks 15–17) ergänzt die Auto-Erkennung. Jede Phase ist für sich lauffähig und testbar.

---

# Phase A — Lokale Heatmap

### Task 1: Rasterquantisierung

Der Kern, auf dem alles andere steht: eine Koordinate → eine Zelle. Muss deterministisch sein, sonst driften Dart und PHP auseinander.

**Files:**
- Create: `lib/heat/heat_grid.dart`
- Test: `test/heat/heat_grid_cell_test.dart`

**Interfaces:**
- Consumes: nichts.
- Produces: `HeatCell(int row, int col)` mit `==`/`hashCode`; `HeatGrid.cellFor(double lat, double lng, int level) → HeatCell`; `HeatGrid.latStep(int level) → double`; Konstanten `HeatGrid.cellMeters` (`List<double>`), `HeatGrid.levelCount` (`int` = 3).

- [x] **Step 1: Test schreiben**

```dart
// test/heat/heat_grid_cell_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/heat/heat_grid.dart';

void main() {
  test('dieselbe Koordinate ergibt dieselbe Zelle', () {
    expect(HeatGrid.cellFor(50.9412, 6.9583, 0),
        HeatGrid.cellFor(50.9412, 6.9583, 0));
  });

  test('15 m Versatz bleibt meist dieselbe Zelle, 80 m nie', () {
    final base = HeatGrid.cellFor(50.9412, 6.9583, 0);
    // 80 m noerdlich: 80 / 111320 Grad
    final far = HeatGrid.cellFor(50.9412 + 80 / 111320.0, 6.9583, 0);
    expect(far, isNot(base));
  });

  test('Zellen sind rund 25 m hoch auf Level 0', () {
    final a = HeatGrid.cellFor(50.0, 6.0, 0);
    final b = HeatGrid.cellFor(50.0 + 25 / 111320.0, 6.0, 0);
    expect((b.row - a.row).abs(), lessThanOrEqualTo(1));
    final c = HeatGrid.cellFor(50.0 + 250 / 111320.0, 6.0, 0);
    expect(c.row - a.row, inInclusiveRange(9, 11));
  });

  test('groebere Level fassen mehr zusammen', () {
    final lat2 = 50.0 + 200 / 111320.0;
    expect(HeatGrid.cellFor(50.0, 6.0, 0), isNot(HeatGrid.cellFor(lat2, 6.0, 0)));
    expect(HeatGrid.cellFor(50.0, 6.0, 2).row,
        HeatGrid.cellFor(lat2, 6.0, 2).row);
  });

  test('Laengengrad-Schritt ist mit cos(lat) skaliert', () {
    // Auf 60 Grad Nord ist ein Laengengrad halb so breit: der Schritt
    // muss doppelt so gross sein, damit die Zelle quadratisch bleibt.
    final atEquator = HeatGrid.cellFor(0.0, 0.001, 0).col;
    final atSixty = HeatGrid.cellFor(60.0, 0.001, 0).col;
    expect(atSixty.abs(), lessThan(atEquator.abs()));
  });

  test('negative Koordinaten funktionieren', () {
    final a = HeatGrid.cellFor(-33.8688, 151.2093, 0);
    final b = HeatGrid.cellFor(-33.8688, 151.2093, 0);
    expect(a, b);
    expect(a.row, isNegative);
  });
}
```

- [x] **Step 2: Test laufen lassen, Fehlschlag prüfen**

Run: `flutter test test/heat/heat_grid_cell_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:speedster/heat/heat_grid.dart'`

- [x] **Step 3: Implementieren**

```dart
// lib/heat/heat_grid.dart
import 'dart:math' as math;

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

/// Reine Rasterlogik. Spiegel von `backend/app/Services/HeatGrid.php` —
/// jede Aenderung hier muss dort nachgezogen werden, sonst weicht die
/// Cloud-Heatmap sichtbar von der lokalen ab.
class HeatGrid {
  const HeatGrid._();

  static const List<double> cellMeters = [25.0, 100.0, 400.0];
  static const int levelCount = 3;
  static const double metersPerDegLat = 111320.0;
  static const double cosClamp = 0.01;

  static double latStep(int level) => cellMeters[level] / metersPerDegLat;

  /// Quantisiert eine Koordinate. [row] haengt nur von [lat] ab und die
  /// Laengengrad-Schrittweite nur von [row] — dadurch ist die Rechnung
  /// nicht selbstbezueglich und in jeder Sprache reproduzierbar.
  static HeatCell cellFor(double lat, double lng, int level) {
    final step = latStep(level);
    final row = (lat / step).floor();
    final rowLat = (row + 0.5) * step;
    final lngStep =
        step / math.max(math.cos(rowLat * math.pi / 180.0), cosClamp);
    final col = (lng / lngStep).floor();
    return HeatCell(row, col);
  }
}
```

- [x] **Step 4: Test laufen lassen, grün prüfen**

Run: `flutter test test/heat/heat_grid_cell_test.dart`
Expected: PASS (6 Tests)

- [x] **Step 5: Änderungen zeigen**

```bash
git add lib/heat/heat_grid.dart test/heat/heat_grid_cell_test.dart
git diff --cached
```
Commit erst nach Freigabe: `git commit -m "feat(heat): add deterministic grid quantisation"`

---

### Task 2: Segmentierung, Nachverdichtung und Kantenextraktion

Hier entsteht das eigentliche Ergebnis: aus einer Punktfolge werden gezählte Kanten. Alle Fallstricke der Spec (Ampel, Tunnel, Tempo 130, GPS-Zittern) werden hier abgefangen.

**Files:**
- Modify: `lib/heat/heat_grid.dart`
- Test: `test/heat/heat_grid_fold_test.dart`

**Interfaces:**
- Consumes: `HeatCell`, `HeatGrid.cellFor` aus Task 1; `StatsEngine.haversineMeters` aus `lib/stats/stats_engine.dart`; `TrackPoint` aus `lib/domain/track_point.dart`.
- Produces:
  - `HeatEdgeKey` mit `HeatEdgeKey.normalized(HeatCell, HeatCell)`, Feldern `a`, `b`, `==`/`hashCode`
  - `CellAccum` mit `double latSum`, `double lngSum`, `int n`, Methode `void add(double lat, double lng)`
  - `LevelFold` mit `Map<HeatCell, CellAccum> cells` und `Map<HeatEdgeKey, int> edges`
  - `TripFold` mit `List<LevelFold> levels` (Länge 3)
  - `HeatGrid.foldTrip(List<TrackPoint> points) → TripFold`

- [x] **Step 1: Test schreiben**

```dart
// test/heat/heat_grid_fold_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/domain/track_point.dart';
import 'package:speedster/heat/heat_grid.dart';

/// Punkte entlang eines Meridians, [spacingMeters] auseinander.
List<TrackPoint> line({
  double startLat = 50.0,
  double lng = 6.0,
  int count = 20,
  double spacingMeters = 12,
  double accuracy = 5,
  DateTime? start,
  int secondsPerPoint = 1,
}) {
  final t0 = start ?? DateTime.utc(2026, 1, 1);
  return [
    for (var i = 0; i < count; i++)
      TrackPoint(
        tripId: 1,
        lat: startLat + (i * spacingMeters) / 111320.0,
        lng: lng,
        speed: 20,
        altitude: 100,
        accuracy: accuracy,
        timestamp: t0.add(Duration(seconds: i * secondsPerPoint)),
      ),
  ];
}

void main() {
  test('eine Fahrt erzeugt jede Kante genau einmal', () {
    final fold = HeatGrid.foldTrip(line());
    expect(fold.levels[0].edges, isNotEmpty);
    expect(fold.levels[0].edges.values, everyElement(1));
  });

  test('Level 0, 1 und 2 werden alle befuellt', () {
    final fold = HeatGrid.foldTrip(line(count: 60));
    for (var l = 0; l < HeatGrid.levelCount; l++) {
      expect(fold.levels[l].edges, isNotEmpty, reason: 'Level $l leer');
    }
    // Groebere Level fassen zusammen: weniger Kanten.
    expect(fold.levels[2].edges.length,
        lessThan(fold.levels[0].edges.length));
  });

  test('15 m Versatz trifft dieselben Kanten wie die Originalfahrt', () {
    final a = HeatGrid.foldTrip(line());
    final b = HeatGrid.foldTrip(line(startLat: 50.0 + 15 / 111320.0));
    final shared =
        a.levels[2].edges.keys.toSet().intersection(b.levels[2].edges.keys.toSet());
    expect(shared, isNotEmpty);
  });

  test('Tempo 130 (36 m Punktabstand) erzeugt eine lueckenlose Kette', () {
    final fold = HeatGrid.foldTrip(line(spacingMeters: 36, count: 10));
    final edges = fold.levels[0].edges.keys.toList();
    // Alle beruehrten Zellen haengen zusammen: die Zeilen bilden eine
    // luueckenlose Folge ohne Sprung groesser als 1.
    final rows = <int>{
      for (final e in edges) ...[e.a.row, e.b.row],
    }.toList()
      ..sort();
    for (var i = 1; i < rows.length; i++) {
      expect(rows[i] - rows[i - 1], 1, reason: 'Luecke bei $rows');
    }
  });

  test('Stillstand erzeugt keine Kante', () {
    final t0 = DateTime.utc(2026, 1, 1);
    final pts = [
      for (var i = 0; i < 30; i++)
        TrackPoint(
          tripId: 1,
          lat: 50.0 + (i.isEven ? 0.0 : 0.0000001),
          lng: 6.0,
          speed: 0,
          altitude: 100,
          accuracy: 5,
          timestamp: t0.add(Duration(seconds: i)),
        ),
    ];
    expect(HeatGrid.foldTrip(pts).levels[0].edges, isEmpty);
  });

  test('GPS-Luecke ueber 200 m wird nicht ueberbrueckt', () {
    final first = line(count: 5);
    final second = line(
      startLat: 51.0, // rund 111 km entfernt
      count: 5,
      start: DateTime.utc(2026, 1, 1, 0, 0, 4),
    );
    final fold = HeatGrid.foldTrip([...first, ...second]);
    // Keine Kante darf die beiden Bereiche verbinden.
    for (final e in fold.levels[0].edges.keys) {
      expect((e.a.row - e.b.row).abs(), lessThanOrEqualTo(1));
    }
  });

  test('Zeitluecke ueber 30 s trennt ebenfalls', () {
    final first = line(count: 5);
    final second = line(
      startLat: 50.0 + (5 * 12) / 111320.0 + 0.0005,
      count: 5,
      start: DateTime.utc(2026, 1, 1, 0, 5),
    );
    final fold = HeatGrid.foldTrip([...first, ...second]);
    final rows = <int>{
      for (final e in fold.levels[0].edges.keys) ...[e.a.row, e.b.row],
    }.toList()
      ..sort();
    expect(rows.last - rows.first, greaterThan(rows.length));
  });

  test('ungenaue Punkte werden verworfen', () {
    final good = line(count: 10);
    final bad = line(count: 10, accuracy: 90, lng: 7.5);
    final fold = HeatGrid.foldTrip([...good, ...bad]);
    for (final c in fold.levels[0].cells.keys) {
      expect(HeatGrid.cellFor(50.0, 7.5, 0).col, isNot(c.col));
    }
  });

  test('Hin- und Rueckweg in einer Fahrt zaehlt zweimal', () {
    final out = line(count: 20);
    final back = <TrackPoint>[
      for (var i = out.length - 1; i >= 0; i--)
        TrackPoint(
          tripId: 1,
          lat: out[i].lat,
          lng: out[i].lng,
          speed: 20,
          altitude: 100,
          accuracy: 5,
          timestamp: out.last.timestamp.add(Duration(seconds: out.length - i)),
        ),
    ];
    final fold = HeatGrid.foldTrip([...out, ...back]);
    // Die Mehrzahl der Kanten wurde zweimal befahren.
    final twice = fold.levels[0].edges.values.where((c) => c == 2).length;
    expect(twice, greaterThan(fold.levels[0].edges.length ~/ 2));
  });

  test('Zellschwerpunkte stammen nur aus real gemessenen Punkten', () {
    final pts = line(count: 5, spacingMeters: 36);
    final fold = HeatGrid.foldTrip(pts);
    final totalN =
        fold.levels[0].cells.values.fold<int>(0, (a, c) => a + c.n);
    expect(totalN, pts.length,
        reason: 'interpolierte Punkte duerfen nicht mitzaehlen');
  });

  test('leere und einpunktige Eingaben sind unauffaellig', () {
    expect(HeatGrid.foldTrip([]).levels[0].edges, isEmpty);
    expect(HeatGrid.foldTrip(line(count: 1)).levels[0].edges, isEmpty);
  });
}
```

- [x] **Step 2: Test laufen lassen, Fehlschlag prüfen**

Run: `flutter test test/heat/heat_grid_fold_test.dart`
Expected: FAIL — `The method 'foldTrip' isn't defined for the type 'HeatGrid'`

- [x] **Step 3: Implementieren** (an `lib/heat/heat_grid.dart` anfügen; `HeatGrid` um die Methoden erweitern)

```dart
// oben ergaenzen:
import 'package:speedster/domain/track_point.dart';
import 'package:speedster/stats/stats_engine.dart';

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

class LevelFold {
  final Map<HeatCell, CellAccum> cells = {};
  final Map<HeatEdgeKey, int> edges = {};
}

class TripFold {
  TripFold() : levels = List.generate(HeatGrid.levelCount, (_) => LevelFold());
  final List<LevelFold> levels;
}
```

Und in `HeatGrid`:

```dart
  static const double maxAccuracyMeters = 50.0;
  static const double maxGapMeters = 200.0;
  static const int maxGapSeconds = 30;
  static const double resampleMeters = 10.0;

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
```

- [x] **Step 4: Test laufen lassen, grün prüfen**

Run: `flutter test test/heat/`
Expected: PASS (alle Tests aus Task 1 und 2)

- [x] **Step 5: Änderungen zeigen**

```bash
git add lib/heat/heat_grid.dart test/heat/heat_grid_fold_test.dart
git diff --cached
```
Commit-Nachricht nach Freigabe: `feat(heat): fold trips into counted grid edges`

---

### Task 3: Drift-Schema v3

**Files:**
- Modify: `lib/data/database.dart`
- Test: `test/data/heat_schema_test.dart`

**Interfaces:**
- Consumes: nichts aus vorherigen Tasks.
- Produces: Drift-Tabellen `HeatCells` (Spalten `level`, `cellRow`, `cellCol`, `latSum`, `lngSum`, `n`) und `HeatEdges` (`level`, `aRow`, `aCol`, `bRow`, `bCol`, `count`); `Trips.heatFoldedAt` (`DateTimeColumn`, nullable); `AppDatabase.schemaVersion == 3`. Generierte Accessoren: `db.heatCells`, `db.heatEdges`.

- [x] **Step 1: Test schreiben**

```dart
// test/data/heat_schema_test.dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/data/database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('Schemaversion ist 3', () async {
    expect(db.schemaVersion, 3);
  });

  test('Heat-Tabellen existieren und nehmen Zeilen auf', () async {
    await db.into(db.heatCells).insert(
          HeatCellsCompanion.insert(
            level: 0,
            cellRow: 10,
            cellCol: 20,
            latSum: const Value(100.0),
            lngSum: const Value(12.0),
            n: const Value(2),
          ),
        );
    await db.into(db.heatEdges).insert(
          HeatEdgesCompanion.insert(
            level: 0,
            aRow: 10,
            aCol: 20,
            bRow: 10,
            bCol: 21,
            count: const Value(3),
          ),
        );

    expect((await db.select(db.heatCells).get()).single.n, 2);
    expect((await db.select(db.heatEdges).get()).single.count, 3);
  });

  test('Trips traegt heatFoldedAt und ist anfangs null', () async {
    final id = await db.into(db.trips).insert(
          TripsCompanion.insert(startTime: DateTime.utc(2026, 1, 1)),
        );
    final row =
        await (db.select(db.trips)..where((t) => t.id.equals(id))).getSingle();
    expect(row.heatFoldedAt, isNull);
  });
}
```

- [x] **Step 2: Test laufen lassen, Fehlschlag prüfen**

Run: `flutter test test/data/heat_schema_test.dart`
Expected: FAIL — `HeatCellsCompanion` ist nicht definiert

- [x] **Step 3: Implementieren**

In `lib/data/database.dart` — `Trips` um eine Spalte erweitern:

```dart
  DateTimeColumn get syncedAt => dateTime().nullable()();
  DateTimeColumn get heatFoldedAt => dateTime().nullable()();
```

Neue Tabellen ergänzen. **`cellRow`/`cellCol` statt `row`/`col`, weil `ROW` in MySQL 8 reserviert ist** — die Namen werden im Backend gespiegelt und sollen dort nicht abweichen:

```dart
/// Schwerpunkt-Summen je Rasterzelle. `n` zaehlt nur real gemessene Punkte.
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

/// Befahrungszaehler je Zellübergang.
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
```

Datenbankklasse:

```dart
@DriftDatabase(tables: [Trips, TrackPoints, HeatCells, HeatEdges])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);
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
```

- [x] **Step 4: Code generieren und Tests laufen lassen**

Run: `dart run build_runner build --delete-conflicting-outputs && flutter test test/data/`
Expected: `database.g.dart` neu generiert, alle Tests PASS

- [x] **Step 5: Änderungen zeigen**

```bash
git add lib/data/database.dart lib/data/database.g.dart test/data/heat_schema_test.dart
git diff --cached --stat
```
Commit-Nachricht nach Freigabe: `feat(data): add heat aggregate tables (schema v3)`

---

### Task 4: HeatFolder — die Schreibseite

**Files:**
- Create: `lib/heat/heat_folder.dart`
- Test: `test/heat/heat_folder_test.dart`

**Interfaces:**
- Consumes: `HeatGrid.foldTrip`, `TripFold`, `LevelFold` (Task 2); `AppDatabase`, `HeatCells`, `HeatEdges` (Task 3).
- Produces: `typedef FoldRunner = Future<TripFold> Function(TripFold Function(List<TrackPoint>), List<TrackPoint>)`; `HeatFolder(AppDatabase db, {FoldRunner runner})` mit `Future<int> foldPending()` (Rückgabe: Anzahl gefalteter Fahrten), `Future<void> rebuild()`, `Future<void> onTripUnkept()`.

**Warum ein injizierbarer Runner:** Die Spec verlangt, dass die Faltung nicht auf dem UI-Thread rechnet. Produktiv ist `runner` deshalb `compute` (eigenes Isolate); Tests reichen einen synchronen Runner herein, weil echte Isolates Widget-Tests langsam und flatterig machen.

- [x] **Step 1: Test schreiben**

```dart
// test/heat/heat_folder_test.dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/data/database.dart';
import 'package:speedster/heat/heat_folder.dart';

void main() {
  late AppDatabase db;
  late HeatFolder folder;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // Synchroner Runner: kein echtes Isolate im Test.
    folder = HeatFolder(db, runner: (fn, msg) async => fn(msg));
  });
  tearDown(() => db.close());

  /// Legt eine Fahrt mit einer geraden Strecke an.
  Future<int> seedTrip({double startLat = 50.0, bool kept = true}) async {
    final id = await db.into(db.trips).insert(
          TripsCompanion.insert(
            startTime: DateTime.utc(2026, 1, 1),
            kept: Value(kept),
          ),
        );
    await db.batch((b) {
      b.insertAll(db.trackPoints, [
        for (var i = 0; i < 20; i++)
          TrackPointsCompanion.insert(
            tripId: id,
            lat: startLat + (i * 12) / 111320.0,
            lng: 6.0,
            speed: 20,
            altitude: 100,
            accuracy: 5,
            timestamp: DateTime.utc(2026, 1, 1).add(Duration(seconds: i)),
          ),
      ]);
    });
    return id;
  }

  Future<int> edgeCount() async =>
      (await db.select(db.heatEdges).get()).length;

  Future<int> maxCount() async {
    final rows = await (db.select(db.heatEdges)
          ..where((e) => e.level.equals(0)))
        .get();
    return rows.map((r) => r.count).fold(0, (a, b) => a > b ? a : b);
  }

  test('faltet offene Fahrten und markiert sie', () async {
    final id = await seedTrip();
    expect(await folder.foldPending(), 1);
    expect(await edgeCount(), greaterThan(0));

    final trip =
        await (db.select(db.trips)..where((t) => t.id.equals(id))).getSingle();
    expect(trip.heatFoldedAt, isNotNull);
  });

  test('faltet dieselbe Fahrt nicht zweimal', () async {
    await seedTrip();
    await folder.foldPending();
    final after = await edgeCount();
    expect(await folder.foldPending(), 0);
    expect(await edgeCount(), after);
    expect(await maxCount(), 1);
  });

  test('zwei Fahrten ueber dieselbe Strecke ergeben count 2', () async {
    await seedTrip();
    await seedTrip();
    await folder.foldPending();
    expect(await maxCount(), 2);
  });

  test('verworfene Fahrten werden nicht gefaltet', () async {
    await seedTrip(kept: false);
    expect(await folder.foldPending(), 0);
    expect(await edgeCount(), 0);
  });

  test('rebuild baut die Aggregate aus allen behaltenen Fahrten neu', () async {
    await seedTrip();
    await seedTrip();
    await folder.foldPending();
    final before = await maxCount();

    await folder.rebuild();
    expect(await maxCount(), before);
  });

  test('nach setKept(false) verschwindet der Beitrag der Fahrt', () async {
    final keep = await seedTrip();
    final drop = await seedTrip();
    await folder.foldPending();
    expect(await maxCount(), 2);

    await (db.update(db.trips)..where((t) => t.id.equals(drop)))
        .write(const TripsCompanion(kept: Value(false)));
    await folder.onTripUnkept();

    expect(await maxCount(), 1);
    expect(await edgeCount(), greaterThan(0));
    final kept =
        await (db.select(db.trips)..where((t) => t.id.equals(keep))).getSingle();
    expect(kept.heatFoldedAt, isNotNull);
  });

  test('Zellschwerpunkte werden mitgeschrieben', () async {
    await seedTrip();
    await folder.foldPending();
    final cell = (await (db.select(db.heatCells)
              ..where((c) => c.level.equals(0)))
            .get())
        .first;
    expect(cell.n, greaterThan(0));
    expect(cell.latSum / cell.n, closeTo(50.0, 0.01));
  });
}
```

- [x] **Step 2: Test laufen lassen, Fehlschlag prüfen**

Run: `flutter test test/heat/heat_folder_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:speedster/heat/heat_folder.dart'`

- [x] **Step 3: Implementieren**

```dart
// lib/heat/heat_folder.dart
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:speedster/data/database.dart';
import 'package:speedster/domain/track_point.dart' as domain;
import 'package:speedster/heat/heat_grid.dart';

/// Schreibseite der Heatmap: faltet Fahrten in die Aggregattabellen.
///
/// Die Heatmap ist der Start-Screen und darf beim Oeffnen nicht rechnen,
/// deshalb wird inkrementell pro Fahrt gefaltet statt bei jedem Aufruf
/// ueber die gesamte Punkthistorie zu aggregieren.
/// Fuehrt die reine Faltung aus — produktiv in einem eigenen Isolate.
typedef FoldRunner = Future<TripFold> Function(
  TripFold Function(List<domain.TrackPoint>),
  List<domain.TrackPoint>,
);

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
  /// Wird bei Ruecknahmen benutzt: einzelne Fahrten exakt herauszurechnen
  /// waere fehleranfaelliger als ein Neuaufbau, und Ruecknahmen sind selten.
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

  /// Nach `setKept(false)` auf eine bereits gefaltete Fahrt.
  Future<void> onTripUnkept() => rebuild();

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
```

- [x] **Step 4: Test laufen lassen, grün prüfen**

Run: `flutter test test/heat/heat_folder_test.dart`
Expected: PASS (7 Tests)

- [x] **Step 5: Rücknahme verdrahten — Test schreiben**

`onTripUnkept()` nützt nichts, solange niemand es ruft. Es gibt genau zwei
Stellen, an denen Fahrten verschwinden: der Beifahrer-Dialog
(`lib/ui/driver_prompt.dart:14`) und „Alle Daten löschen"
(`lib/ui/settings_screen.dart:35`).

**`deleteAll()` ist dabei ein Datenschutz-Fehler in Wartestellung:** es
löscht heute `trackPoints` und `trips`, aber die Heat-Aggregate blieben
stehen — nach „alle Daten löschen" leuchtete die Heatmap weiter. Der Test
hält das fest:

```dart
// test/data/trip_repository_test.dart — ergaenzen
  test('deleteAll raeumt auch die Heatmap-Aggregate', () async {
    final id = await repo.createTrip(
      Trip(startTime: DateTime.utc(2026, 1, 1), kept: true),
    );
    await repo.addPoints(id, [
      for (var i = 0; i < 20; i++)
        TrackPoint(
          tripId: id,
          lat: 50.0 + (i * 12) / 111320.0,
          lng: 6.0,
          speed: 20,
          altitude: 100,
          accuracy: 5,
          timestamp: DateTime.utc(2026, 1, 1).add(Duration(seconds: i)),
        ),
    ]);
    await HeatFolder(db, runner: (fn, msg) async => fn(msg)).foldPending();
    expect(await db.select(db.heatEdges).get(), isNotEmpty);

    await repo.deleteAll();

    expect(await db.select(db.heatEdges).get(), isEmpty);
    expect(await db.select(db.heatCells).get(), isEmpty);
  });
```

Run: `flutter test test/data/trip_repository_test.dart`
Expected: FAIL — `heat_edges` ist nach `deleteAll()` noch gefüllt

- [x] **Step 6: Rücknahme implementieren**

`lib/data/trip_repository.dart` — `deleteAll()` erweitern:

```dart
  @override
  Future<void> deleteAll() async {
    await db.delete(db.trackPoints).go();
    await db.delete(db.trips).go();
    // Sonst ueberlebt die Heatmap ein "alle Daten loeschen".
    await db.delete(db.heatEdges).go();
    await db.delete(db.heatCells).go();
  }
```

`lib/ui/driver_prompt.dart` — in `_resolve` nach `setKept`:

```dart
    await ref.read(tripRepositoryProvider).setKept(tripId, kept);
    if (!kept) {
      // Verworfene Fahrt aus den Aggregaten nehmen. Nur noetig, wenn sie
      // bereits gefaltet war — onTripUnkept prueft das nicht, der Rebuild
      // ist aber idempotent und dieser Fall ist selten.
      await ref.read(heatFolderProvider).onTripUnkept();
    }
    ref.invalidate(keptTripsProvider);
```

Der `heatFolderProvider` entsteht in Task 6; bis dahin hier direkt
`HeatFolder(ref.read(databaseProvider))` benutzen und in Task 6 auf den
Provider umstellen.

- [x] **Step 7: Tests laufen lassen, grün prüfen**

Run: `flutter test test/data/ test/heat/ test/ui/driver_prompt_test.dart`
Expected: PASS

- [x] **Step 8: Änderungen zeigen**

```bash
git add lib/heat/heat_folder.dart lib/data/trip_repository.dart lib/ui/driver_prompt.dart test/heat/heat_folder_test.dart test/data/trip_repository_test.dart
git diff --cached
```
Commit-Nachricht nach Freigabe: `feat(heat): incrementally fold trips into aggregates`

---

### Task 5: Domänentypen, HeatSource und LocalHeatSource

**Files:**
- Create: `lib/heat/heat_map.dart`, `lib/heat/heat_source.dart`, `lib/heat/local_heat_source.dart`
- Test: `test/heat/local_heat_source_test.dart`

**Interfaces:**
- Consumes: `AppDatabase` (Task 3), `HeatFolder` (Task 4).
- Produces:
  - `HeatBounds(double minLat, double minLng, double maxLat, double maxLng)`
  - `enum HeatRange { all, months12, months3 }` mit `String get wire` (`'all'`, `'12m'`, `'3m'`)
  - `HeatQuery({required int level, HeatBounds? bounds, HeatRange range = HeatRange.all})`
  - `HeatEdgeView({required double aLat, aLng, bLat, bLng, required int count})`
  - `HeatMap({required List<HeatEdgeView> edges, required int maxCount})`, `HeatMap.empty`
  - `HeatGridZoom.levelForZoom(double zoom) → int`
  - `abstract class HeatSource { Future<HeatMap> load(HeatQuery query); }`
  - `LocalHeatSource(AppDatabase db, HeatFolder folder)` implementiert `HeatSource`

- [x] **Step 1: Test schreiben**

```dart
// test/heat/local_heat_source_test.dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/data/database.dart';
import 'package:speedster/heat/heat_folder.dart';
import 'package:speedster/heat/heat_map.dart';
import 'package:speedster/heat/local_heat_source.dart';

void main() {
  late AppDatabase db;
  late LocalHeatSource source;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    source = LocalHeatSource(
      db,
      HeatFolder(db, runner: (fn, msg) async => fn(msg)),
    );
  });
  tearDown(() => db.close());

  Future<void> seedTrip({double startLat = 50.0}) async {
    final id = await db.into(db.trips).insert(
          TripsCompanion.insert(startTime: DateTime.utc(2026, 1, 1)),
        );
    await db.batch((b) {
      b.insertAll(db.trackPoints, [
        for (var i = 0; i < 20; i++)
          TrackPointsCompanion.insert(
            tripId: id,
            lat: startLat + (i * 12) / 111320.0,
            lng: 6.0,
            speed: 20,
            altitude: 100,
            accuracy: 5,
            timestamp: DateTime.utc(2026, 1, 1).add(Duration(seconds: i)),
          ),
      ]);
    });
  }

  test('leere Datenbank liefert eine leere Heatmap', () async {
    final map = await source.load(const HeatQuery(level: 0));
    expect(map.edges, isEmpty);
    expect(map.maxCount, 0);
  });

  test('faltet beim Laden nach und liefert Kanten mit Koordinaten', () async {
    await seedTrip();
    final map = await source.load(const HeatQuery(level: 0));

    expect(map.edges, isNotEmpty);
    expect(map.maxCount, 1);
    final edge = map.edges.first;
    expect(edge.aLat, closeTo(50.0, 0.01));
    expect(edge.aLng, closeTo(6.0, 0.01));
    expect(edge.count, 1);
  });

  test('zwei gleiche Fahrten heben maxCount auf 2', () async {
    await seedTrip();
    await seedTrip();
    final map = await source.load(const HeatQuery(level: 0));
    expect(map.maxCount, 2);
  });

  test('Viewport-Filter grenzt die Kanten ein, maxCount bleibt global',
      () async {
    await seedTrip();
    await seedTrip(startLat: 51.0);

    final all = await source.load(const HeatQuery(level: 0));
    final windowed = await source.load(
      const HeatQuery(
        level: 0,
        bounds: HeatBounds(49.9, 5.9, 50.1, 6.1),
      ),
    );

    expect(windowed.edges.length, lessThan(all.edges.length));
    expect(windowed.edges, isNotEmpty);
    expect(windowed.maxCount, all.maxCount);
  });

  test('Zeitfilter wird lokal ignoriert', () async {
    await seedTrip();
    final all = await source.load(const HeatQuery(level: 0));
    final filtered = await source
        .load(const HeatQuery(level: 0, range: HeatRange.months3));
    expect(filtered.edges.length, all.edges.length);
  });

  test('groebere Level liefern weniger Kanten', () async {
    await seedTrip();
    final fine = await source.load(const HeatQuery(level: 0));
    final coarse = await source.load(const HeatQuery(level: 2));
    expect(coarse.edges.length, lessThan(fine.edges.length));
  });

  test('Zoom wird auf das richtige Level abgebildet', () {
    expect(HeatGridZoom.levelForZoom(16), 0);
    expect(HeatGridZoom.levelForZoom(14), 0);
    expect(HeatGridZoom.levelForZoom(12), 1);
    expect(HeatGridZoom.levelForZoom(10), 2);
    expect(HeatGridZoom.levelForZoom(3), 2);
  });
}
```

- [x] **Step 2: Test laufen lassen, Fehlschlag prüfen**

Run: `flutter test test/heat/local_heat_source_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:speedster/heat/heat_map.dart'`

- [x] **Step 3: Implementieren**

```dart
// lib/heat/heat_map.dart

/// Rechteckiger Kartenausschnitt.
class HeatBounds {
  const HeatBounds(this.minLat, this.minLng, this.maxLat, this.maxLng);

  final double minLat;
  final double minLng;
  final double maxLat;
  final double maxLng;
}

/// Zeitraum. Nur die Cloud kann filtern — lokal liegen keine Monatsbuckets vor.
enum HeatRange {
  all('all'),
  months12('12m'),
  months3('3m');

  const HeatRange(this.wire);
  final String wire;
}

class HeatQuery {
  const HeatQuery({
    required this.level,
    this.bounds,
    this.range = HeatRange.all,
  });

  final int level;
  final HeatBounds? bounds;
  final HeatRange range;
}

/// Eine zeichenbare Kante: zwei Zellschwerpunkte plus Befahrungszahl.
class HeatEdgeView {
  const HeatEdgeView({
    required this.aLat,
    required this.aLng,
    required this.bLat,
    required this.bLng,
    required this.count,
  });

  final double aLat;
  final double aLng;
  final double bLat;
  final double bLng;
  final int count;
}

class HeatMap {
  const HeatMap({required this.edges, required this.maxCount});

  /// [maxCount] ist das Maximum ueber den gesamten Zeitraum und Level, nicht
  /// nur ueber den Viewport — sonst wuerden sich die Farben beim Verschieben
  /// der Karte aendern.
  final List<HeatEdgeView> edges;
  final int maxCount;

  static const empty = HeatMap(edges: [], maxCount: 0);
}

/// Zoomstufe → Rasterebene.
class HeatGridZoom {
  const HeatGridZoom._();

  static int levelForZoom(double zoom) {
    if (zoom >= 14) return 0;
    if (zoom >= 11) return 1;
    return 2;
  }
}
```

```dart
// lib/heat/heat_source.dart
import 'package:speedster/heat/heat_map.dart';

/// Woher die Heatmap kommt. Lokal ignoriert den Zeitfilter, die Cloud
/// wertet ihn aus.
abstract class HeatSource {
  Future<HeatMap> load(HeatQuery query);
}
```

```dart
// lib/heat/local_heat_source.dart
import 'package:drift/drift.dart';
import 'package:speedster/data/database.dart';
import 'package:speedster/heat/heat_folder.dart';
import 'package:speedster/heat/heat_map.dart';
import 'package:speedster/heat/heat_source.dart';

/// Leseseite lokal. Faltet vor dem Lesen offene Fahrten nach, damit auch
/// nach einer Migration oder einer verpassten Faltung nichts fehlt.
class LocalHeatSource implements HeatSource {
  LocalHeatSource(this.db, this.folder);

  final AppDatabase db;
  final HeatFolder folder;

  @override
  Future<HeatMap> load(HeatQuery query) async {
    await folder.foldPending();

    final cells = <int, Map<int, ({double lat, double lng})>>{};
    for (final c in await (db.select(db.heatCells)
          ..where((c) => c.level.equals(query.level)))
        .get()) {
      if (c.n == 0) continue;
      cells.putIfAbsent(c.cellRow, () => {})[c.cellCol] =
          (lat: c.latSum / c.n, lng: c.lngSum / c.n);
    }

    final rows = await (db.select(db.heatEdges)
          ..where((e) => e.level.equals(query.level)))
        .get();

    var maxCount = 0;
    final edges = <HeatEdgeView>[];
    for (final e in rows) {
      if (e.count > maxCount) maxCount = e.count;

      final a = cells[e.aRow]?[e.aCol];
      final b = cells[e.bRow]?[e.bCol];
      if (a == null || b == null) continue;
      if (!_inBounds(query.bounds, a.lat, a.lng) &&
          !_inBounds(query.bounds, b.lat, b.lng)) {
        continue;
      }

      edges.add(
        HeatEdgeView(
          aLat: a.lat,
          aLng: a.lng,
          bLat: b.lat,
          bLng: b.lng,
          count: e.count,
        ),
      );
    }

    return HeatMap(edges: edges, maxCount: maxCount);
  }

  bool _inBounds(HeatBounds? b, double lat, double lng) {
    if (b == null) return true;
    return lat >= b.minLat &&
        lat <= b.maxLat &&
        lng >= b.minLng &&
        lng <= b.maxLng;
  }
}
```

- [x] **Step 4: Test laufen lassen, grün prüfen**

Run: `flutter test test/heat/`
Expected: PASS (alle Heat-Tests)

- [x] **Step 5: Änderungen zeigen**

```bash
git add lib/heat/ test/heat/local_heat_source_test.dart
git diff --cached
```
Commit-Nachricht nach Freigabe: `feat(heat): add heat domain types and local source`

---

### Task 6: Farbskala und Heatmap-Screen

**Files:**
- Create: `lib/heat/heat_palette.dart`, `lib/ui/heatmap_screen.dart`
- Modify: `lib/app/providers.dart`
- Test: `test/heat/heat_palette_test.dart`, `test/ui/heatmap_screen_test.dart`

**Interfaces:**
- Consumes: `HeatMap`, `HeatQuery`, `HeatEdgeView`, `HeatGridZoom`, `HeatSource` (Task 5); `LocalHeatSource`, `HeatFolder` (Tasks 4–5); `databaseProvider` (bestehend).
- Produces: `HeatPalette.colorFor(int count, int maxCount) → Color`; `heatFolderProvider`, `heatSourceProvider` (`Provider<HeatSource>`), `heatMapProvider` (`FutureProvider.family<HeatMap, HeatQuery>`); Widget `HeatmapScreen`.

- [x] **Step 1: Tests schreiben**

```dart
// test/heat/heat_palette_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/heat/heat_palette.dart';

void main() {
  test('einmal befahren ist der dunkelste Ton', () {
    expect(HeatPalette.colorFor(1, 200), const Color(0xFF4A0E0E));
  });

  test('das Maximum ist der hellste Ton', () {
    expect(HeatPalette.colorFor(200, 200), const Color(0xFFFFD54A));
  });

  test('logarithmisch: die Mitte liegt weit unter dem halben Maximum', () {
    // Bei linearer Normierung waere count=14 bei max=200 fast schwarz.
    // Logarithmisch liegt es schon im mittleren Bereich.
    final mid = HeatPalette.colorFor(14, 200);
    expect(mid.r, greaterThan(const Color(0xFF4A0E0E).r));
  });

  test('haeufiger heisst nie dunkler', () {
    var previous = 0.0;
    for (final c in [1, 2, 5, 10, 50, 200]) {
      final lum = HeatPalette.colorFor(c, 200).computeLuminance();
      expect(lum, greaterThanOrEqualTo(previous - 0.001));
      previous = lum;
    }
  });

  test('Randfaelle stuerzen nicht ab', () {
    expect(HeatPalette.colorFor(1, 1), const Color(0xFFFFD54A));
    expect(HeatPalette.colorFor(0, 0), const Color(0xFF4A0E0E));
    expect(HeatPalette.colorFor(5, 2), const Color(0xFFFFD54A));
  });
}
```

```dart
// test/ui/heatmap_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/heat/heat_map.dart';
import 'package:speedster/heat/heat_source.dart';
import 'package:speedster/ui/heatmap_screen.dart';

class FakeHeatSource implements HeatSource {
  FakeHeatSource(this.map);
  final HeatMap map;
  HeatQuery? lastQuery;

  @override
  Future<HeatMap> load(HeatQuery query) async {
    lastQuery = query;
    return map;
  }
}

Widget wrap(HeatSource source) => ProviderScope(
      overrides: [heatSourceProvider.overrideWithValue(source)],
      child: const MaterialApp(home: HeatmapScreen()),
    );

void main() {
  testWidgets('zeigt einen Hinweis, wenn nichts aufgezeichnet wurde',
      (tester) async {
    await tester.pumpWidget(wrap(FakeHeatSource(HeatMap.empty)));
    await tester.pumpAndSettle();
    expect(find.text('Noch keine Strecken aufgezeichnet'), findsOneWidget);
  });

  testWidgets('zeigt Karte und Legende, wenn Kanten vorliegen',
      (tester) async {
    final source = FakeHeatSource(
      const HeatMap(
        edges: [
          HeatEdgeView(
            aLat: 50.0,
            aLng: 6.0,
            bLat: 50.001,
            bLng: 6.001,
            count: 3,
          ),
        ],
        maxCount: 3,
      ),
    );
    await tester.pumpWidget(wrap(source));
    await tester.pumpAndSettle();

    expect(find.text('Noch keine Strecken aufgezeichnet'), findsNothing);
    expect(find.text('selten'), findsOneWidget);
    expect(find.text('oft'), findsOneWidget);
  });
}
```

- [x] **Step 2: Tests laufen lassen, Fehlschlag prüfen**

Run: `flutter test test/heat/heat_palette_test.dart test/ui/heatmap_screen_test.dart`
Expected: FAIL — `heat_palette.dart` und `heatmap_screen.dart` existieren nicht

- [x] **Step 3: Implementieren**

```dart
// lib/heat/heat_palette.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Farbskala der Heatmap: dunkelrot (selten) nach hellgelb (oft).
class HeatPalette {
  const HeatPalette._();

  static const List<(double, Color)> stops = [
    (0.0, Color(0xFF4A0E0E)),
    (0.35, Color(0xFFB3261E)),
    (0.7, Color(0xFFFF7A00)),
    (1.0, Color(0xFFFFD54A)),
  ];

  /// Logarithmisch normiert. Befahrungszahlen sind stark schief verteilt —
  /// der Arbeitsweg hat dreistellige Werte, der Ausflug eine 1. Linear
  /// normiert waere alles ausser dem Arbeitsweg unlesbar dunkel.
  static Color colorFor(int count, int maxCount) {
    if (count <= 1 && maxCount <= 1 && count > 0) return stops.last.$2;
    if (count <= 0) return stops.first.$2;
    if (maxCount <= 1) return stops.last.$2;

    final t = (math.log(count) / math.log(maxCount)).clamp(0.0, 1.0);
    return _lerp(t);
  }

  static Color _lerp(double t) {
    for (var i = 0; i < stops.length - 1; i++) {
      final (fromT, fromC) = stops[i];
      final (toT, toC) = stops[i + 1];
      if (t <= toT) {
        final span = toT - fromT;
        final local = span == 0 ? 0.0 : (t - fromT) / span;
        return Color.lerp(fromC, toC, local)!;
      }
    }
    return stops.last.$2;
  }
}
```

```dart
// lib/ui/heatmap_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/heat/heat_map.dart';
import 'package:speedster/heat/heat_palette.dart';

/// Karte aller gefahrenen Strecken, eingefaerbt nach Befahrungshaeufigkeit.
class HeatmapScreen extends ConsumerStatefulWidget {
  const HeatmapScreen({super.key});

  @override
  ConsumerState<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends ConsumerState<HeatmapScreen> {
  static const _initialZoom = 12.0;

  HeatQuery _query = const HeatQuery(level: 1);
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /// Ohne Entprellung loeste jeder Pan-Frame eine neue Abfrage aus.
  void _onMapEvent(MapCamera camera) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final b = camera.visibleBounds;
      setState(() {
        _query = HeatQuery(
          level: HeatGridZoom.levelForZoom(camera.zoom),
          bounds: HeatBounds(
            b.south,
            b.west,
            b.north,
            b.east,
          ),
          range: _query.range,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(heatMapProvider(_query));

    return Scaffold(
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('Heatmap nicht verfügbar: $e')),
        data: (map) {
          if (map.edges.isEmpty) {
            return const Center(
              child: Text('Noch keine Strecken aufgezeichnet'),
            );
          }
          return Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(map.edges.first.aLat, map.edges.first.aLng),
                  initialZoom: _initialZoom,
                  onMapEvent: (e) => _onMapEvent(e.camera),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'de.codesphere.speedster',
                  ),
                  PolylineLayer(
                    polylines: [
                      for (final e in map.edges)
                        Polyline(
                          points: [
                            LatLng(e.aLat, e.aLng),
                            LatLng(e.bLat, e.bLng),
                          ],
                          strokeWidth: 4,
                          color: HeatPalette.colorFor(e.count, map.maxCount),
                        ),
                    ],
                  ),
                ],
              ),
              const Positioned(left: 12, bottom: 12, child: _Legend()),
            ],
          );
        },
      ),
    );
  }
}

/// Ohne Legende ist die Farbskala nicht interpretierbar.
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('selten'),
          const SizedBox(width: 8),
          Container(
            width: 80,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(
                colors: [for (final s in HeatPalette.stops) s.$2],
                stops: [for (final s in HeatPalette.stops) s.$1],
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text('oft'),
        ],
      ),
    );
  }
}
```

In `lib/app/providers.dart` ergänzen (Imports `heat_folder.dart`, `heat_map.dart`, `heat_source.dart`, `local_heat_source.dart`):

```dart
final heatFolderProvider = Provider<HeatFolder>(
  (ref) => HeatFolder(ref.watch(databaseProvider)),
);

/// Wird in Task 13 um die Cloud-Quelle erweitert.
final heatSourceProvider = Provider<HeatSource>(
  (ref) => LocalHeatSource(
    ref.watch(databaseProvider),
    ref.watch(heatFolderProvider),
  ),
);

final heatMapProvider = FutureProvider.family<HeatMap, HeatQuery>(
  (ref, query) => ref.watch(heatSourceProvider).load(query),
);
```

`HeatQuery` braucht Wertsemantik, damit `family` nicht bei jedem Rebuild neu lädt. In `lib/heat/heat_map.dart` an `HeatQuery` und `HeatBounds` ergänzen:

```dart
  // in HeatBounds
  @override
  bool operator ==(Object other) =>
      other is HeatBounds &&
      other.minLat == minLat &&
      other.minLng == minLng &&
      other.maxLat == maxLat &&
      other.maxLng == maxLng;

  @override
  int get hashCode => Object.hash(minLat, minLng, maxLat, maxLng);

  // in HeatQuery
  @override
  bool operator ==(Object other) =>
      other is HeatQuery &&
      other.level == level &&
      other.bounds == bounds &&
      other.range == range;

  @override
  int get hashCode => Object.hash(level, bounds, range);
```

- [x] **Step 4: Tests laufen lassen, grün prüfen**

Run: `flutter test test/heat/ test/ui/heatmap_screen_test.dart`
Expected: PASS

- [x] **Step 5: Änderungen zeigen**

```bash
git add lib/heat/heat_palette.dart lib/ui/heatmap_screen.dart lib/heat/heat_map.dart lib/app/providers.dart test/heat/heat_palette_test.dart test/ui/heatmap_screen_test.dart
git diff --cached
```
Commit-Nachricht nach Freigabe: `feat(ui): add heatmap screen with logarithmic colour scale`

---

### Task 7: Tab-Umbau und Start-Tab-Logik

**Files:**
- Modify: `lib/app/app.dart`
- Test: `test/app/start_tab_test.dart`, Anpassung `test/app/app_smoke_test.dart`

**Interfaces:**
- Consumes: `HeatmapScreen` (Task 6), `recorderStateProvider` (bestehend).
- Produces: `HomeShell` mit fünf Tabs in der Reihenfolge Heatmap, Live, Fahrten, Ranking, Einstellungen; Konstanten `HomeShell.heatmapTab = 0`, `HomeShell.liveTab = 1`.

- [x] **Step 1: Tests schreiben**

```dart
// test/app/start_tab_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/app/app.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/heat/heat_map.dart';
import 'package:speedster/heat/heat_source.dart';
import 'package:speedster/recording/trip_recorder.dart';

class _FakeHeatSource implements HeatSource {
  @override
  Future<HeatMap> load(HeatQuery query) async => HeatMap.empty;
}

Widget wrap(Stream<RecorderState> states) => ProviderScope(
      overrides: [
        heatSourceProvider.overrideWithValue(_FakeHeatSource()),
        recorderStateProvider.overrideWith((ref) => states),
      ],
      child: const MaterialApp(home: HomeShell()),
    );

void main() {
  testWidgets('startet auf der Heatmap, wenn nicht gefahren wird',
      (tester) async {
    await tester.pumpWidget(wrap(Stream.value(const RecorderState())));
    await tester.pumpAndSettle();

    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, HomeShell.heatmapTab);
    expect(find.text('Heatmap'), findsWidgets);
  });

  testWidgets('startet auf Live, wenn bereits gefahren wird', (tester) async {
    await tester.pumpWidget(
      wrap(Stream.value(const RecorderState(isDriving: true))),
    );
    await tester.pumpAndSettle();

    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, HomeShell.liveTab);
  });

  testWidgets('springt bei Fahrtbeginn einmalig auf Live, aber nicht zurueck',
      (tester) async {
    final controller = StreamController<RecorderState>();
    addTearDown(controller.close);

    await tester.pumpWidget(wrap(controller.stream));
    controller.add(const RecorderState());
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      HomeShell.heatmapTab,
    );

    controller.add(const RecorderState(isDriving: true));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      HomeShell.liveTab,
    );

    // Fahrtende darf die Ansicht nicht zurueckreissen.
    controller.add(const RecorderState());
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      HomeShell.liveTab,
    );
  });
}
```

Der Test braucht `import 'dart:async';` für `StreamController`.

- [x] **Step 2: Tests laufen lassen, Fehlschlag prüfen**

Run: `flutter test test/app/start_tab_test.dart`
Expected: FAIL — `HomeShell.heatmapTab` ist nicht definiert

- [x] **Step 3: Implementieren**

In `lib/app/app.dart` — Import `heatmap_screen.dart` ergänzen und `_HomeShellState` umbauen:

```dart
class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = HomeShell.heatmapTab;
  bool _switchedForCurrentDrive = false;

  static const _tabs = [
    HeatmapScreen(),
    LiveScreen(),
    TripListScreen(),
    RankingScreen(),
    SettingsScreen(),
  ];
  static const _titles = [
    'Heatmap',
    'Live',
    'Fahrten',
    'Ranking',
    'Einstellungen',
  ];
```

`HomeShell` selbst bekommt die Konstanten:

```dart
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  static const int heatmapTab = 0;
  static const int liveTab = 1;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}
```

In `build` den bestehenden `ref.listen(recorderStateProvider, ...)` erweitern:

```dart
    ref.listen(recorderStateProvider, (prev, next) {
      final state = next.asData?.value;

      // Fahrtbeginn: einmalig auf Live wechseln. Kein Ruecksprung bei
      // Fahrtende — dem Nutzer die Ansicht unter dem Finger wegzuziehen
      // waere stoerend.
      final driving = state?.isDriving ?? false;
      if (driving && !_switchedForCurrentDrive) {
        _switchedForCurrentDrive = true;
        setState(() => _index = HomeShell.liveTab);
      } else if (!driving) {
        _switchedForCurrentDrive = false;
      }

      final id = state?.awaitingConfirmationTripId;
      if (id != null) {
        ref.invalidate(keptTripsProvider);
        showDialog<void>(
          context: context,
          builder: (_) => DriverPrompt(tripId: id),
        );
      }
    });
```

Und die Navigationsziele:

```dart
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.local_fire_department),
            label: 'Heatmap',
          ),
          NavigationDestination(icon: Icon(Icons.speed), label: 'Live'),
          NavigationDestination(icon: Icon(Icons.list), label: 'Fahrten'),
          NavigationDestination(
            icon: Icon(Icons.leaderboard),
            label: 'Ranking',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Einstellungen',
          ),
        ],
```

- [x] **Step 4: Bestehenden Smoke-Test anpassen und alles laufen lassen**

`test/app/app_smoke_test.dart` erwartet drei Tabs („renders the three-tab shell") — auf fünf Tabs aktualisieren und `heatSourceProvider` überschreiben, sonst greift der Test auf die echte Datenbank zu.

Run: `flutter test && flutter analyze`
Expected: alle Tests PASS, keine Analyse-Befunde

- [x] **Step 5: Änderungen zeigen**

```bash
git add lib/app/app.dart test/app/
git diff --cached
```
Commit-Nachricht nach Freigabe: `feat(app): make heatmap the start tab, live while driving`

**Phase A ist hier lauffähig:** die App startet mit einer lokalen Heatmap, wechselt bei Fahrtbeginn auf Live. Vor Phase B einmal auf einem Gerät prüfen (`flutter run`).

---

# Phase B — Cloud und Filter

### Task 8: HeatGrid in PHP mit Paritätsnachweis

Die Fixtures sind der eigentliche Wert dieser Task: sie belegen, dass Dart und PHP dasselbe rechnen.

**Files:**
- Create: `backend/app/Services/HeatGrid.php`, `test/fixtures/heat_parity.json`, `backend/tests/Unit/HeatGridParityTest.php`, `test/heat/heat_grid_parity_test.dart`

**Interfaces:**
- Consumes: Konstanten und Algorithmus aus Task 1–2.
- Produces: `HeatGrid::cellFor(float $lat, float $lng, int $level): array{0:int,1:int}`; `HeatGrid::foldTrip(array $points): array` mit Struktur `[level => ['cells' => [ "row:col" => ['lat_sum'=>float,'lng_sum'=>float,'n'=>int] ], 'edges' => [ "aRow:aCol:bRow:bCol" => int ]]]`. `$points` sind Arrays mit `lat`, `lng`, `accuracy`, `t` (ISO-8601).

- [x] **Step 1: Fixture-Datei erzeugen**

`test/fixtures/heat_parity.json` — von Hand angelegt, beide Seiten lesen sie:

```json
{
  "cases": [
    {
      "name": "gerade_strecke_12m",
      "points": [
        {"lat": 50.0,          "lng": 6.0, "accuracy": 5, "t": "2026-01-01T00:00:00Z"},
        {"lat": 50.000107798,  "lng": 6.0, "accuracy": 5, "t": "2026-01-01T00:00:01Z"},
        {"lat": 50.000215596,  "lng": 6.0, "accuracy": 5, "t": "2026-01-01T00:00:02Z"},
        {"lat": 50.000323394,  "lng": 6.0, "accuracy": 5, "t": "2026-01-01T00:00:03Z"},
        {"lat": 50.000431192,  "lng": 6.0, "accuracy": 5, "t": "2026-01-01T00:00:04Z"}
      ]
    },
    {
      "name": "tempo_130_36m",
      "points": [
        {"lat": 50.0,         "lng": 6.0, "accuracy": 5, "t": "2026-01-01T00:00:00Z"},
        {"lat": 50.000323394, "lng": 6.0, "accuracy": 5, "t": "2026-01-01T00:00:01Z"},
        {"lat": 50.000646788, "lng": 6.0, "accuracy": 5, "t": "2026-01-01T00:00:02Z"},
        {"lat": 50.000970182, "lng": 6.0, "accuracy": 5, "t": "2026-01-01T00:00:03Z"}
      ]
    },
    {
      "name": "ungenaue_punkte_raus",
      "points": [
        {"lat": 50.0,         "lng": 6.0, "accuracy": 5,  "t": "2026-01-01T00:00:00Z"},
        {"lat": 50.5,         "lng": 6.5, "accuracy": 90, "t": "2026-01-01T00:00:01Z"},
        {"lat": 50.000107798, "lng": 6.0, "accuracy": 5,  "t": "2026-01-01T00:00:02Z"},
        {"lat": 50.000215596, "lng": 6.0, "accuracy": 5,  "t": "2026-01-01T00:00:03Z"}
      ]
    },
    {
      "name": "luecke_trennt",
      "points": [
        {"lat": 50.0,         "lng": 6.0, "accuracy": 5, "t": "2026-01-01T00:00:00Z"},
        {"lat": 50.000107798, "lng": 6.0, "accuracy": 5, "t": "2026-01-01T00:00:01Z"},
        {"lat": 51.0,         "lng": 6.0, "accuracy": 5, "t": "2026-01-01T00:00:02Z"},
        {"lat": 51.000107798, "lng": 6.0, "accuracy": 5, "t": "2026-01-01T00:00:03Z"}
      ]
    },
    {
      "name": "suedhalbkugel",
      "points": [
        {"lat": -33.8688,     "lng": 151.2093, "accuracy": 5, "t": "2026-01-01T00:00:00Z"},
        {"lat": -33.8687,     "lng": 151.2093, "accuracy": 5, "t": "2026-01-01T00:00:01Z"},
        {"lat": -33.8686,     "lng": 151.2093, "accuracy": 5, "t": "2026-01-01T00:00:02Z"}
      ]
    }
  ]
}
```

- [x] **Step 2: Dart-Paritätstest schreiben, der die erwarteten Werte erzeugt**

```dart
// test/heat/heat_grid_parity_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/domain/track_point.dart';
import 'package:speedster/heat/heat_grid.dart';

/// Erzeugt die kanonische, sortierte Darstellung einer Faltung.
/// PHP muss exakt dieselbe Struktur liefern.
Map<String, dynamic> canonical(TripFold fold) {
  final out = <String, dynamic>{};
  for (var level = 0; level < HeatGrid.levelCount; level++) {
    final edges = <String, int>{};
    fold.levels[level].edges.forEach((k, v) {
      edges['${k.a.row}:${k.a.col}:${k.b.row}:${k.b.col}'] = v;
    });
    final cells = <String, int>{};
    fold.levels[level].cells.forEach((k, v) {
      cells['${k.row}:${k.col}'] = v.n;
    });
    out['$level'] = {
      'edges': Map.fromEntries(
        edges.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      ),
      'cells': Map.fromEntries(
        cells.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      ),
    };
  }
  return out;
}

void main() {
  test('erzeugt die Paritaets-Erwartungswerte', () {
    final file = File('test/fixtures/heat_parity.json');
    final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

    final expected = <String, dynamic>{};
    for (final c in data['cases'] as List) {
      final map = c as Map<String, dynamic>;
      final points = [
        for (final p in map['points'] as List)
          TrackPoint(
            tripId: 1,
            lat: (p['lat'] as num).toDouble(),
            lng: (p['lng'] as num).toDouble(),
            speed: 0,
            altitude: 0,
            accuracy: (p['accuracy'] as num).toDouble(),
            timestamp: DateTime.parse(p['t'] as String),
          ),
      ];
      expected[map['name'] as String] = canonical(HeatGrid.foldTrip(points));
    }

    // Erwartungswerte neben die Fixtures schreiben; PHP prueft dagegen.
    File('test/fixtures/heat_parity_expected.json')
        .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(expected));

    expect(expected, isNotEmpty);
    expect((expected['gerade_strecke_12m'] as Map)['0'], isNotNull);
  });
}
```

- [x] **Step 3: Dart-Test laufen lassen, Erwartungswerte erzeugen**

Run: `flutter test test/heat/heat_grid_parity_test.dart`
Expected: PASS, `test/fixtures/heat_parity_expected.json` entsteht

- [x] **Step 4: PHP-Paritätstest schreiben**

```php
<?php
// backend/tests/Unit/HeatGridParityTest.php

use App\Services\HeatGrid;

function loadJson(string $relative): array
{
    return json_decode(file_get_contents(base_path('../'.$relative)), true);
}

/** Kanonische Darstellung, identisch zu canonical() im Dart-Test. */
function canonical(array $fold): array
{
    $out = [];
    foreach ($fold as $level => $data) {
        $edges = $data['edges'];
        $cells = [];
        foreach ($data['cells'] as $key => $cell) {
            $cells[$key] = $cell['n'];
        }
        ksort($edges, SORT_STRING);
        ksort($cells, SORT_STRING);
        $out[(string) $level] = ['edges' => $edges, 'cells' => $cells];
    }

    return $out;
}

it('rechnet identisch zur Dart-Implementierung', function () {
    $fixtures = loadJson('test/fixtures/heat_parity.json');
    $expected = loadJson('test/fixtures/heat_parity_expected.json');

    foreach ($fixtures['cases'] as $case) {
        $actual = canonical(HeatGrid::foldTrip($case['points']));
        expect($actual)->toEqual(
            $expected[$case['name']],
            "Fall {$case['name']} weicht ab"
        );
    }
});
```

- [x] **Step 5: PHP-Test laufen lassen, Fehlschlag prüfen**

Run: `cd backend && php artisan test --filter=HeatGridParity`
Expected: FAIL — `Class "App\Services\HeatGrid" not found`

- [x] **Step 6: HeatGrid.php implementieren**

```php
<?php

namespace App\Services;

/**
 * Rasterlogik der Heatmap. Zeilengetreuer Spiegel von
 * `lib/heat/heat_grid.dart` — weicht eine Seite ab, sieht die
 * Cloud-Heatmap anders aus als die lokale. HeatGridParityTest belegt
 * die Gleichheit anhand gemeinsamer Fixtures.
 */
class HeatGrid
{
    public const CELL_METERS = [25.0, 100.0, 400.0];
    public const LEVEL_COUNT = 3;
    public const METERS_PER_DEG_LAT = 111320.0;
    public const COS_CLAMP = 0.01;
    public const MAX_ACCURACY_METERS = 50.0;
    public const MAX_GAP_METERS = 200.0;
    public const MAX_GAP_SECONDS = 30;
    public const RESAMPLE_METERS = 10.0;
    private const EARTH_RADIUS_METERS = 6371000.0;

    public static function latStep(int $level): float
    {
        return self::CELL_METERS[$level] / self::METERS_PER_DEG_LAT;
    }

    /** @return array{0:int,1:int} [row, col] */
    public static function cellFor(float $lat, float $lng, int $level): array
    {
        $step = self::latStep($level);
        $row = (int) floor($lat / $step);
        $rowLat = ($row + 0.5) * $step;
        $lngStep = $step / max(cos($rowLat * M_PI / 180.0), self::COS_CLAMP);
        $col = (int) floor($lng / $lngStep);

        return [$row, $col];
    }

    public static function haversineMeters(
        float $lat1, float $lng1, float $lat2, float $lng2
    ): float {
        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);
        $a = sin($dLat / 2) ** 2
            + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLng / 2) ** 2;

        return self::EARTH_RADIUS_METERS * 2 * atan2(sqrt($a), sqrt(1 - $a));
    }

    /**
     * @param  array<int, array{lat:float,lng:float,accuracy:float,t:string}>  $points
     * @return array<int, array{cells: array<string, array{lat_sum:float,lng_sum:float,n:int}>, edges: array<string,int>}>
     */
    public static function foldTrip(array $points): array
    {
        $fold = [];
        for ($level = 0; $level < self::LEVEL_COUNT; $level++) {
            $fold[$level] = ['cells' => [], 'edges' => []];
        }

        foreach (self::segments($points) as $segment) {
            for ($level = 0; $level < self::LEVEL_COUNT; $level++) {
                self::foldSegment($segment, $level, $fold[$level]);
            }
        }

        return $fold;
    }

    /** @return array<int, array<int, array<string, mixed>>> */
    private static function segments(array $points): array
    {
        $result = [];
        $current = [];

        foreach ($points as $p) {
            if (($p['accuracy'] ?? 0) > self::MAX_ACCURACY_METERS) {
                continue;
            }
            if ($current === []) {
                $current = [$p];

                continue;
            }
            $prev = $current[count($current) - 1];
            $gap = self::haversineMeters(
                $prev['lat'], $prev['lng'], $p['lat'], $p['lng']
            );
            $seconds = abs(strtotime($p['t']) - strtotime($prev['t']));

            if ($gap > self::MAX_GAP_METERS || $seconds > self::MAX_GAP_SECONDS) {
                if (count($current) > 1) {
                    $result[] = $current;
                }
                $current = [$p];
            } else {
                $current[] = $p;
            }
        }
        if (count($current) > 1) {
            $result[] = $current;
        }

        return $result;
    }

    private static function foldSegment(array $segment, int $level, array &$acc): void
    {
        foreach ($segment as $p) {
            [$row, $col] = self::cellFor($p['lat'], $p['lng'], $level);
            $key = "$row:$col";
            if (! isset($acc['cells'][$key])) {
                $acc['cells'][$key] = ['lat_sum' => 0.0, 'lng_sum' => 0.0, 'n' => 0];
            }
            $acc['cells'][$key]['lat_sum'] += $p['lat'];
            $acc['cells'][$key]['lng_sum'] += $p['lng'];
            $acc['cells'][$key]['n']++;
        }

        $path = [];
        $count = count($segment);
        for ($i = 0; $i < $count - 1; $i++) {
            $from = $segment[$i];
            $to = $segment[$i + 1];
            self::appendCell($path, self::cellFor($from['lat'], $from['lng'], $level));

            $distance = self::haversineMeters(
                $from['lat'], $from['lng'], $to['lat'], $to['lng']
            );
            $steps = (int) floor($distance / self::RESAMPLE_METERS);
            for ($s = 1; $s <= $steps; $s++) {
                $f = $s / ($steps + 1);
                self::appendCell($path, self::cellFor(
                    $from['lat'] + ($to['lat'] - $from['lat']) * $f,
                    $from['lng'] + ($to['lng'] - $from['lng']) * $f,
                    $level
                ));
            }
        }
        if ($count > 0) {
            $last = $segment[$count - 1];
            self::appendCell($path, self::cellFor($last['lat'], $last['lng'], $level));
        }

        $previous = null;
        $pathLength = count($path);
        for ($i = 0; $i < $pathLength - 1; $i++) {
            $edge = self::normalizedEdge($path[$i], $path[$i + 1]);
            if ($edge === $previous) {
                continue;
            }
            $acc['edges'][$edge] = ($acc['edges'][$edge] ?? 0) + 1;
            $previous = $edge;
        }
    }

    private static function appendCell(array &$path, array $cell): void
    {
        $last = $path === [] ? null : $path[count($path) - 1];
        if ($last !== null && $last[0] === $cell[0] && $last[1] === $cell[1]) {
            return;
        }
        $path[] = $cell;
    }

    private static function normalizedEdge(array $x, array $y): string
    {
        $xFirst = $x[0] < $y[0] || ($x[0] === $y[0] && $x[1] <= $y[1]);
        [$a, $b] = $xFirst ? [$x, $y] : [$y, $x];

        return "{$a[0]}:{$a[1]}:{$b[0]}:{$b[1]}";
    }
}
```

- [x] **Step 7: PHP-Test laufen lassen, grün prüfen**

Run: `cd backend && php artisan test --filter=HeatGridParity`
Expected: PASS. Bei Abweichung ist **die Dart-Seite die Referenz** — PHP anpassen, nicht die Fixtures.

- [x] **Step 8: Änderungen zeigen**

```bash
git add backend/app/Services/HeatGrid.php backend/tests/Unit/HeatGridParityTest.php test/fixtures/ test/heat/heat_grid_parity_test.dart
git diff --cached --stat
```
Commit-Nachricht nach Freigabe: `feat(backend): mirror heat grid in PHP with parity fixtures`

---

### Task 9: Backend-Migration

**Files:**
- Create: `backend/database/migrations/2026_09_04_100000_create_heat_tables.php`
- Test: `backend/tests/Feature/HeatSchemaTest.php`

**Interfaces:**
- Consumes: nichts.
- Produces: Tabellen `heat_cells` (`user_id`, `level`, `cell_row`, `cell_col`, `lat_sum`, `lng_sum`, `n`) und `heat_edges` (`user_id`, `level`, `month`, `a_row`, `a_col`, `b_row`, `b_col`, `count`); Spalte `trips.heat_folded_at`.

- [x] **Step 1: Test schreiben**

```php
<?php
// backend/tests/Feature/HeatSchemaTest.php

use Illuminate\Support\Facades\Schema;

it('legt die Heat-Tabellen und die Faltungsmarkierung an', function () {
    expect(Schema::hasTable('heat_cells'))->toBeTrue();
    expect(Schema::hasTable('heat_edges'))->toBeTrue();
    expect(Schema::hasColumn('trips', 'heat_folded_at'))->toBeTrue();

    expect(Schema::hasColumns('heat_cells', [
        'user_id', 'level', 'cell_row', 'cell_col', 'lat_sum', 'lng_sum', 'n',
    ]))->toBeTrue();

    expect(Schema::hasColumns('heat_edges', [
        'user_id', 'level', 'month', 'a_row', 'a_col', 'b_row', 'b_col', 'count',
    ]))->toBeTrue();
});
```

- [x] **Step 2: Test laufen lassen, Fehlschlag prüfen**

Run: `cd backend && php artisan test --filter=HeatSchema`
Expected: FAIL — `heat_cells` existiert nicht

- [x] **Step 3: Implementieren**

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Schwerpunkte je Zelle. Ohne Monatsbucket: der Schwerpunkt einer
        // Zelle ist zeitlich stabil.
        Schema::create('heat_cells', function (Blueprint $table) {
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->unsignedTinyInteger('level');
            // Bewusst cell_row/cell_col: ROW ist in MySQL 8 reserviert.
            $table->integer('cell_row');
            $table->integer('cell_col');
            $table->double('lat_sum')->default(0);
            $table->double('lng_sum')->default(0);
            $table->unsignedInteger('n')->default(0);

            $table->primary(['user_id', 'level', 'cell_row', 'cell_col'], 'heat_cells_pk');
        });

        // Befahrungen je Kante und Monat. Der Monatsbucket ist der Grund,
        // warum die Cloud Zeitraeume filtern kann, ohne neu zu aggregieren.
        Schema::create('heat_edges', function (Blueprint $table) {
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->unsignedTinyInteger('level');
            $table->unsignedInteger('month'); // YYYYMM
            $table->integer('a_row');
            $table->integer('a_col');
            $table->integer('b_row');
            $table->integer('b_col');
            $table->unsignedInteger('count')->default(0);

            $table->primary(
                ['user_id', 'level', 'month', 'a_row', 'a_col', 'b_row', 'b_col'],
                'heat_edges_pk'
            );
            $table->index(['user_id', 'level', 'month'], 'heat_edges_scope_idx');
        });

        Schema::table('trips', function (Blueprint $table) {
            $table->dateTime('heat_folded_at')->nullable();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('heat_edges');
        Schema::dropIfExists('heat_cells');
        Schema::table('trips', function (Blueprint $table) {
            $table->dropColumn('heat_folded_at');
        });
    }
};
```

- [x] **Step 4: Test laufen lassen, grün prüfen**

Run: `cd backend && php artisan test --filter=HeatSchema`
Expected: PASS

- [x] **Step 5: Änderungen zeigen**

```bash
git add backend/database/migrations/ backend/tests/Feature/HeatSchemaTest.php
git diff --cached
```
Commit-Nachricht nach Freigabe: `feat(backend): add heat aggregate tables`

---

### Task 10: HeatAggregator und Einbindung in den Upload

**Files:**
- Create: `backend/app/Services/HeatAggregator.php`
- Modify: `backend/app/Http/Controllers/Api/TripController.php`, `backend/app/Models/Trip.php`
- Test: `backend/tests/Feature/HeatAggregationTest.php`

**Interfaces:**
- Consumes: `HeatGrid::foldTrip` (Task 8), Tabellen aus Task 9.
- Produces: `HeatAggregator::fold(Trip $trip, array $points): void`, `HeatAggregator::unfold(Trip $trip): void`. `Trip::$fillable` += `heat_folded_at`, `$casts` += `'heat_folded_at' => 'datetime'`.

- [x] **Step 1: Test schreiben**

Die Helfer kommen nach `backend/tests/Pest.php`, weil die Tasks 11 und 12
sie ebenfalls brauchen — zweimal deklariert wäre ein Fatal Error:

```php
<?php
// backend/tests/Pest.php — ans Dateiende anfuegen

function tripPayload(string $uuid, string $start = '2026-01-15T10:00:00Z', float $startLat = 50.0): array
{
    $points = [];
    for ($i = 0; $i < 20; $i++) {
        $points[] = [
            'lat' => $startLat + ($i * 12) / 111320.0,
            'lng' => 6.0,
            'speed' => 20,
            'altitude' => 100,
            'accuracy' => 5,
            't' => date('c', strtotime($start) + $i),
        ];
    }

    return [
        'client_uuid' => $uuid,
        'start_time' => $start,
        'end_time' => date('c', strtotime($start) + 20),
        'max_speed' => 20, 'avg_speed' => 15, 'distance' => 240,
        'duration_seconds' => 20, 'elevation_gain' => 0,
        'points' => $points,
    ];
}

function maxEdgeCount(int $userId): int
{
    return (int) \Illuminate\Support\Facades\DB::table('heat_edges')
        ->where('user_id', $userId)->where('level', 0)->max('count');
}
```

```php
<?php
// backend/tests/Feature/HeatAggregationTest.php

use App\Models\User;
use Illuminate\Support\Facades\DB;
use Laravel\Sanctum\Sanctum;

it('faltet eine hochgeladene Fahrt in die Aggregate', function () {
    Sanctum::actingAs($user = User::factory()->create());

    $this->postJson('/api/trips', tripPayload('uuid-1'))->assertCreated();

    expect(DB::table('heat_edges')->where('user_id', $user->id)->count())
        ->toBeGreaterThan(0);
    expect(maxEdgeCount($user->id))->toBe(1);
});

it('zaehlt zwei Fahrten ueber dieselbe Strecke doppelt', function () {
    Sanctum::actingAs($user = User::factory()->create());

    $this->postJson('/api/trips', tripPayload('uuid-1'))->assertCreated();
    $this->postJson('/api/trips', tripPayload('uuid-2'))->assertCreated();

    expect(maxEdgeCount($user->id))->toBe(2);
});

it('zaehlt einen erneuten Upload derselben Fahrt nicht doppelt', function () {
    Sanctum::actingAs($user = User::factory()->create());

    $this->postJson('/api/trips', tripPayload('uuid-1'))->assertCreated();
    $this->postJson('/api/trips', tripPayload('uuid-1'))->assertOk();

    expect(maxEdgeCount($user->id))->toBe(1);
});

it('bucketet nach dem Monat der Startzeit', function () {
    Sanctum::actingAs($user = User::factory()->create());

    $this->postJson('/api/trips', tripPayload('a', '2026-01-15T10:00:00Z'))->assertCreated();
    $this->postJson('/api/trips', tripPayload('b', '2026-03-15T10:00:00Z'))->assertCreated();

    $months = DB::table('heat_edges')->where('user_id', $user->id)
        ->distinct()->pluck('month')->sort()->values()->all();
    expect($months)->toBe([202601, 202603]);
});

it('haelt die Daten zweier Nutzer getrennt', function () {
    Sanctum::actingAs($a = User::factory()->create());
    $this->postJson('/api/trips', tripPayload('uuid-a'))->assertCreated();

    Sanctum::actingAs($b = User::factory()->create());
    $this->postJson('/api/trips', tripPayload('uuid-b'))->assertCreated();

    expect(maxEdgeCount($a->id))->toBe(1);
    expect(maxEdgeCount($b->id))->toBe(1);
});
```

- [x] **Step 2: Test laufen lassen, Fehlschlag prüfen**

Run: `cd backend && php artisan test --filter=HeatAggregation`
Expected: FAIL — `heat_edges` bleibt leer

- [x] **Step 3: Implementieren**

```php
<?php

namespace App\Services;

use App\Models\Trip;
use Illuminate\Support\Facades\DB;

/**
 * Faltet Fahrten in die Aggregattabellen und nimmt sie wieder heraus.
 *
 * Die Ruecknahme ist noetig, weil `/trips` idempotent ist: dieselbe
 * client_uuid darf erneut hochgeladen werden, ohne dass die Heatmap
 * doppelt zaehlt.
 */
class HeatAggregator
{
    /** @param array<int, array<string, mixed>> $points */
    public function fold(Trip $trip, array $points): void
    {
        DB::transaction(function () use ($trip, $points) {
            if ($trip->heat_folded_at !== null) {
                $this->unfold($trip);
            }

            $month = (int) $trip->start_time->format('Ym');
            $fold = HeatGrid::foldTrip($points);

            foreach ($fold as $level => $data) {
                foreach ($data['cells'] as $key => $cell) {
                    [$row, $col] = array_map('intval', explode(':', $key));
                    $this->addCell($trip->user_id, $level, $row, $col,
                        $cell['lat_sum'], $cell['lng_sum'], $cell['n']);
                }
                foreach ($data['edges'] as $key => $count) {
                    [$aRow, $aCol, $bRow, $bCol] = array_map('intval', explode(':', $key));
                    $this->addEdge($trip->user_id, $level, $month,
                        $aRow, $aCol, $bRow, $bCol, $count);
                }
            }

            $trip->forceFill(['heat_folded_at' => now()])->save();
        });
    }

    /** Subtrahiert den Beitrag einer bereits gefalteten Fahrt. */
    public function unfold(Trip $trip): void
    {
        if ($trip->heat_folded_at === null) {
            return;
        }

        $month = (int) $trip->start_time->format('Ym');
        $fold = HeatGrid::foldTrip($trip->points());

        foreach ($fold as $level => $data) {
            foreach ($data['cells'] as $key => $cell) {
                [$row, $col] = array_map('intval', explode(':', $key));
                $this->addCell($trip->user_id, $level, $row, $col,
                    -$cell['lat_sum'], -$cell['lng_sum'], -$cell['n']);
            }
            foreach ($data['edges'] as $key => $count) {
                [$aRow, $aCol, $bRow, $bCol] = array_map('intval', explode(':', $key));
                $this->addEdge($trip->user_id, $level, $month,
                    $aRow, $aCol, $bRow, $bCol, -$count);
            }
        }

        DB::table('heat_cells')->where('user_id', $trip->user_id)
            ->where('n', '<=', 0)->delete();
        DB::table('heat_edges')->where('user_id', $trip->user_id)
            ->where('count', '<=', 0)->delete();

        $trip->forceFill(['heat_folded_at' => null])->save();
    }

    private function addCell(
        int $userId, int $level, int $row, int $col,
        float $latSum, float $lngSum, int $n
    ): void {
        DB::table('heat_cells')->upsert(
            [[
                'user_id' => $userId, 'level' => $level,
                'cell_row' => $row, 'cell_col' => $col,
                'lat_sum' => $latSum, 'lng_sum' => $lngSum, 'n' => max($n, 0),
            ]],
            ['user_id', 'level', 'cell_row', 'cell_col'],
            [
                'lat_sum' => DB::raw('heat_cells.lat_sum + '.$latSum),
                'lng_sum' => DB::raw('heat_cells.lng_sum + '.$lngSum),
                'n' => DB::raw('heat_cells.n + '.$n),
            ]
        );
    }

    private function addEdge(
        int $userId, int $level, int $month,
        int $aRow, int $aCol, int $bRow, int $bCol, int $count
    ): void {
        DB::table('heat_edges')->upsert(
            [[
                'user_id' => $userId, 'level' => $level, 'month' => $month,
                'a_row' => $aRow, 'a_col' => $aCol,
                'b_row' => $bRow, 'b_col' => $bCol,
                'count' => max($count, 0),
            ]],
            ['user_id', 'level', 'month', 'a_row', 'a_col', 'b_row', 'b_col'],
            ['count' => DB::raw('heat_edges.count + '.$count)]
        );
    }
}
```

`backend/app/Models/Trip.php`: `'heat_folded_at'` zu `$fillable` und `'heat_folded_at' => 'datetime'` zu `$casts` ergänzen.

`TripController::store()` nach dem `updateOrCreate` ergänzen:

```php
        app(\App\Services\HeatAggregator::class)->fold($trip, $points);
```

- [x] **Step 4: Test laufen lassen, grün prüfen**

Run: `cd backend && php artisan test`
Expected: alle Tests PASS (auch die bestehenden Trip-Tests)

- [x] **Step 5: Änderungen zeigen**

```bash
git add backend/app/Services/HeatAggregator.php backend/app/Http/Controllers/Api/TripController.php backend/app/Models/Trip.php backend/tests/Feature/HeatAggregationTest.php
git diff --cached
```
Commit-Nachricht nach Freigabe: `feat(backend): fold uploaded trips into heat aggregates`

---

### Task 11: GET /api/heatmap

**Files:**
- Create: `backend/app/Http/Controllers/Api/HeatmapController.php`
- Modify: `backend/routes/api.php`
- Test: `backend/tests/Feature/HeatmapEndpointTest.php`

**Interfaces:**
- Consumes: Tabellen aus Task 9, Faltung aus Task 10.
- Produces: `GET /api/heatmap?range=all|12m|3m&level=0|1|2&min_lat=&min_lng=&max_lat=&max_lng=` → `{"range":..., "level":..., "max_count":int, "edges":[{"a":[lat,lng],"b":[lat,lng],"c":int}]}`.

- [x] **Step 1: Test schreiben**

```php
<?php
// backend/tests/Feature/HeatmapEndpointTest.php

use App\Models\User;
use Laravel\Sanctum\Sanctum;

// tripPayload() und maxEdgeCount() stehen in tests/Pest.php (Task 10).

it('verlangt Authentifizierung', function () {
    $this->getJson('/api/heatmap')->assertUnauthorized();
});

it('liefert Kanten mit aufgeloesten Koordinaten', function () {
    Sanctum::actingAs(User::factory()->create());
    $this->postJson('/api/trips', tripPayload('uuid-1'))->assertCreated();

    $res = $this->getJson('/api/heatmap?level=0')->assertOk();

    $res->assertJsonStructure([
        'range', 'level', 'max_count',
        'edges' => [['a', 'b', 'c']],
    ]);
    expect($res->json('max_count'))->toBe(1);

    $edge = $res->json('edges.0');
    expect($edge['a'][0])->toBeGreaterThan(49.9)->toBeLessThan(50.1);
    expect($edge['c'])->toBe(1);
});

it('filtert ueber die Monatsbuckets', function () {
    Sanctum::actingAs(User::factory()->create());
    $this->postJson('/api/trips', tripPayload('alt', '2020-01-15T10:00:00Z'))->assertCreated();
    $this->postJson('/api/trips', tripPayload('neu', now()->toIso8601String()))->assertCreated();

    $all = $this->getJson('/api/heatmap?range=all')->assertOk();
    $recent = $this->getJson('/api/heatmap?range=3m')->assertOk();

    expect(count($recent->json('edges')))
        ->toBeLessThan(count($all->json('edges')));
    expect(count($recent->json('edges')))->toBeGreaterThan(0);
});

it('grenzt auf den Viewport ein, laesst max_count aber global', function () {
    Sanctum::actingAs(User::factory()->create());
    $this->postJson('/api/trips', tripPayload('nah', '2026-01-15T10:00:00Z', 50.0))->assertCreated();
    $this->postJson('/api/trips', tripPayload('nah2', '2026-01-16T10:00:00Z', 50.0))->assertCreated();
    $this->postJson('/api/trips', tripPayload('fern', '2026-01-15T10:00:00Z', 51.0))->assertCreated();

    $all = $this->getJson('/api/heatmap')->assertOk();
    $box = $this->getJson('/api/heatmap?min_lat=49.9&min_lng=5.9&max_lat=50.1&max_lng=6.1')
        ->assertOk();

    expect(count($box->json('edges')))->toBeLessThan(count($all->json('edges')));
    expect($box->json('max_count'))->toBe($all->json('max_count'));
});

it('zeigt niemals fremde Daten', function () {
    Sanctum::actingAs(User::factory()->create());
    $this->postJson('/api/trips', tripPayload('fremd'))->assertCreated();

    Sanctum::actingAs(User::factory()->create());
    expect($this->getJson('/api/heatmap')->assertOk()->json('edges'))->toBe([]);
});

it('weist unzulaessige Parameter zurueck', function () {
    Sanctum::actingAs(User::factory()->create());
    $this->getJson('/api/heatmap?level=9')->assertStatus(422);
    $this->getJson('/api/heatmap?range=gestern')->assertStatus(422);
});
```

- [x] **Step 2: Test laufen lassen, Fehlschlag prüfen**

Run: `cd backend && php artisan test --filter=HeatmapEndpoint`
Expected: FAIL — Route `/api/heatmap` existiert nicht (404)

- [x] **Step 3: Implementieren**

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class HeatmapController extends Controller
{
    public function index(Request $request)
    {
        $data = $request->validate([
            'range' => 'sometimes|in:all,12m,3m',
            'level' => 'sometimes|integer|between:0,2',
            'min_lat' => 'sometimes|numeric|between:-90,90',
            'max_lat' => 'sometimes|numeric|between:-90,90',
            'min_lng' => 'sometimes|numeric|between:-180,180',
            'max_lng' => 'sometimes|numeric|between:-180,180',
        ]);

        $userId = $request->user()->id;
        $level = (int) ($data['level'] ?? 0);
        $range = $data['range'] ?? 'all';

        $edges = DB::table('heat_edges')
            ->select('a_row', 'a_col', 'b_row', 'b_col',
                DB::raw('SUM(count) as total'))
            ->where('user_id', $userId)
            ->where('level', $level)
            ->when($this->monthFloor($range), fn ($q, $m) => $q->where('month', '>=', $m))
            ->groupBy('a_row', 'a_col', 'b_row', 'b_col')
            ->get();

        // Global ueber den gewaehlten Zeitraum, nicht ueber den Viewport:
        // sonst wuerden sich die Farben beim Verschieben der Karte aendern.
        $maxCount = (int) $edges->max('total');

        $cells = DB::table('heat_cells')
            ->where('user_id', $userId)
            ->where('level', $level)
            ->where('n', '>', 0)
            ->get()
            ->keyBy(fn ($c) => "{$c->cell_row}:{$c->cell_col}");

        $out = [];
        foreach ($edges as $e) {
            $a = $cells->get("{$e->a_row}:{$e->a_col}");
            $b = $cells->get("{$e->b_row}:{$e->b_col}");
            if (! $a || ! $b) {
                continue;
            }

            $aLat = $a->lat_sum / $a->n;
            $aLng = $a->lng_sum / $a->n;
            $bLat = $b->lat_sum / $b->n;
            $bLng = $b->lng_sum / $b->n;

            if (! $this->inBox($data, $aLat, $aLng) && ! $this->inBox($data, $bLat, $bLng)) {
                continue;
            }

            $out[] = [
                'a' => [$aLat, $aLng],
                'b' => [$bLat, $bLng],
                'c' => (int) $e->total,
            ];
        }

        return response()->json([
            'range' => $range,
            'level' => $level,
            'max_count' => $maxCount,
            'edges' => $out,
        ]);
    }

    /** Kleinster einzuschliessender Monatsbucket, null bei `all`. */
    private function monthFloor(string $range): ?int
    {
        return match ($range) {
            '3m' => (int) now()->subMonths(3)->format('Ym'),
            '12m' => (int) now()->subMonths(12)->format('Ym'),
            default => null,
        };
    }

    private function inBox(array $data, float $lat, float $lng): bool
    {
        if (! isset($data['min_lat'], $data['max_lat'], $data['min_lng'], $data['max_lng'])) {
            return true;
        }

        return $lat >= $data['min_lat'] && $lat <= $data['max_lat']
            && $lng >= $data['min_lng'] && $lng <= $data['max_lng'];
    }
}
```

`backend/routes/api.php` in der `auth:sanctum`-Gruppe ergänzen:

```php
    Route::get('/heatmap', [HeatmapController::class, 'index']);
```
plus `use App\Http\Controllers\Api\HeatmapController;`.

- [x] **Step 4: Test laufen lassen, grün prüfen**

Run: `cd backend && php artisan test`
Expected: PASS

- [x] **Step 5: Änderungen zeigen**

```bash
git add backend/app/Http/Controllers/Api/HeatmapController.php backend/routes/api.php backend/tests/Feature/HeatmapEndpointTest.php
git diff --cached
```
Commit-Nachricht nach Freigabe: `feat(backend): add GET /api/heatmap`

---

### Task 12: Artisan-Command heatmap:rebuild

Nötig für Bestandsdaten — alle bereits hochgeladenen Fahrten sind ungefaltet.

**Files:**
- Create: `backend/app/Console/Commands/HeatmapRebuild.php`
- Test: `backend/tests/Feature/HeatmapRebuildTest.php`

**Interfaces:**
- Consumes: `HeatAggregator` (Task 10), `Trip::points()` (bestehend).
- Produces: Command-Signatur `heatmap:rebuild {--user=}`.

- [x] **Step 1: Test schreiben**

```php
<?php
// backend/tests/Feature/HeatmapRebuildTest.php

use App\Models\User;
use Illuminate\Support\Facades\DB;
use Laravel\Sanctum\Sanctum;

it('baut die Aggregate aus vorhandenen Fahrten neu auf', function () {
    Sanctum::actingAs($user = User::factory()->create());
    $this->postJson('/api/trips', tripPayload('uuid-1'))->assertCreated();

    $before = (int) DB::table('heat_edges')->where('user_id', $user->id)->max('count');
    expect($before)->toBe(1);

    // Aggregate verwerfen, so als kaemen die Fahrten aus der Zeit vor
    // diesem Feature.
    DB::table('heat_edges')->delete();
    DB::table('heat_cells')->delete();
    DB::table('trips')->update(['heat_folded_at' => null]);

    $this->artisan('heatmap:rebuild')->assertSuccessful();

    expect((int) DB::table('heat_edges')->where('user_id', $user->id)->max('count'))
        ->toBe($before);
});

it('kann auf einen Nutzer eingegrenzt werden', function () {
    Sanctum::actingAs($a = User::factory()->create());
    $this->postJson('/api/trips', tripPayload('a'))->assertCreated();
    Sanctum::actingAs($b = User::factory()->create());
    $this->postJson('/api/trips', tripPayload('b'))->assertCreated();

    DB::table('heat_edges')->delete();
    DB::table('heat_cells')->delete();
    DB::table('trips')->update(['heat_folded_at' => null]);

    $this->artisan('heatmap:rebuild', ['--user' => $a->id])->assertSuccessful();

    expect(DB::table('heat_edges')->where('user_id', $a->id)->count())->toBeGreaterThan(0);
    expect(DB::table('heat_edges')->where('user_id', $b->id)->count())->toBe(0);
});
```

- [x] **Step 2: Test laufen lassen, Fehlschlag prüfen**

Run: `cd backend && php artisan test --filter=HeatmapRebuild`
Expected: FAIL — Command `heatmap:rebuild` ist nicht definiert

- [x] **Step 3: Implementieren**

```php
<?php

namespace App\Console\Commands;

use App\Models\Trip;
use App\Services\HeatAggregator;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

/**
 * Baut die Heatmap-Aggregate aus den gespeicherten Routen-Blobs neu.
 * Noetig fuer Fahrten, die vor Einfuehrung des Features hochgeladen
 * wurden, und als Reparaturweg.
 */
class HeatmapRebuild extends Command
{
    protected $signature = 'heatmap:rebuild {--user= : Nur diesen Nutzer}';

    protected $description = 'Baut die Heatmap-Aggregate neu auf';

    public function handle(HeatAggregator $aggregator): int
    {
        $userId = $this->option('user');

        DB::table('heat_cells')->when($userId, fn ($q) => $q->where('user_id', $userId))->delete();
        DB::table('heat_edges')->when($userId, fn ($q) => $q->where('user_id', $userId))->delete();
        Trip::query()->when($userId, fn ($q) => $q->where('user_id', $userId))
            ->update(['heat_folded_at' => null]);

        $count = 0;
        Trip::query()
            ->when($userId, fn ($q) => $q->where('user_id', $userId))
            ->orderBy('id')
            ->chunkById(100, function ($trips) use ($aggregator, &$count) {
                foreach ($trips as $trip) {
                    $points = $trip->points();
                    if ($points === []) {
                        continue;
                    }
                    $aggregator->fold($trip, $points);
                    $count++;
                }
            });

        $this->info("Heatmap neu aufgebaut: {$count} Fahrten.");

        return self::SUCCESS;
    }
}
```

- [x] **Step 4: Test laufen lassen, grün prüfen**

Run: `cd backend && php artisan test`
Expected: PASS

- [x] **Step 5: Änderungen zeigen**

```bash
git add backend/app/Console/Commands/HeatmapRebuild.php backend/tests/Feature/HeatmapRebuildTest.php
git diff --cached
```
Commit-Nachricht nach Freigabe: `feat(backend): add heatmap:rebuild command`

---

### Task 13: CloudHeatSource und Quellenwahl mit Fallback

**Files:**
- Create: `lib/heat/cloud_heat_source.dart`
- Modify: `lib/app/providers.dart`
- Test: `test/heat/cloud_heat_source_test.dart`

**Interfaces:**
- Consumes: `HeatSource`, `HeatMap`, `HeatQuery` (Task 5); `ApiClient`, `TokenStore` (bestehend); `LocalHeatSource` (Task 5).
- Produces: `CloudHeatSource(Dio dio)`; `FallbackHeatSource(HeatSource primary, HeatSource fallback, TokenStore tokenStore)`; `heatSourceProvider` liefert nun `FallbackHeatSource`; `cloudActiveProvider` (`FutureProvider<bool>`).

- [x] **Step 1: Test schreiben**

```dart
// test/heat/cloud_heat_source_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/cloud/token_store.dart';
import 'package:speedster/heat/cloud_heat_source.dart';
import 'package:speedster/heat/heat_map.dart';
import 'package:speedster/heat/heat_source.dart';

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.body, {this.statusCode = 200});
  final String body;
  final int statusCode;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(RequestOptions options, _, __) async {
    lastRequest = options;
    return ResponseBody.fromString(body, statusCode,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
  }

  @override
  void close({bool force = false}) {}
}

class _FailingSource implements HeatSource {
  @override
  Future<HeatMap> load(HeatQuery query) async => throw DioException(
        requestOptions: RequestOptions(path: '/heatmap'),
      );
}

class _LocalStub implements HeatSource {
  bool called = false;
  @override
  Future<HeatMap> load(HeatQuery query) async {
    called = true;
    return const HeatMap(edges: [], maxCount: 7);
  }
}

void main() {
  test('parst die Antwort des Endpunkts', () async {
    final adapter = _StubAdapter('''
      {"range":"all","level":0,"max_count":9,
       "edges":[{"a":[50.0,6.0],"b":[50.001,6.001],"c":4}]}
    ''');
    final dio = Dio()..httpClientAdapter = adapter;

    final map = await CloudHeatSource(dio).load(const HeatQuery(level: 0));

    expect(map.maxCount, 9);
    expect(map.edges.single.count, 4);
    expect(map.edges.single.aLat, 50.0);
    expect(map.edges.single.bLng, 6.001);
  });

  test('schickt Range, Level und Viewport mit', () async {
    final adapter = _StubAdapter('{"max_count":0,"edges":[]}');
    final dio = Dio()..httpClientAdapter = adapter;

    await CloudHeatSource(dio).load(
      const HeatQuery(
        level: 2,
        range: HeatRange.months3,
        bounds: HeatBounds(49.0, 5.0, 51.0, 7.0),
      ),
    );

    final params = adapter.lastRequest!.queryParameters;
    expect(params['range'], '3m');
    expect(params['level'], 2);
    expect(params['min_lat'], 49.0);
    expect(params['max_lng'], 7.0);
  });

  test('ohne Token wird direkt lokal geladen', () async {
    final local = _LocalStub();
    final source = FallbackHeatSource(
      _FailingSource(),
      local,
      InMemoryTokenStore(),
    );

    final map = await source.load(const HeatQuery(level: 0));
    expect(local.called, isTrue);
    expect(map.maxCount, 7);
  });

  test('faellt bei Cloud-Fehler auf lokal zurueck', () async {
    final store = InMemoryTokenStore();
    await store.write('token');
    final local = _LocalStub();

    final map = await FallbackHeatSource(_FailingSource(), local, store)
        .load(const HeatQuery(level: 0));

    expect(local.called, isTrue);
    expect(map.maxCount, 7);
  });

  test('401 loescht den Token und faellt lokal zurueck', () async {
    final store = InMemoryTokenStore();
    await store.write('abgelaufen');
    final local = _LocalStub();

    final unauthorized = _FailingSource.withStatus(401);
    final map =
        await FallbackHeatSource(unauthorized, local, store)
            .load(const HeatQuery(level: 0));

    expect(await store.read(), isNull, reason: 'Token muss geloescht sein');
    expect(map.maxCount, 7);
  });
}
```

`_FailingSource` muss dafür einen Status tragen können:

```dart
class _FailingSource implements HeatSource {
  _FailingSource([this.status]);
  factory _FailingSource.withStatus(int status) => _FailingSource(status);

  final int? status;

  @override
  Future<HeatMap> load(HeatQuery query) async {
    final options = RequestOptions(path: '/heatmap');
    throw DioException(
      requestOptions: options,
      response: status == null
          ? null
          : Response<dynamic>(requestOptions: options, statusCode: status),
    );
  }
}
```

- [x] **Step 2: Test laufen lassen, Fehlschlag prüfen**

Run: `flutter test test/heat/cloud_heat_source_test.dart`
Expected: FAIL — `cloud_heat_source.dart` existiert nicht

- [x] **Step 3: Implementieren**

```dart
// lib/heat/cloud_heat_source.dart
import 'package:dio/dio.dart';
import 'package:speedster/cloud/token_store.dart';
import 'package:speedster/heat/heat_map.dart';
import 'package:speedster/heat/heat_source.dart';

/// Liest die serverseitig aggregierte Heatmap. Nur hier greifen die
/// Zeitraum-Filter — lokal fehlen die Monatsbuckets.
class CloudHeatSource implements HeatSource {
  CloudHeatSource(this.dio);

  final Dio dio;

  @override
  Future<HeatMap> load(HeatQuery query) async {
    final bounds = query.bounds;
    final res = await dio.get<Map<String, dynamic>>(
      '/heatmap',
      queryParameters: {
        'range': query.range.wire,
        'level': query.level,
        if (bounds != null) ...{
          'min_lat': bounds.minLat,
          'min_lng': bounds.minLng,
          'max_lat': bounds.maxLat,
          'max_lng': bounds.maxLng,
        },
      },
    );

    final data = res.data ?? const {};
    final edges = <HeatEdgeView>[];
    for (final raw in (data['edges'] as List? ?? const [])) {
      final e = raw as Map<String, dynamic>;
      final a = e['a'] as List;
      final b = e['b'] as List;
      edges.add(
        HeatEdgeView(
          aLat: (a[0] as num).toDouble(),
          aLng: (a[1] as num).toDouble(),
          bLat: (b[0] as num).toDouble(),
          bLng: (b[1] as num).toDouble(),
          count: (e['c'] as num).toInt(),
        ),
      );
    }

    return HeatMap(
      edges: edges,
      maxCount: (data['max_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Waehlt die Quelle und faengt Cloud-Ausfaelle ab.
///
/// Die Heatmap ist der Start-Screen: sie darf nie in einen Fehlerzustand
/// kippen, nur weil das Netz weg ist.
class FallbackHeatSource implements HeatSource {
  FallbackHeatSource(this.cloud, this.local, this.tokenStore);

  final HeatSource cloud;
  final HeatSource local;
  final TokenStore tokenStore;

  @override
  Future<HeatMap> load(HeatQuery query) async {
    if (await tokenStore.read() == null) {
      return local.load(query);
    }
    try {
      return await cloud.load(query);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Token abgelaufen: loeschen wie beim Sync, damit die Quellenwahl
        // beim naechsten Aufruf von selbst auf lokal umschaltet.
        await tokenStore.clear();
      }
      return local.load(query);
    }
  }
}
```

`lib/app/providers.dart` — `heatSourceProvider` ersetzen und `cloudActiveProvider` ergänzen:

```dart
final heatSourceProvider = Provider<HeatSource>(
  (ref) => FallbackHeatSource(
    CloudHeatSource(ref.watch(apiClientProvider).dio),
    LocalHeatSource(
      ref.watch(databaseProvider),
      ref.watch(heatFolderProvider),
    ),
    ref.watch(tokenStoreProvider),
  ),
);

/// Steuert, ob die Zeitraum-Filter angeboten werden.
final cloudActiveProvider = FutureProvider<bool>(
  (ref) async => await ref.watch(tokenStoreProvider).read() != null,
);
```

- [x] **Step 4: Test laufen lassen, grün prüfen**

Run: `flutter test test/heat/ && flutter analyze`
Expected: PASS, keine Befunde

- [x] **Step 5: Änderungen zeigen**

```bash
git add lib/heat/cloud_heat_source.dart lib/app/providers.dart test/heat/cloud_heat_source_test.dart
git diff --cached
```
Commit-Nachricht nach Freigabe: `feat(heat): add cloud source with local fallback`

---

### Task 14: Filter-Chips

**Files:**
- Modify: `lib/ui/heatmap_screen.dart`
- Test: `test/ui/heatmap_filter_test.dart`

**Interfaces:**
- Consumes: `cloudActiveProvider` (Task 13), `HeatRange` (Task 5).
- Produces: keine neuen öffentlichen Typen.

- [x] **Step 1: Test schreiben**

```dart
// test/ui/heatmap_filter_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/heat/heat_map.dart';
import 'package:speedster/heat/heat_source.dart';
import 'package:speedster/ui/heatmap_screen.dart';

class _Source implements HeatSource {
  final queries = <HeatQuery>[];
  @override
  Future<HeatMap> load(HeatQuery query) async {
    queries.add(query);
    return const HeatMap(
      edges: [
        HeatEdgeView(aLat: 50, aLng: 6, bLat: 50.001, bLng: 6.001, count: 1),
      ],
      maxCount: 1,
    );
  }
}

Widget wrap(HeatSource source, {required bool cloud}) => ProviderScope(
      overrides: [
        heatSourceProvider.overrideWithValue(source),
        cloudActiveProvider.overrideWith((ref) async => cloud),
      ],
      child: const MaterialApp(home: HeatmapScreen()),
    );

void main() {
  testWidgets('ohne Cloud gibt es keine Filter', (tester) async {
    await tester.pumpWidget(wrap(_Source(), cloud: false));
    await tester.pumpAndSettle();
    expect(find.text('Alles'), findsNothing);
    expect(find.text('12 Monate'), findsNothing);
  });

  testWidgets('mit Cloud erscheinen die Filter und wirken', (tester) async {
    final source = _Source();
    await tester.pumpWidget(wrap(source, cloud: true));
    await tester.pumpAndSettle();

    expect(find.text('Alles'), findsOneWidget);
    expect(find.text('12 Monate'), findsOneWidget);
    expect(find.text('3 Monate'), findsOneWidget);

    await tester.tap(find.text('3 Monate'));
    await tester.pumpAndSettle();

    expect(source.queries.last.range, HeatRange.months3);
  });
}
```

- [x] **Step 2: Test laufen lassen, Fehlschlag prüfen**

Run: `flutter test test/ui/heatmap_filter_test.dart`
Expected: FAIL — `Alles` wird nicht gefunden

- [x] **Step 3: Implementieren**

In `lib/ui/heatmap_screen.dart` den `Stack` um eine Chip-Leiste erweitern und den Filter in `_query` übernehmen:

```dart
  void _setRange(HeatRange range) {
    setState(() {
      _query = HeatQuery(
        level: _query.level,
        bounds: _query.bounds,
        range: range,
      );
    });
  }
```

Im `Stack` nach der Legende:

```dart
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Consumer(
                  builder: (context, ref, _) {
                    // Nur die Cloud kennt Monatsbuckets; lokal gibt es
                    // nichts zu filtern.
                    final cloud =
                        ref.watch(cloudActiveProvider).asData?.value ?? false;
                    if (!cloud) return const SizedBox.shrink();
                    return Wrap(
                      spacing: 8,
                      children: [
                        for (final (range, label) in const [
                          (HeatRange.all, 'Alles'),
                          (HeatRange.months12, '12 Monate'),
                          (HeatRange.months3, '3 Monate'),
                        ])
                          ChoiceChip(
                            label: Text(label),
                            selected: _query.range == range,
                            onSelected: (_) => _setRange(range),
                          ),
                      ],
                    );
                  },
                ),
              ),
```

Der `Consumer`-Import kommt aus `flutter_riverpod`, ist also bereits vorhanden.

- [x] **Step 4: Tests laufen lassen, grün prüfen**

Run: `flutter test && flutter analyze`
Expected: alle PASS

- [x] **Step 5: Änderungen zeigen**

```bash
git add lib/ui/heatmap_screen.dart test/ui/heatmap_filter_test.dart
git diff --cached
```
Commit-Nachricht nach Freigabe: `feat(ui): add cloud-only time range filters`

**Phase B ist hier lauffähig.** Vor Phase C prüfen: Backend starten, `php artisan heatmap:rebuild` laufen lassen, App eingeloggt öffnen — die Filter müssen erscheinen und wirken.

---

# Phase C — Auto-Erkennung

### Task 15: CarConnection-Abstraktion und Start-Tab-Erweiterung

**Files:**
- Create: `lib/app/car_connection.dart`
- Modify: `lib/app/providers.dart`, `lib/app/app.dart`
- Test: `test/app/car_connection_test.dart`

**Interfaces:**
- Consumes: `HomeShell` (Task 7).
- Produces: `abstract class CarConnection { Stream<bool> get connected; }`; `PlatformCarConnection`; `FakeCarConnection(Stream<bool>)`; `carConnectionProvider` (`Provider<CarConnection>`), `carConnectedProvider` (`StreamProvider<bool>`).

- [x] **Step 1: Test schreiben**

```dart
// test/app/car_connection_test.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/app/app.dart';
import 'package:speedster/app/car_connection.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/heat/heat_map.dart';
import 'package:speedster/heat/heat_source.dart';
import 'package:speedster/recording/trip_recorder.dart';

class _EmptySource implements HeatSource {
  @override
  Future<HeatMap> load(HeatQuery query) async => HeatMap.empty;
}

Widget wrap({required bool carConnected}) => ProviderScope(
      overrides: [
        heatSourceProvider.overrideWithValue(_EmptySource()),
        recorderStateProvider
            .overrideWith((ref) => Stream.value(const RecorderState())),
        carConnectedProvider
            .overrideWith((ref) => Stream.value(carConnected)),
      ],
      child: const MaterialApp(home: HomeShell()),
    );

void main() {
  test('FakeCarConnection reicht den Stream durch', () async {
    final fake = FakeCarConnection(Stream.fromIterable([false, true]));
    expect(await fake.connected.toList(), [false, true]);
  });

  testWidgets('ohne Auto-Verbindung startet die Heatmap', (tester) async {
    await tester.pumpWidget(wrap(carConnected: false));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      HomeShell.heatmapTab,
    );
  });

  testWidgets('mit Auto-Verbindung startet Live, auch ohne isDriving',
      (tester) async {
    await tester.pumpWidget(wrap(carConnected: true));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      HomeShell.liveTab,
    );
  });
}
```

- [x] **Step 2: Test laufen lassen, Fehlschlag prüfen**

Run: `flutter test test/app/car_connection_test.dart`
Expected: FAIL — `car_connection.dart` existiert nicht

- [x] **Step 3: Implementieren**

```dart
// lib/app/car_connection.dart
import 'package:flutter/services.dart';

/// Meldet, ob das Geraet mit CarPlay oder Android Auto verbunden ist.
///
/// Bewusst ein *zusaetzliches* Signal neben der Fahrterkennung, nie das
/// einzige: faellt der Plattformkanal aus, lautet die Antwort `false` und
/// die App verhaelt sich wie vorher.
abstract class CarConnection {
  Stream<bool> get connected;
}

class PlatformCarConnection implements CarConnection {
  const PlatformCarConnection();

  static const _channel =
      EventChannel('de.codesphere.speedster/car_connection');

  @override
  Stream<bool> get connected => _channel
      .receiveBroadcastStream()
      .map((event) => event == true)
      .handleError((_) {})
      .cast<bool>();
}

class FakeCarConnection implements CarConnection {
  FakeCarConnection(this._stream);

  final Stream<bool> _stream;

  @override
  Stream<bool> get connected => _stream;
}
```

`lib/app/providers.dart`:

```dart
final carConnectionProvider = Provider<CarConnection>(
  (ref) => const PlatformCarConnection(),
);

final carConnectedProvider = StreamProvider<bool>(
  (ref) => ref.watch(carConnectionProvider).connected,
);
```

`lib/app/app.dart` — in `build` von `_HomeShellState` vor dem `return` ergänzen:

```dart
    // Auto verbunden heisst: der Nutzer sitzt im Wagen, auch wenn die
    // Fahrterkennung noch nicht angesprungen ist.
    ref.listen(carConnectedProvider, (prev, next) {
      if (next.asData?.value == true && _index == HomeShell.heatmapTab) {
        setState(() => _index = HomeShell.liveTab);
      }
    });
```

- [x] **Step 4: Test laufen lassen, grün prüfen**

Run: `flutter test && flutter analyze`
Expected: PASS

- [x] **Step 5: Änderungen zeigen**

```bash
git add lib/app/car_connection.dart lib/app/providers.dart lib/app/app.dart test/app/car_connection_test.dart
git diff --cached
```
Commit-Nachricht nach Freigabe: `feat(app): show live tab when the car is connected`

---

### Task 16: Android — CarConnection über androidx.car.app

**Files:**
- Modify: `android/app/build.gradle.kts`, `android/app/src/main/kotlin/de/codesphere/speedster/MainActivity.kt`

**Interfaces:**
- Consumes: EventChannel-Name `de.codesphere.speedster/car_connection` (Task 15).
- Produces: Ereignisse `true`/`false` auf diesem Kanal.

- [x] **Step 1: Dependency ergänzen**

In `android/app/build.gradle.kts` nach dem `kotlin`-Block:

```kotlin
dependencies {
    // Liefert den Verbindungsstatus zu Android Auto, ohne dass die App
    // selbst eine Auto-App sein muss.
    implementation("androidx.car.app:app:1.7.0")
}
```

- [x] **Step 2: MainActivity erweitern**

```kotlin
package de.codesphere.speedster

import androidx.car.app.connection.CarConnection
import androidx.lifecycle.Observer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    private var observer: Observer<Int>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "de.codesphere.speedster/car_connection",
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                val liveData = CarConnection(this@MainActivity).type
                val o = Observer<Int> { type ->
                    events?.success(type != CarConnection.CONNECTION_TYPE_NOT_CONNECTED)
                }
                observer = o
                liveData.observe(this@MainActivity, o)
            }

            override fun onCancel(arguments: Any?) {
                observer?.let { CarConnection(this@MainActivity).type.removeObserver(it) }
                observer = null
            }
        })
    }
}
```

- [x] **Step 3: Build prüfen**

Run: `flutter build apk --debug`
Expected: erfolgreicher Build. Schlägt die Auflösung von `androidx.car.app:app:1.7.0` fehl, die aktuelle Version über `https://maven.google.com` prüfen und eintragen.

- [x] **Step 4: Änderungen zeigen**

```bash
git add android/
git diff --cached
```
Commit-Nachricht nach Freigabe: `feat(android): report android auto connection state`

---

### Task 17: iOS — CarConnection über die Audio-Route

**Files:**
- Modify: `ios/Runner/AppDelegate.swift`

**Interfaces:**
- Consumes: EventChannel-Name aus Task 15.
- Produces: Ereignisse `true`/`false`.

- [x] **Step 1: AppDelegate erweitern**

```swift
import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var carSink: FlutterEventSink?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterEventChannel(
      name: "de.codesphere.speedster/car_connection",
      binaryMessenger: controller.binaryMessenger
    )
    channel.setStreamHandler(self)

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// CarPlay meldet sich als Audio-Ausgang vom Typ `carAudio`. Das laesst
  /// sich ohne CarPlay-Entitlement lesen — ein Entitlement braeuchte erst
  /// eine eigene App auf dem Autodisplay.
  private func isCarConnected() -> Bool {
    AVAudioSession.sharedInstance().currentRoute.outputs.contains {
      $0.portType == .carAudio
    }
  }

  @objc private func routeChanged(_ notification: Notification) {
    carSink?(isCarConnected())
  }
}

extension AppDelegate: FlutterStreamHandler {
  func onListen(
    withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    carSink = events
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(routeChanged(_:)),
      name: AVAudioSession.routeChangeNotification,
      object: nil
    )
    events(isCarConnected())
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    NotificationCenter.default.removeObserver(
      self, name: AVAudioSession.routeChangeNotification, object: nil
    )
    carSink = nil
    return nil
  }
}
```

- [x] **Step 2: Build prüfen**

Run: `flutter build ios --no-codesign`
Expected: erfolgreicher Build

- [x] **Step 3: Gesamtlauf**

Run: `flutter analyze && flutter test && cd backend && php artisan test`
Expected: alles grün

- [x] **Step 4: Änderungen zeigen**

```bash
git add ios/
git diff --cached
```
Commit-Nachricht nach Freigabe: `feat(ios): report carplay connection state`

---

## Abschlussprüfung auf einem Gerät

Nicht automatisierbar, deshalb als Checkliste — passend zu `docs/qa/`:

- [ ] App öffnen ohne laufende Fahrt → Heatmap ist sichtbar.
- [ ] Zwei Fahrten über dieselbe Straße → dieser Abschnitt ist deutlich heller als der Rest.
- [ ] Herauszoomen → Linien bleiben sichtbar, keine Ruckler (Levelwechsel bei Zoom 14 und 11).
- [ ] Ausgeloggt → keine Filter-Chips; eingeloggt → Chips wirken.
- [ ] Flugmodus bei eingeloggtem Konto → Heatmap zeigt weiter lokale Daten statt eines Fehlers.
- [ ] Fahrt starten bei offener App → Sprung auf Live; Fahrt beenden → bleibt auf Live.
- [ ] Mit CarPlay/Android Auto verbinden → Live wird aktiv.
- [ ] Tunnelfahrt → keine Gerade quer über die Karte.
