import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/settings/unit_system.dart';

void main() {
  test('formats speed in km/h', () {
    expect(SpeedFormat.speed(10, UnitSystem.kmh), '36 km/h');
  });
  test('formats speed in mph', () {
    expect(SpeedFormat.speed(10, UnitSystem.mph), '22 mph');
  });
  test('formats distance in km', () {
    expect(SpeedFormat.distance(1500, UnitSystem.kmh), '1.5 km');
  });
  test('formats distance in miles', () {
    expect(SpeedFormat.distance(1609.34, UnitSystem.mph), '1.0 mi');
  });
}
