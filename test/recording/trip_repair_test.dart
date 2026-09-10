import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/data/database.dart' show AppDatabase;
import 'package:speedster/data/trip_repository.dart';
import 'package:speedster/domain/route_preview.dart';
import 'package:speedster/domain/track_point.dart';
import 'package:speedster/domain/trip.dart';
import 'package:speedster/recording/trip_repair.dart';

Trip openTrip() => Trip(
      startTime: DateTime(2026, 1, 1, 12),
      endTime: null,
      maxSpeed: 0,
      avgSpeed: 0,
      distance: 0,
      elevationGain: 0,
      durationSeconds: 0,
      zeroToHundredSeconds: null,
      kept: true,
    );

/// Eine Fahrt geradeaus nach Norden, ein Punkt je Sekunde.
List<TrackPoint> route(int tripId, int count) => [
      for (var i = 0; i < count; i++)
        TrackPoint(
          tripId: tripId,
          lat: 52.5 + i * 0.001,
          lng: 13.4,
          speed: 20,
          altitude: 100,
          accuracy: 5,
          timestamp: DateTime(2026, 1, 1, 12).add(Duration(seconds: i)),
        ),
    ];

void main() {
  late AppDatabase db;
  late DriftTripRepository repo;
  late TripRepair repair;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftTripRepository(db);
    repair = TripRepair(repo);
  });
  tearDown(() => db.close());

  test('rechnet eine abgebrochene Fahrt aus ihren Punkten nach', () async {
    // Der eigentliche Fall: die App wurde nach dem Parken beendet, bevor
    // die Fahrterkennung das Ende meldete. Die Punkte liegen aber
    // laengst auf der Platte.
    final id = await repo.createTrip(openTrip());
    await repo.addPoints(id, route(id, 60));

    expect(await repair.run(), 1);

    final trip = (await repo.keptTrips()).single;
    expect(trip.distance, greaterThan(6000));
    expect(trip.maxSpeed, 20);
    expect(trip.durationSeconds, 59);
  });

  test('setzt die Endzeit auf den letzten Punkt, nicht auf jetzt', () async {
    // Die Reparatur laeuft, wann die App das naechste Mal geoeffnet wird
    // -- Stunden oder Tage spaeter. Aus einer halben Stunde wuerde sonst
    // eine halbe Woche.
    final id = await repo.createTrip(openTrip());
    await repo.addPoints(id, route(id, 60));

    await repair.run();

    expect(
      (await repo.keptTrips()).single.endTime,
      DateTime(2026, 1, 1, 12, 0, 59),
    );
  });

  test('traegt auch die Streckenvorschau nach', () async {
    final id = await repo.createTrip(openTrip());
    await repo.addPoints(id, route(id, 60));

    await repair.run();

    final preview = (await repo.keptTrips()).single.routePreview;
    expect(RoutePreview.decode(preview).length, greaterThan(1));
  });

  test('schickt die Korrektur erneut in die Cloud', () async {
    // Vor dem Upload lag die Fahrt mit Nullen dort; ohne das
    // Zuruecksetzen des Stempels blieben sie stehen.
    final id = await repo.createTrip(openTrip());
    await repo.addPoints(id, route(id, 60));
    await repo.markSynced((await repo.openTrips()).single.clientUuid);
    expect(await repo.unsyncedTrips(), isEmpty);

    await repair.run();

    expect(await repo.unsyncedTrips(), hasLength(1));
  });

  test('laesst eine Fahrt ohne Punkte liegen', () async {
    // Aus einem einzigen Startpunkt laesst sich weder Strecke noch Dauer
    // noch Tempo gewinnen. Geloescht wird nichts.
    final id = await repo.createTrip(openTrip());
    await repo.addPoints(id, route(id, 1));

    expect(await repair.run(), 0);
    expect(await repo.openTrips(), hasLength(1));
    expect(await repo.keptTrips(), isEmpty);
  });

  test('fasst abgeschlossene Fahrten nicht an', () async {
    final id = await repo.createTrip(
      openTrip().copyWith(endTime: DateTime(2026, 1, 1, 12, 30)),
    );
    await repo.addPoints(id, route(id, 60));

    expect(await repair.run(), 0);
  });
}
