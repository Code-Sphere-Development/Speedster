import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/heat/heat_grid.dart';

void main() {
  test('dieselbe Koordinate ergibt dieselbe Zelle', () {
    expect(HeatGrid.cellFor(50.9412, 6.9583, 0),
        HeatGrid.cellFor(50.9412, 6.9583, 0));
  });

  test('80 m Versatz ergibt nie dieselbe Zelle', () {
    final base = HeatGrid.cellFor(50.9412, 6.9583, 0);
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
