import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/domain/recurring_routes.dart';
import 'package:speedster/domain/trip.dart';

/// Baut eine Fahrt mit gespeicherter Streckenvorschau.
Trip trip({
  required String uuid,
  required double startLat,
  required double endLat,
  double startLng = 13.4,
  double endLng = 13.5,
  int seconds = 1800,
  double distance = 20000,
}) =>
    Trip(
      startTime: DateTime(2026, 8, 1),
      endTime: DateTime(2026, 8, 1).add(Duration(seconds: seconds)),
      maxSpeed: 30,
      avgSpeed: 15,
      distance: distance,
      elevationGain: 0,
      durationSeconds: seconds,
      zeroToHundredSeconds: null,
      kept: true,
      clientUuid: uuid,
      routePreview: '${startLat.toStringAsFixed(5)},'
          '${startLng.toStringAsFixed(5)};'
          '${endLat.toStringAsFixed(5)},${endLng.toStringAsFixed(5)}',
    );

List<Trip> commute(int count, {List<int>? seconds}) => [
      for (var i = 0; i < count; i++)
        trip(
          uuid: 'c$i',
          startLat: 52.5,
          endLat: 52.6,
          seconds: seconds == null ? 1800 : seconds[i],
        ),
    ];

void main() {
  test('unter drei Fahrten ist es Zufall, keine Gewohnheit', () {
    expect(RecurringRoutes.from(commute(2)), isEmpty);
    expect(RecurringRoutes.from(commute(3)), hasLength(1));
  });

  test('ein anderer Parkplatz zaehlt noch als dieselbe Strecke', () {
    // Ueber den Abstand und nicht ueber die Rasterzelle: fuenfzig Meter
    // weiter kann die Zelle wechseln, die Strecke nicht.
    final trips = [
      ...commute(2),
      // Rund 110 Meter weiter noerdlich.
      trip(uuid: 'x', startLat: 52.501, endLat: 52.6),
    ];

    expect(RecurringRoutes.from(trips), hasLength(1));
    expect(RecurringRoutes.from(trips).single.count, 3);
  });

  test('ein anderes Ziel ist eine andere Strecke', () {
    final trips = [...commute(3), ...[
      for (var i = 0; i < 3; i++)
        trip(uuid: 'w$i', startLat: 52.5, endLat: 53.4),
    ]];

    final routes = RecurringRoutes.from(trips);
    expect(routes, hasLength(2));
  });

  test('die Gegenrichtung ist eine eigene Strecke', () {
    // Hin und zurueck sind nicht dasselbe -- schon weil die Dauer
    // morgens und abends verschieden ausfaellt.
    final trips = [
      ...commute(3),
      for (var i = 0; i < 3; i++)
        trip(uuid: 'r$i', startLat: 52.6, endLat: 52.5),
    ];

    expect(RecurringRoutes.from(trips), hasLength(2));
  });

  test('ein Umweg zaehlt nicht mehr dazu', () {
    final trips = [
      ...commute(3),
      trip(uuid: 'u', startLat: 52.5, endLat: 52.6, distance: 40000),
    ];

    expect(RecurringRoutes.from(trips).single.count, 3);
  });

  test('Fahrten ohne Streckenvorschau bleiben aussen vor', () {
    // Sie stammen von einem anderen Geraet; der Weg laesst sich nicht
    // erfinden.
    final without = Trip(
      startTime: DateTime(2026, 8, 1),
      endTime: DateTime(2026, 8, 1),
      maxSpeed: 30,
      avgSpeed: 15,
      distance: 20000,
      elevationGain: 0,
      durationSeconds: 1800,
      zeroToHundredSeconds: null,
      kept: true,
      clientUuid: 'leer',
    );

    expect(RecurringRoutes.from([...commute(3), without]).single.count, 3);
  });

  test('die uebliche Dauer ist der Median, nicht der Mittelwert', () {
    // Ein einziger Stau zoege den Mittelwert so weit hoch, dass danach
    // jede gewoehnliche Fahrt "schneller als ueblich" waere.
    final route = RecurringRoutes.from(
      commute(5, seconds: [1800, 1810, 1790, 1805, 7200]),
    ).single;

    expect(route.typicalSeconds, 1805);
  });

  test('vergleicht gegen die uebrigen, nicht gegen sich selbst', () {
    final trips = commute(5, seconds: [1500, 1800, 1800, 1800, 1800]);
    final route = RecurringRoutes.from(trips).single;

    // Die schnelle Fahrt liegt 300 s unter dem Median der anderen vier.
    expect(route.fasterThanUsual(trips.first), 300);
  });

  test('ohne genug Vergleichsfahrten gibt es kein Urteil', () {
    final trips = commute(3);
    final route = RecurringRoutes.from(trips).single;

    // Zwei uebrige reichen -- eine allein nicht.
    expect(route.fasterThanUsual(trips.first), isNotNull);

    final short = RecurringRoutes.from(commute(3)).single;
    expect(short.trips, hasLength(3));
  });

  test('forTrip findet die Strecke einer bestimmten Fahrt', () {
    final trips = commute(4);

    final route = RecurringRoutes.forTrip(trips, trips[1]);
    expect(route?.count, 4);

    final lonely = trip(uuid: 'einzeln', startLat: 48.1, endLat: 48.2);
    expect(RecurringRoutes.forTrip([...trips, lonely], lonely), isNull);
  });
}
