import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Farbskala der Heatmap: dunkelrot (selten) nach hellgelb (oft).
class HeatPalette {
  const HeatPalette._();

  static const List<(double, Color)> stops = [
    (0.0, Color(0xFF4A0E0E)),
    (0.35, Color(0xFFB3261E)),
    (0.7, Color(0xFFFF7A00)),
    (1.0, Color(0xFFFFD54A)),
  ];

  /// Logarithmisch normiert. Befahrungszahlen sind stark schief verteilt —
  /// der Arbeitsweg hat dreistellige Werte, der Ausflug eine 1. Linear
  /// normiert waere alles ausser dem Arbeitsweg unlesbar dunkel.
  static Color colorFor(int count, int maxCount) {
    if (count <= 0) return stops.first.$2;
    if (maxCount <= 1) return stops.last.$2;

    final t = (math.log(count) / math.log(maxCount)).clamp(0.0, 1.0);
    return _lerp(t);
  }

  static Color _lerp(double t) {
    for (var i = 0; i < stops.length - 1; i++) {
      final (fromT, fromC) = stops[i];
      final (toT, toC) = stops[i + 1];
      if (t <= toT) {
        final span = toT - fromT;
        final local = span == 0 ? 0.0 : (t - fromT) / span;
        return Color.lerp(fromC, toC, local)!;
      }
    }
    return stops.last.$2;
  }
}
