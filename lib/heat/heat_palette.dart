import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Eine Zeichenebene der Heatmap: Farbe samt Deckkraft, Strichstaerke und
/// Weichzeichnung.
class HeatLayer {
  const HeatLayer({
    required this.color,
    required this.strokeWidth,
    required this.blurSigma,
  });

  final Color color;
  final double strokeWidth;

  /// Sigma fuer `MaskFilter.blur`. 0 zeichnet eine harte Kante.
  final double blurSigma;
}

/// Die zwei Ebenen einer Strecke: ein breiter, stark weichgezeichneter
/// Schein und ein schmaler, kaum weichgezeichneter Kern.
class HeatStyle {
  const HeatStyle({required this.glow, required this.core});

  final HeatLayer glow;
  final HeatLayer core;

  List<HeatLayer> get layers => [glow, core];
}

/// Darstellung der Heatmap.
///
/// Farbrampe von dunkel nach hell, gemessen an einer Referenz-App:
/// dunkler Wein (selten befahren) -> Karmesin (mittel) -> helles Warmgrau
/// (haeufigster Kern einer einzelnen Strecke). Zusaetzliches Ausbrennen zu
/// Weiss an Kreuzungen entsteht nicht aus der Rampe selbst, sondern aus der
/// additiven Ueberlagerung mehrerer Strecken beim Zeichnen (`BlendMode.plus`
/// in `HeatGlowLayer`, siehe `lib/ui/heat_glow_layer.dart`).
///
/// Haeufigkeit wird ueber Farbe, Deckkraft und Strichstaerke getragen. Eine
/// fruehere Fassung faerbte selten befahrene Strecken fast schwarz -- und
/// weil praktisch jede Strecke genau einmal gefahren wurde, war die Karte
/// eine dunkle Kritzelei auf hellen Kacheln. Die dunkle Esri-Basiskarte
/// (siehe `lib/ui/map_tiles.dart`) macht den dunklen Wein-Ton bei niedriger
/// Intensitaet jetzt wieder lesbar, statt wie Schmutz zu wirken.
///
/// WICHTIG: `resources/js/maps.js` im Speedster_Cloud-Repository spiegelt
/// diese Rampe fuer den Webclient. Aendert sich [colorLow], [colorMid] oder
/// [colorHigh], muss die dortige Kopie von Hand nachgezogen werden -- dieses
/// Repository darf das andere nicht anfassen.
class HeatPalette {
  const HeatPalette._();

  /// Selten befahren: dunkler Wein.
  static const Color colorLow = Color(0xFF4A182C);

  /// Mittlere Haeufigkeit: Karmesin.
  static const Color colorMid = Color(0xFF842D42);

  /// Kern bei haeufigster Nutzung einer einzelnen Strecke: helles Warmgrau,
  /// nahe am Ausbrennen.
  static const Color colorHigh = Color(0xFFBEBEB2);

  /// Normierte Haeufigkeit zwischen 0 und 1.
  ///
  /// Logarithmisch, weil Befahrungszahlen stark schief verteilt sind: der
  /// Arbeitsweg hat dreistellige Werte, der Ausflug eine 1.
  static double intensity(int count, int maxCount) {
    if (count <= 0) return 0;
    if (maxCount <= 1) return 1;
    return (math.log(count) / math.log(maxCount)).clamp(0.0, 1.0);
  }

  /// Farbe entlang der Rampe fuer eine normierte Intensitaet 0..1.
  static Color colorFor(double t) {
    final clamped = t.clamp(0.0, 1.0);
    if (clamped <= 0.5) {
      return Color.lerp(colorLow, colorMid, clamped / 0.5)!;
    }
    return Color.lerp(colorMid, colorHigh, (clamped - 0.5) / 0.5)!;
  }

  static HeatStyle styleFor(int count, int maxCount) {
    final t = intensity(count, maxCount);
    final color = colorFor(t);

    return HeatStyle(
      // Breiter Schein, stark weichgezeichnet: traegt die weiche Kante und
      // ist die Ebene, die an Kreuzungen additiv Richtung Weiss aufaddiert.
      glow: HeatLayer(
        color: color.withValues(alpha: 0.35 + 0.35 * t),
        strokeWidth: 14 + 10 * t,
        blurSigma: 8 + 6 * t,
      ),
      // Schmaler, fast scharfer Kern: gibt der Strecke Koerper und Kontur.
      core: HeatLayer(
        color: color.withValues(alpha: 0.85 + 0.15 * t),
        strokeWidth: 2.5 + 2 * t,
        blurSigma: 1 + 0.5 * t,
      ),
    );
  }
}
