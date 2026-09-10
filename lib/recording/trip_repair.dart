import 'package:speedster/data/trip_repository.dart';
import 'package:speedster/domain/route_preview.dart';
import 'package:speedster/stats/stats_engine.dart';

/// Rechnet Fahrten nach, die angelegt, aber nie abgeschlossen wurden.
///
/// Eine Fahrt entsteht beim Beginn mit lauter Nullen und ohne Endzeit;
/// die Kennzahlen schreibt erst `TripRecorder` am Fahrtende. Stirbt der
/// Prozess dazwischen -- iOS beendet die App nach dem Parken, ein
/// Absturz, ein Wegwischen --, laeuft diese Stelle nie, und die Zeile
/// bleibt so stehen, wie sie angelegt wurde.
///
/// Verloren ist dabei nichts: die Punkte schreibt der Rekorder waehrend
/// der Fahrt alle paar Messungen weg (siehe `TripRecorder.flushEvery`).
/// Die Kennzahlen sind reine Ableitungen daraus -- genau dieselbe
/// Rechnung wie am Fahrtende, nur spaeter.
///
/// Laeuft **beim Start der App**, bevor die Aufzeichnung scharf gemacht
/// wird: dann ist jede offene Fahrt zwangslaeufig eine Leiche, und es
/// gibt kein Rennen mit einer gerade laufenden.
class TripRepair {
  const TripRepair(this.repo);

  final TripRepository repo;

  /// Unterhalb von zwei Punkten gibt es keine Strecke, keine Dauer und
  /// kein Tempo -- nur einen Startpunkt. Solche Fahrten bleiben offen
  /// liegen: die Filter in `keptTrips` und `unsyncedTrips` halten sie aus
  /// Liste und Cloud heraus, und geloescht wird nichts, was sich nicht
  /// zweifelsfrei als wertlos erweist.
  static const int minPoints = 2;

  /// Gibt zurueck, wie viele Fahrten nachgerechnet wurden.
  Future<int> run() async {
    var repaired = 0;

    for (final trip in await repo.openTrips()) {
      final id = trip.id;
      if (id == null) continue;

      final points = await repo.pointsFor(id);
      if (points.length < minPoints) continue;

      await repo.finalizeTrip(
        id,
        StatsEngine.compute(points),
        // Die Endzeit ist der letzte Punkt, den die Fahrt erreicht hat --
        // nicht der Zeitpunkt der Reparatur. Der laege je nach dem, wann
        // die App das naechste Mal geoeffnet wird, Stunden oder Tage
        // spaeter und machte aus einer halben Stunde eine halbe Woche.
        points.last.timestamp,
        // Das Fahrzeug bleibt, wie es war. Das aktuelle Standardfahrzeug
        // einzusetzen waere eine Behauptung ueber die Vergangenheit --
        // dieselbe Ueberlegung wie beim Fahrtende.
        cloudVehicleId: trip.cloudVehicleId,
        routePreview: RoutePreview.encode(points),
      );

      repaired++;
    }

    return repaired;
  }
}
