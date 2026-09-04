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
    expect(fold.levels[2].edges.length, lessThan(fold.levels[0].edges.length));
  });

  test('15 m GPS-Versatz trifft praktisch dieselben Kanten', () {
    // Lange Spur, damit auch Level 2 (400-m-Zellen) Kanten hat: eine kurze
    // Fahrt passt dort komplett in eine Zelle und erzeugt gar keine.
    final a = HeatGrid.foldTrip(line(count: 200));
    final b = HeatGrid.foldTrip(line(count: 200, startLat: 50.0 + 15 / 111320.0));

    for (var level = 0; level < HeatGrid.levelCount; level++) {
      final keysA = a.levels[level].edges.keys.toSet();
      final keysB = b.levels[level].edges.keys.toSet();
      expect(keysA, isNotEmpty, reason: 'Level $level ohne Kanten');
      final shared = keysA.intersection(keysB).length;
      expect(shared / keysA.length, greaterThan(0.9),
          reason: 'Level $level fing das Rauschen nicht: '
              '$shared von ${keysA.length}');
    }
  });

  test('Tempo 130 (36 m Punktabstand) erzeugt eine lueckenlose Kette', () {
    final fold = HeatGrid.foldTrip(line(spacingMeters: 36, count: 10));
    final rows = <int>{
      for (final e in fold.levels[0].edges.keys) ...[e.a.row, e.b.row],
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
      startLat: 51.0,
      count: 5,
      start: DateTime.utc(2026, 1, 1, 0, 0, 4),
    );
    final fold = HeatGrid.foldTrip([...first, ...second]);
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
    final badCol = HeatGrid.cellFor(50.0, 7.5, 0).col;
    for (final c in fold.levels[0].cells.keys) {
      expect(c.col, isNot(badCol));
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
    final twice = fold.levels[0].edges.values.where((c) => c == 2).length;
    expect(twice, greaterThan(fold.levels[0].edges.length ~/ 2));
  });

  test('Zellschwerpunkte stammen nur aus real gemessenen Punkten', () {
    final pts = line(count: 5, spacingMeters: 36);
    final fold = HeatGrid.foldTrip(pts);
    final totalN = fold.levels[0].cells.values.fold<int>(0, (a, c) => a + c.n);
    expect(totalN, pts.length,
        reason: 'interpolierte Punkte duerfen nicht mitzaehlen');
  });

  test('leere und einpunktige Eingaben sind unauffaellig', () {
    expect(HeatGrid.foldTrip([]).levels[0].edges, isEmpty);
    expect(HeatGrid.foldTrip(line(count: 1)).levels[0].edges, isEmpty);
  });
}
