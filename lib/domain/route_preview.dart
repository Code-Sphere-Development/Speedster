import 'package:speedster/domain/track_point.dart';
import 'package:speedster/stats/stats_engine.dart';

/// Eine stark vereinfachte Strecke, klein genug, um an der Fahrt selbst
/// zu haengen.
///
/// Die Fahrtenliste soll die gefahrene Strecke zeigen. Die Punkte dafuer
/// stehen aber nur fuer die zuletzt gefahrenen Fahrten auf dem Geraet --
/// bei aktiver Cloud raeumt `TripCacheService` alles jenseits der zehn
/// neuesten weg. Eine Miniatur aus den Punkten gaebe es also fuer die
/// wenigsten Zeilen, und fuer alle uebrigen je eine Netzabfrage.
///
/// Deshalb wird beim Fahrtende eine Handvoll Stuetzpunkte als Text an der
/// Fahrt gespeichert. Der ueberlebt das Verdraengen der Punkte, kostet
/// unter einem Kilobyte und braucht nie wieder das Netz.
typedef LatLng = ({double lat, double lng});

abstract final class RoutePreview {
  /// Mehr Stuetzpunkte braucht ein 64 Pixel breites Bild nicht.
  static const int maxPoints = 48;

  /// Fuenf Nachkommastellen sind rund 1,1 Meter -- auf dieser Flaeche
  /// deutlich feiner als ein Bildpunkt.
  static const int _decimals = 5;

  static const String _pointSeparator = ';';
  static const String _partSeparator = ',';

  /// `null`, wenn es nichts zu zeichnen gibt -- eine leere Zeichenkette
  /// waere ein zweiter Ausdruck fuer denselben Zustand.
  static String? encode(List<TrackPoint> points) =>
      encodeLatLng([for (final p in points) (lat: p.lat, lng: p.lng)]);

  /// Wie [encode], aber ohne die uebrigen Felder eines [TrackPoint].
  ///
  /// Die Migration liest die Punkte direkt aus der Tabelle und muesste
  /// sonst Tempo, Hoehe, Genauigkeit und Zeitstempel mitschleppen, nur um
  /// sie hier wegzuwerfen.
  static String? encodeLatLng(List<LatLng> points) {
    if (points.isEmpty) return null;

    return _sample(points)
        .map((p) => '${p.lat.toStringAsFixed(_decimals)}'
            '$_partSeparator'
            '${p.lng.toStringAsFixed(_decimals)}')
        .join(_pointSeparator);
  }

  /// Liest zurueck, was [encode] geschrieben hat.
  ///
  /// Unlesbares ergibt eine leere Liste und keinen Fehler: der Wert
  /// stammt aus der Datenbank, und eine beschaedigte Zeile darf die
  /// Fahrtenliste nicht zum Absturz bringen.
  static List<LatLng> decode(String? encoded) {
    if (encoded == null || encoded.isEmpty) return const [];

    final points = <LatLng>[];
    for (final pair in encoded.split(_pointSeparator)) {
      final parts = pair.split(_partSeparator);
      if (parts.length != 2) return const [];

      final lat = double.tryParse(parts[0]);
      final lng = double.tryParse(parts[1]);
      if (lat == null || lng == null) return const [];

      points.add((lat: lat, lng: lng));
    }

    return points;
  }

  /// Waehlt bis zu [maxPoints] Punkte, gleichmaessig ueber die gefahrene
  /// **Strecke** verteilt.
  ///
  /// Nicht ueber den Index: die Punkte kommen im Sekundentakt, und eine
  /// lange Ampelphase legte damit ein Drittel aller Stuetzpunkte auf
  /// denselben Fleck -- die Form der Strecke ginge dabei verloren.
  ///
  /// Erster und letzter Punkt bleiben in jedem Fall erhalten: sie sind
  /// Anfang und Ende der Fahrt.
  static List<LatLng> _sample(List<LatLng> points) {
    if (points.length <= maxPoints) return points;

    // Aufsummierte Strecke bis zu jedem Punkt.
    final cumulative = List<double>.filled(points.length, 0);
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      cumulative[i] = cumulative[i - 1] +
          StatsEngine.haversineMeters(a.lat, a.lng, b.lat, b.lng);
    }

    final total = cumulative.last;
    // Steht alles auf einem Fleck, gibt es keine Strecke zu verteilen.
    if (total <= 0) return [points.first, points.last];

    final picked = <LatLng>[points.first];
    var cursor = 1;
    for (var k = 1; k < maxPoints - 1; k++) {
      final target = total * k / (maxPoints - 1);
      while (cursor < points.length - 1 && cumulative[cursor] < target) {
        cursor++;
      }
      // Doppelte ueberspringen: bei einem langen Halt faellt mehr als
      // ein Zielwert auf denselben Punkt.
      final next = points[cursor];
      if (picked.last != next) picked.add(next);
    }
    picked.add(points.last);

    return picked;
  }
}
