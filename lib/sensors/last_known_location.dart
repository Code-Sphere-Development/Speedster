import 'package:geolocator/geolocator.dart';

/// Letzte vom Betriebssystem gemerkte Position.
///
/// Dient allein dazu, die Karte sinnvoll zu zentrieren, solange noch keine
/// Strecken aufgezeichnet sind. Bewusst abstrahiert, damit Tests ohne
/// Ortungsdienste auskommen.
abstract class LastKnownLocation {
  Future<({double lat, double lng})?> get();
}

class GeolocatorLastKnownLocation implements LastKnownLocation {
  const GeolocatorLastKnownLocation();

  @override
  Future<({double lat, double lng})?> get() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position == null) return null;
      return (lat: position.latitude, lng: position.longitude);
    } catch (_) {
      // Fehlende Rechte oder abgeschalteter Ortungsdienst sind hier kein
      // Fehler: die Karte startet dann eben mit der Uebersicht.
      return null;
    }
  }
}

class FakeLastKnownLocation implements LastKnownLocation {
  const FakeLastKnownLocation([this.value]);

  final ({double lat, double lng})? value;

  @override
  Future<({double lat, double lng})?> get() async => value;
}
