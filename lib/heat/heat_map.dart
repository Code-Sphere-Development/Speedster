/// Rechteckiger Kartenausschnitt.
class HeatBounds {
  const HeatBounds(this.minLat, this.minLng, this.maxLat, this.maxLng);

  final double minLat;
  final double minLng;
  final double maxLat;
  final double maxLng;

  @override
  bool operator ==(Object other) =>
      other is HeatBounds &&
      other.minLat == minLat &&
      other.minLng == minLng &&
      other.maxLat == maxLat &&
      other.maxLng == maxLng;

  @override
  int get hashCode => Object.hash(minLat, minLng, maxLat, maxLng);
}

/// Zeitraum. Nur die Cloud kann filtern — lokal fehlen die Monatsbuckets.
enum HeatRange {
  all('all'),
  months12('12m'),
  months3('3m');

  const HeatRange(this.wire);

  final String wire;
}

/// Wertsemantik, damit der Provider nicht bei jedem Rebuild neu laedt.
class HeatQuery {
  const HeatQuery({
    required this.level,
    this.bounds,
    this.range = HeatRange.all,
  });

  final int level;
  final HeatBounds? bounds;
  final HeatRange range;

  HeatQuery copyWith({int? level, HeatBounds? bounds, HeatRange? range}) =>
      HeatQuery(
        level: level ?? this.level,
        bounds: bounds ?? this.bounds,
        range: range ?? this.range,
      );

  @override
  bool operator ==(Object other) =>
      other is HeatQuery &&
      other.level == level &&
      other.bounds == bounds &&
      other.range == range;

  @override
  int get hashCode => Object.hash(level, bounds, range);
}

/// Eine zeichenbare Kante: zwei Zellschwerpunkte plus Befahrungszahl.
class HeatEdgeView {
  const HeatEdgeView({
    required this.aLat,
    required this.aLng,
    required this.bLat,
    required this.bLng,
    required this.count,
  });

  final double aLat;
  final double aLng;
  final double bLat;
  final double bLng;
  final int count;
}

class HeatMap {
  const HeatMap({required this.edges, required this.maxCount});

  final List<HeatEdgeView> edges;

  /// Maximum ueber den gesamten Zeitraum und Level, nicht nur ueber den
  /// Viewport — sonst wuerden sich die Farben beim Verschieben der Karte
  /// aendern.
  final int maxCount;

  static const empty = HeatMap(edges: [], maxCount: 0);
}

/// Zoomstufe → Rasterebene.
class HeatGridZoom {
  const HeatGridZoom._();

  static int levelForZoom(double zoom) {
    if (zoom >= 14) return 0;
    if (zoom >= 11) return 1;
    return 2;
  }
}
