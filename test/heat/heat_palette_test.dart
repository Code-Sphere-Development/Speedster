import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/heat/heat_palette.dart';

void main() {
  test('selten befahren ist dunkler Wein, nicht Orange', () {
    // Gemessen an der Referenz-App: #4A182C. Eine fruehere Fassung faerbte
    // niedrige Intensitaet hell und kraeftig -- auf der jetzt dunklen
    // Esri-Basiskarte muss der dunkle Wein-Ton wieder lesbar sein.
    final style = HeatPalette.styleFor(1, 100);

    final color = style.core.color;
    expect(color.r, closeTo(0x4A / 255, 0.02));
    expect(color.g, closeTo(0x18 / 255, 0.02));
    expect(color.b, closeTo(0x2C / 255, 0.02));
  });

  test('mittlere Haeufigkeit trifft den gemessenen Karmesin-Ton', () {
    // intensity(10, 100) liegt bei genau 0.5 -- der Mittelpunkt der Rampe.
    final color = HeatPalette.colorFor(0.5);

    expect(color.r, closeTo(0x84 / 255, 0.02));
    expect(color.g, closeTo(0x2D / 255, 0.02));
    expect(color.b, closeTo(0x42 / 255, 0.02));
  });

  test('haeufigste Nutzung naehert sich einem hellen, fast weissen Kern',
      () {
    final style = HeatPalette.styleFor(100, 100);
    final color = style.core.color;

    // Gemessener Endpunkt der Rampe: #BEBEB2 -- deutlich heller und
    // entsaettigter als der dunkle Wein-Ton bei niedriger Intensitaet.
    expect(color.r, closeTo(0xBE / 255, 0.02));
    expect(color.g, closeTo(0xBE / 255, 0.02));
    expect(color.b, closeTo(0xB2 / 255, 0.02));

    final low = HeatPalette.styleFor(1, 100).core.color;
    expect(color.r, greaterThan(low.r));
    expect(color.g, greaterThan(low.g));
    expect(color.b, greaterThan(low.b));
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

  test('der Schein liegt breiter, weicher und durchsichtiger als der Kern',
      () {
    final s = HeatPalette.styleFor(10, 20);

    // Der Schein muss breiter, staerker weichgezeichnet und durchsichtiger
    // sein als der Kern, sonst entsteht kein weicher Rand sondern wieder
    // eine harte Linie.
    expect(s.glow.strokeWidth, greaterThan(s.core.strokeWidth));
    expect(s.glow.blurSigma, greaterThan(s.core.blurSigma));
    expect(s.glow.color.a, lessThan(s.core.color.a));
    expect(s.layers.length, 2);
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
