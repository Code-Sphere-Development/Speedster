enum UnitSystem { kmh, mph }

/// Converts SI values (m/s, meters) into display strings for the chosen unit.
class SpeedFormat {
  static const _mpsToKmh = 3.6;
  static const _mpsToMph = 2.23694;
  static const _metersPerMile = 1609.344;

  /// Speed rounded to whole units, e.g. "36 km/h" / "22 mph".
  static String speed(double mps, UnitSystem u) {
    switch (u) {
      case UnitSystem.kmh:
        return '${(mps * _mpsToKmh).round()} km/h';
      case UnitSystem.mph:
        return '${(mps * _mpsToMph).round()} mph';
    }
  }

  /// Distance with one decimal, e.g. "1.5 km" / "1.0 mi".
  static String distance(double meters, UnitSystem u) {
    switch (u) {
      case UnitSystem.kmh:
        return '${(meters / 1000).toStringAsFixed(1)} km';
      case UnitSystem.mph:
        return '${(meters / _metersPerMile).toStringAsFixed(1)} mi';
    }
  }
}
