import 'package:intl/intl.dart';

enum UnitSystem { kmh, mph }

/// Zahl und Einheit getrennt.
///
/// Braucht es, sobald eine Kennzahl gross und ihre Einheit klein daneben
/// stehen soll: als ein String liesse sich das nicht setzen, ohne den
/// String wieder aufzutrennen.
typedef Measure = ({String value, String unit});

/// Converts SI values (m/s, meters) into display strings for the chosen unit.
class SpeedFormat {
  static const _mpsToKmh = 3.6;
  static const _mpsToMph = 2.23694;
  static const _metersPerMile = 1609.344;

  /// Tempo auf ganze Einheiten gerundet, getrennt nach Zahl und Einheit.
  static Measure speedParts(double mps, UnitSystem u) => switch (u) {
    UnitSystem.kmh => (value: '${(mps * _mpsToKmh).round()}', unit: 'km/h'),
    UnitSystem.mph => (value: '${(mps * _mpsToMph).round()}', unit: 'mph'),
  };

  /// Strecke mit einer Nachkommastelle, getrennt nach Zahl und Einheit.
  ///
  /// Ueber NumberFormat und nicht ueber toStringAsFixed: das schreibt
  /// immer einen Punkt, und im Deutschen gehoert dort ein Komma. Welche
  /// Sprache gilt, sagt Intl.defaultLocale -- gesetzt wird das einmal an
  /// der Wurzel der App (siehe SpeedsterApp).
  static Measure distanceParts(double meters, UnitSystem u) {
    final value = u == UnitSystem.kmh ? meters / 1000 : meters / _metersPerMile;

    return (
      value: _oneDecimal.format(value),
      unit: u == UnitSystem.kmh ? 'km' : 'mi',
    );
  }

  /// Speed rounded to whole units, e.g. "36 km/h" / "22 mph".
  static String speed(double mps, UnitSystem u) => _joined(speedParts(mps, u));

  /// Distance with one decimal, e.g. "1,5 km" (de) / "1.5 mi" (en).
  static String distance(double meters, UnitSystem u) =>
      _joined(distanceParts(meters, u));

  static String _joined(Measure m) => '${m.value} ${m.unit}';

  static NumberFormat get _oneDecimal =>
      NumberFormat.decimalPatternDigits(decimalDigits: 1);
}
