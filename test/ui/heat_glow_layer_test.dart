import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/heat/heat_palette.dart';
import 'package:speedster/ui/heat_glow_layer.dart';

void main() {
  // Ein realistischer Kartenausschnitt in Logik-Pixeln.
  const viewport = Size(400, 800);

  test('weit ausserhalb liegende Kanten werden ausgeschlossen', () {
    // Weit rechts unten, kein Weichzeichner der Welt reicht so weit.
    final visible = heatSegmentOverlapsViewport(
      a: const Offset(2000, 2000),
      b: const Offset(2100, 2100),
      viewport: viewport,
      margin: 40,
    );

    expect(visible, isFalse);
  });

  test(
      'eine Kante knapp ausserhalb bleibt sichtbar, wenn ihr Schein '
      'hineinreicht', () {
    // Liegt bei x = -30..-25, also links ausserhalb von [0, 400] -- aber
    // die Weichzeichnung (margin 40) reicht bis x = 15 in den Ausschnitt.
    final visible = heatSegmentOverlapsViewport(
      a: const Offset(-30, 100),
      b: const Offset(-25, 150),
      viewport: viewport,
      margin: 40,
    );

    expect(visible, isTrue);
  });

  test('dieselbe Kante faellt ohne ausreichenden Rand doch heraus', () {
    // Gleiche Kante wie oben, aber der Rand ist zu knapp, um bis in den
    // Ausschnitt zu reichen -- zeigt, dass der Test oben wirklich am Rand
    // haengt und nicht zufaellig durchkommt.
    final visible = heatSegmentOverlapsViewport(
      a: const Offset(-30, 100),
      b: const Offset(-25, 150),
      viewport: viewport,
      margin: 10,
    );

    expect(visible, isFalse);
  });

  test('eine vollstaendig im Ausschnitt liegende Kante bleibt sichtbar', () {
    final visible = heatSegmentOverlapsViewport(
      a: const Offset(100, 200),
      b: const Offset(150, 250),
      viewport: viewport,
      margin: 10,
    );

    expect(visible, isTrue);
  });

  test('heatCullMargin folgt dem breiteren, staerker weichgezeichneten '
      'Schein-Layer', () {
    final style = HeatPalette.styleFor(10, 20);

    final expected = style.glow.strokeWidth / 2 + style.glow.blurSigma * 3;
    expect(heatCullMargin(style), expected);

    // Muss grosszuegiger sein als der Kern allein, sonst schneidet die
    // Kulisse den Schein an der Bildschirmkante hart ab.
    final coreOnlyMargin =
        style.core.strokeWidth / 2 + style.core.blurSigma * 3;
    expect(heatCullMargin(style), greaterThan(coreOnlyMargin));
  });
}
