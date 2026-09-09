import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:speedster/settings/unit_system.dart';

void main() {
  test('formats speed in km/h', () {
    expect(SpeedFormat.speed(10, UnitSystem.kmh), '36 km/h');
  });
  test('formats speed in mph', () {
    expect(SpeedFormat.speed(10, UnitSystem.mph), '22 mph');
  });
  test('formats distance in the current language', () {
    // Die Testumgebung laeuft auf Deutsch (flutter_test_config.dart), und
    // dort gehoert ein Komma hin. toStringAsFixed schrieb immer einen
    // Punkt -- der Fehler war in jeder Distanz der App zu sehen.
    expect(SpeedFormat.distance(1500, UnitSystem.kmh), '1,5 km');
    expect(SpeedFormat.distance(1609.34, UnitSystem.mph), '1,0 mi');
  });

  test('formats distance with a point in English', () {
    final previous = Intl.defaultLocale;
    Intl.defaultLocale = 'en';
    addTearDown(() => Intl.defaultLocale = previous);

    expect(SpeedFormat.distance(1500, UnitSystem.kmh), '1.5 km');
    expect(SpeedFormat.distance(1609.34, UnitSystem.mph), '1.0 mi');
  });
}
