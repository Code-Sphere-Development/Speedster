import 'package:intl/intl.dart';

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

  /// Distance with one decimal, e.g. "1,5 km" (de) / "1.5 mi" (en).
  ///
  /// Ueber NumberFormat und nicht ueber toStringAsFixed: das schreibt
  /// immer einen Punkt, und im Deutschen gehoert dort ein Komma. Welche
  /// Sprache gilt, sagt Intl.defaultLocale -- gesetzt wird das einmal an
  /// der Wurzel der App (siehe SpeedsterApp).
  static String distance(double meters, UnitSystem u) {
    final value = u == UnitSystem.kmh
        ? meters / 1000
        : meters / _metersPerMile;

    return '${_oneDecimal.format(value)} ${u == UnitSystem.kmh ? 'km' : 'mi'}';
  }

  static NumberFormat get _oneDecimal => NumberFormat.decimalPatternDigits(
        decimalDigits: 1,
      );
}
