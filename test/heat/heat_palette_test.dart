import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/heat/heat_palette.dart';

void main() {
  test('einmal befahren ist sichtbar, nicht fast schwarz', () {
    // Der Vorgaenger faerbte genau diesen Fall #4A0E0E -- und weil fast
    // jede Strecke nur einmal gefahren wird, war die ganze Karte dunkel.
    final style = HeatPalette.styleFor(1, 50);

    expect(style.core.color.r, greaterThan(0.9));
    expect(style.core.color.a, greaterThan(0.8));
  });

  test('haeufiger heisst breiter und deckender, nie duenner', () {
    var previousWidth = 0.0;
    var previousAlpha = 0.0;
    for (final count in [1, 2, 5, 20, 50]) {
      final core = HeatPalette.styleFor(count, 50).core;
      expect(core.strokeWidth, greaterThanOrEqualTo(previousWidth));
      expect(core.color.a, greaterThanOrEqualTo(previousAlpha - 0.001));
      previousWidth = core.strokeWidth;
      previousAlpha = core.color.a;
    }
  });

  test('die drei Ebenen liegen von aussen nach innen', () {
    final s = HeatPalette.styleFor(10, 20);

    // Der Schein muss breiter und durchsichtiger sein als der Kern, sonst
    // entsteht kein weicher Rand sondern wieder eine harte Linie.
    expect(s.glow.strokeWidth, greaterThan(s.halo.strokeWidth));
    expect(s.halo.strokeWidth, greaterThan(s.core.strokeWidth));
    expect(s.glow.color.a, lessThan(s.halo.color.a));
    expect(s.halo.color.a, lessThan(s.core.color.a));
    expect(s.layers.length, 3);
  });

  test('Normierung ist logarithmisch und begrenzt', () {
    expect(HeatPalette.intensity(1, 100), 0);
    expect(HeatPalette.intensity(100, 100), 1);
    expect(HeatPalette.intensity(10, 100), closeTo(0.5, 0.01));
    // Randfaelle duerfen nicht in eine Division durch null laufen.
    expect(HeatPalette.intensity(1, 1), 1);
    expect(HeatPalette.intensity(0, 0), 0);
    expect(HeatPalette.intensity(5, 2), 1);
  });
}
