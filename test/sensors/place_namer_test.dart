import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:speedster/sensors/place_namer.dart';

Placemark mark({
  String? locality,
  String? subAdministrativeArea,
  String? administrativeArea,
}) =>
    Placemark(
      locality: locality,
      subAdministrativeArea: subAdministrativeArea,
      administrativeArea: administrativeArea,
    );

void main() {
  test('die Stadt zuerst', () {
    expect(
      PlatformPlaceNamer.nameOf(
        mark(
          locality: 'Köln',
          subAdministrativeArea: 'Köln',
          administrativeArea: 'Nordrhein-Westfalen',
        ),
      ),
      'Köln',
    );
  });

  test('ohne Stadt der Kreis, sonst das Land', () {
    // Auf der Autobahn und auf dem Land liefert das System keine Stadt.
    // Dort traegt die naechstgroessere Ebene die Aussage -- "Nordrhein-
    // Westfalen" sagt wenig, aber mehr als nichts.
    expect(
      PlatformPlaceNamer.nameOf(
        mark(
          subAdministrativeArea: 'Rhein-Sieg-Kreis',
          administrativeArea: 'Nordrhein-Westfalen',
        ),
      ),
      'Rhein-Sieg-Kreis',
    );
    expect(
      PlatformPlaceNamer.nameOf(mark(administrativeArea: 'Bayern')),
      'Bayern',
    );
  });

  test('ein leerer Name ist keiner', () {
    // Android liefert fuer Unbekanntes den leeren String statt null; ohne
    // diese Pruefung stuende in der Liste ein Pfeil ins Nichts.
    expect(
      PlatformPlaceNamer.nameOf(mark(locality: '', administrativeArea: 'Hessen')),
      'Hessen',
    );
    expect(PlatformPlaceNamer.nameOf(mark()), isNull);
  });
}
