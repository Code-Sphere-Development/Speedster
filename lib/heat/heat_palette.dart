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
/// Farbrampe "Rotglut": dunkles Rot (einmal gefahren) -> kraeftiges Rot
/// (mittel) -> Gold-Amber (taeglich). Das Ausbrennen zu Weiss entsteht
/// nicht aus der Rampe, sondern aus der additiven Ueberlagerung mehrerer
/// Strecken beim Zeichnen (`BlendMode.plus` in `HeatGlowLayer`).
///
/// Der oberste Stop ist bewusst eine gesaettigte Farbe und kein Weissgrau.
/// Eine fruehere Fassung endete auf `#BEBEB2`; zusammen mit der additiven
/// Ueberlagerung sattierte damit jede haeufig befahrene Strecke sofort zu
/// reinem Weiss durch. Die Karte kannte danach nur noch zwei Zustaende --
/// blasses Rosa oder Weiss -- und die Abstufung dazwischen, um die es bei
/// einer Heatmap geht, war verschwunden. Nachgewiesen durch Rendern der
/// Zeichenebene in eine Bilddatei, nicht durch Betrachten der Zahlen.
///
/// Aus demselben Grund liegen die Deckkraefte niedriger als naiv gedacht:
/// bei additiver Mischung addiert sich jede Ueberlappung, ein Startwert
/// von 0,35 fuer den Schein war bereits zu hoch.
///
/// Haeufigkeit wird ueber Farbe, Deckkraft und Strichstaerke getragen. Eine
/// noch fruehere Fassung faerbte selten befahrene Strecken fast schwarz --
/// und weil praktisch jede Strecke genau einmal gefahren wurde, war die
/// Karte eine dunkle Kritzelei auf hellen Kacheln. Die dunkle
/// Esri-Basiskarte (siehe `lib/ui/map_tiles.dart`) macht den dunkelroten
/// Ton bei niedriger Intensitaet lesbar, statt ihn wie Schmutz wirken zu
/// lassen.
///
/// WICHTIG: `resources/js/maps.js` im Speedster_Cloud-Repository spiegelt
/// diese Rampe fuer den Webclient. Aendert sich [colorLow], [colorMid] oder
/// [colorHigh], muss die dortige Kopie von Hand nachgezogen werden -- dieses
/// Repository darf das andere nicht anfassen.
class HeatPalette {
  const HeatPalette._();

  /// Einmal gefahren: dunkles Rot, auf der dunklen Karte gerade noch
  /// deutlich als Farbe erkennbar.
  static const Color colorLow = Color(0xFF3B0D12);

  /// Mittlere Haeufigkeit: kraeftiges Rot, der Ton des App-Akzents.
  static const Color colorMid = Color(0xFFC81E28);

  /// Haeufigste Nutzung einer einzelnen Strecke: Gold-Amber. Gesaettigt,
  /// nicht weisslich -- siehe Klassenkommentar.
  static const Color colorHigh = Color(0xFFFF9A3C);

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

  /// Weichzeichnung der Schein-Ebene.
  ///
  /// Fest statt nach Intensitaet gestaffelt, weil der Weichzeichner nicht
  /// mehr je Strecke, sondern einmal ueber die gesamte Ebene laeuft (siehe
  /// `HeatGlowLayer`). Ein Blur je Strecke kostete bei mehreren tausend
  /// Kanten ebenso viele Offscreen-Durchgaenge pro Bild -- die Karte war
  /// dadurch nicht mehr fluessig zu bedienen. Die Staffelung nach
  /// Haeufigkeit tragen weiterhin Farbe, Deckkraft und Strichstaerke.
  static const double glowBlurSigma = 11.0;

  static HeatStyle styleFor(int count, int maxCount) {
    final t = intensity(count, maxCount);
    final color = colorFor(t);

    return HeatStyle(
      // Breiter Schein: traegt die weiche Kante und ist die Ebene, die an
      // Kreuzungen additiv Richtung Weiss aufaddiert.
      glow: HeatLayer(
        color: color.withValues(alpha: 0.16 + 0.30 * t),
        strokeWidth: 14 + 10 * t,
        blurSigma: glowBlurSigma,
      ),
      // Schmaler, scharfer Kern: gibt der Strecke Koerper und Kontur.
      // Ohne eigene Weichzeichnung -- die des Scheins genuegt, und eine
      // zweite kostete einen weiteren Ebenendurchgang je Bild.
      core: HeatLayer(
        color: color.withValues(alpha: 0.55 + 0.40 * t),
        strokeWidth: 2.5 + 2 * t,
        blurSigma: 0,
      ),
    );
  }
}
