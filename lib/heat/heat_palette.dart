import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Eine Zeichenebene der Heatmap: Farbe samt Deckkraft und Strichstaerke.
class HeatLayer {
  const HeatLayer(this.color, this.strokeWidth);

  final Color color;
  final double strokeWidth;
}

/// Die drei Ebenen einer Strecke, von aussen nach innen gezeichnet.
class HeatStyle {
  const HeatStyle(this.glow, this.halo, this.core);

  final HeatLayer glow;
  final HeatLayer halo;
  final HeatLayer core;

  List<HeatLayer> get layers => [glow, halo, core];
}

/// Darstellung der Heatmap.
///
/// Haeufigkeit wird ueber Deckkraft und Strichstaerke getragen, nicht ueber
/// Dunkelheit. Eine fruehere Fassung faerbte selten befahrene Strecken fast
/// schwarz -- und weil praktisch jede Strecke genau einmal gefahren wurde,
/// war die Karte eine dunkle Kritzelei auf hellen Kacheln.
///
/// Gezeichnet wird jede Strecke dreimal: breit und fast durchsichtig, mittel,
/// dann duenn und hell. Wo sich Strecken ueberlagern, addieren sich die
/// Ebenen von selbst -- Kreuzungen leuchten, ohne dass sie berechnet werden.
class HeatPalette {
  const HeatPalette._();

  /// Aussenschein, traegt die weiche Kante.
  static const Color glowColor = Color(0xFFFF3B00);

  /// Mittlere Ebene, gibt der Strecke Koerper.
  static const Color haloColor = Color(0xFFFF7A00);

  /// Kern bei seltener Nutzung.
  static const Color coreLow = Color(0xFFFFB03A);

  /// Kern bei haeufigster Nutzung.
  static const Color coreHigh = Color(0xFFFFF3B0);

  /// Normierte Haeufigkeit zwischen 0 und 1.
  ///
  /// Logarithmisch, weil Befahrungszahlen stark schief verteilt sind: der
  /// Arbeitsweg hat dreistellige Werte, der Ausflug eine 1.
  static double intensity(int count, int maxCount) {
    if (count <= 0) return 0;
    if (maxCount <= 1) return 1;
    return (math.log(count) / math.log(maxCount)).clamp(0.0, 1.0);
  }

  static HeatStyle styleFor(int count, int maxCount) {
    final t = intensity(count, maxCount);

    return HeatStyle(
      HeatLayer(glowColor.withValues(alpha: 0.10 + 0.14 * t), 12 + 8 * t),
      HeatLayer(haloColor.withValues(alpha: 0.26 + 0.24 * t), 7 + 4 * t),
      HeatLayer(
        Color.lerp(coreLow, coreHigh, t)!.withValues(alpha: 0.85 + 0.15 * t),
        2.5 + 1.5 * t,
      ),
    );
  }
}
