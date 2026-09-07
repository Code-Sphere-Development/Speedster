import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/domain/track_point.dart';
import 'package:speedster/heat/heat_grid.dart';

/// Kanonische, sortierte Darstellung einer Faltung.
/// Die PHP-Seite muss exakt dieselbe Struktur liefern.
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

/// Mit `--dart-define=REGENERATE_HEAT_FIXTURES=true` werden die
/// Erwartungswerte neu geschrieben statt geprueft. Danach gehoeren beide
/// JSON-Dateien nach `tests/fixtures/` im Speedster_Cloud-Repo kopiert,
/// sonst pruefen die beiden Implementierungen gegen verschiedene Referenzen.
const _regenerate = bool.fromEnvironment('REGENERATE_HEAT_FIXTURES');

void main() {
  test('Dart-Rasterung entspricht der festgeschriebenen Referenz', () {
    final data = jsonDecode(File('test/fixtures/heat_parity.json')
        .readAsStringSync()) as Map<String, dynamic>;

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

    final baseline = File('test/fixtures/heat_parity_expected.json');

    if (_regenerate) {
      baseline.writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(expected)}\n',
      );
      return;
    }

    // Gegen die Referenz pruefen, nicht sie ueberschreiben: sonst faellt eine
    // Abweichung auf der Dart-Seite nie auf, und die PHP-Seite prueft gegen
    // etwas, das sich stillschweigend mitverschoben hat.
    final committed =
        jsonDecode(baseline.readAsStringSync()) as Map<String, dynamic>;
    expect(
      jsonDecode(jsonEncode(expected)),
      committed,
      reason: 'Rasterung geaendert? Dann mit '
          '--dart-define=REGENERATE_HEAT_FIXTURES=true neu erzeugen und die '
          'Dateien ins Speedster_Cloud-Repo kopieren.',
    );
  });
}
