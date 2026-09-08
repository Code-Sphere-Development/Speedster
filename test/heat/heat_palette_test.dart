import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/heat/heat_palette.dart';

void main() {
  test('einmal gefahren ist dunkles Rot, nicht Orange', () {
    // Eine fruehere Fassung faerbte niedrige Intensitaet hell und
    // kraeftig -- auf der dunklen Esri-Basiskarte muss der dunkelrote Ton
    // lesbar bleiben, ohne die haeufigen Strecken zu verdraengen.
    final style = HeatPalette.styleFor(1, 100);

    final color = style.core.color;
    expect(color.r, closeTo(0x3B / 255, 0.02));
    expect(color.g, closeTo(0x0D / 255, 0.02));
    expect(color.b, closeTo(0x12 / 255, 0.02));
  });

  test('mittlere Haeufigkeit trifft das kraeftige Rot des App-Akzents', () {
    // intensity(10, 100) liegt bei genau 0.5 -- der Mittelpunkt der Rampe.
    final color = HeatPalette.colorFor(0.5);

    expect(color.r, closeTo(0xC8 / 255, 0.02));
    expect(color.g, closeTo(0x1E / 255, 0.02));
    expect(color.b, closeTo(0x28 / 255, 0.02));
  });

  test('haeufigste Nutzung endet auf gesaettigtem Gold, nicht auf Weissgrau',
      () {
    final style = HeatPalette.styleFor(100, 100);
    final color = style.core.color;

    expect(color.r, closeTo(0xFF / 255, 0.02));
    expect(color.g, closeTo(0x9A / 255, 0.02));
    expect(color.b, closeTo(0x3C / 255, 0.02));

    final low = HeatPalette.styleFor(1, 100).core.color;
    expect(color.r, greaterThan(low.r));
    expect(color.g, greaterThan(low.g));
    expect(color.b, greaterThan(low.b));
  });

  test('der oberste Stop bleibt farbig statt weisslich', () {
    // Der Kern der Regression: mit einem fast weissen Endpunkt sattierte
    // jede haeufig befahrene Strecke unter BlendMode.plus sofort zu reinem
    // Weiss durch, und die Abstufung dazwischen verschwand. Ein deutlicher
    // Abstand zwischen dem staerksten und dem schwaechsten Kanal haelt die
    // Farbe -- bei Weissgrau liegen alle drei fast gleichauf.
    final high = HeatPalette.colorFor(1);
    final spread = high.r - high.b;

    expect(spread, greaterThan(0.4));
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
