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
    final mid = HeatPalette.colorFor(14, 200);
    expect(mid.g, greaterThan(const Color(0xFF4A0E0E).g));
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
