import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';

/// Loest Koordinaten in einen Ortsnamen auf.
///
/// Der Name entsteht **einmal am Fahrtende** und liegt danach an der
/// Fahrt. Nicht bei jeder Anzeige neu: die Aufloesung geht ueber das Netz,
/// iOS drosselt sie hart, und eine Liste mit dreissig Zeilen loeste sonst
/// bei jedem Blaettern dreissig Abfragen aus. So steht der Name auch ohne
/// Netz noch da.
abstract class PlaceNamer {
  /// Der Ort zu diesen Koordinaten, oder null.
  ///
  /// Null ist ein regulaeres Ergebnis und kein Fehler: mitten auf der
  /// Autobahn oder ohne Netz gibt es keinen Namen, und die Fahrt bleibt
  /// dann bei ihrem Datum.
  Future<String?> nameFor(double lat, double lng);
}

class PlatformPlaceNamer implements PlaceNamer {
  PlatformPlaceNamer({
    this.timeout = const Duration(seconds: 8),
    Geocoding? geocoding,
  }) : _geocoding = geocoding ?? Geocoding();

  final Geocoding _geocoding;

  /// Wie lange auf das System gewartet wird.
  ///
  /// Ohne Grenze haengt die Aufloesung ohne Netz bis zum Zeitlimit der
  /// Plattform -- das ist auf iOS deutlich laenger und faellt genau dann
  /// an, wenn man gerade geparkt hat.
  final Duration timeout;

  @override
  Future<String?> nameFor(double lat, double lng) async {
    try {
      final marks = await _geocoding
          .placemarkFromCoordinates(
            lat,
            lng,
            // In der Sprache des Geraets: sonst steht "Cologne" in einer
            // sonst deutschen Oberflaeche.
            locale: PlatformDispatcher.instance.locale,
          )
          .timeout(timeout);
      if (marks.isEmpty) return null;

      return nameOf(marks.first);
    } on Object {
      // Kein Netz, kein Treffer, keine Plattformanbindung: die Fahrt ist
      // aufgezeichnet, der Name ist Beiwerk.
      return null;
    }
  }

  /// Die Stadt, sonst der naechstgroessere Verwaltungsbezirk.
  ///
  /// Bewusst nur eine Ebene und keine Adresse: in der Fahrtenliste steht
  /// "Koeln -> Duesseldorf" und nicht die Strasse. Auf dem Land und auf
  /// der Autobahn fehlt die Stadt ganz -- dort traegt der Kreis die
  /// Aussage.
  @visibleForTesting
  static String? nameOf(Placemark mark) {
    for (final candidate in [
      mark.locality,
      mark.subAdministrativeArea,
      mark.administrativeArea,
    ]) {
      if (candidate != null && candidate.isNotEmpty) return candidate;
    }

    return null;
  }
}

/// Fuer Tests: liefert feste Namen und zaehlt die Abfragen.
class FakePlaceNamer implements PlaceNamer {
  FakePlaceNamer([this.names = const {}]);

  /// Namen je "lat,lng". Was nicht darin steht, bleibt namenlos.
  final Map<String, String> names;

  final List<String> asked = [];

  @override
  Future<String?> nameFor(double lat, double lng) async {
    final key = '$lat,$lng';
    asked.add(key);

    return names[key];
  }
}
