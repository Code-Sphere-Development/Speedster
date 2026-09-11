import 'package:speedster/domain/route_preview.dart';
import 'package:speedster/domain/trip.dart';
import 'package:speedster/stats/stats_engine.dart';

/// Eine Strecke, die mehrfach gefahren wurde.
class RecurringRoute {
  RecurringRoute({required this.trips});

  /// Absteigend nach Startzeit, wie sie hereinkamen.
  final List<Trip> trips;

  int get count => trips.length;

  /// Die uebliche Dauer: der Median, nicht der Mittelwert.
  ///
  /// Ein einziger Stau zoege den Mittelwert so weit hoch, dass danach
  /// jede gewoehnliche Fahrt "schneller als ueblich" waere.
  int get typicalSeconds => _median(
        trips.map((t) => t.durationSeconds).toList()..sort(),
      );

  /// Wie viele Sekunden [trip] schneller war als ueblich. Negativ heisst
  /// langsamer.
  ///
  /// Verglichen wird gegen die **uebrigen** Fahrten: sonst zoege eine
  /// Fahrt ihren eigenen Massstab mit sich, und bei drei Fahrten waere
  /// die mittlere immer exakt durchschnittlich.
  int? fasterThanUsual(Trip trip) {
    final others = [
      for (final t in trips)
        if (t.clientUuid != trip.clientUuid) t.durationSeconds,
    ]..sort();

    if (others.length < RecurringRoutes.minTrips - 1) return null;

    return _median(others) - trip.durationSeconds;
  }

  static int _median(List<int> sorted) {
    if (sorted.isEmpty) return 0;
    final middle = sorted.length ~/ 2;

    return sorted.length.isOdd
        ? sorted[middle]
        : ((sorted[middle - 1] + sorted[middle]) / 2).round();
  }
}

/// Erkennt Fahrten, die man immer wieder macht.
///
/// Verglichen werden Anfang und Ende, nicht der Weg dazwischen: zwei
/// Fahrten zur Arbeit sind dieselbe Strecke, auch wenn eine davon einen
/// Umweg genommen hat.
///
/// **Ueber den Abstand und nicht ueber die Rasterzelle**, obwohl die App
/// eine hat (`HeatGrid`): wer fuenfzig Meter weiter parkt, landet je nach
/// Zellgrenze in einer anderen Zelle, und dieselbe Strecke zerfiele in
/// zwei Gruppen. Der Abstand kennt keine Grenzen.
abstract final class RecurringRoutes {
  /// Wie nah Anfang und Ende beieinanderliegen muessen. Grosszuegig
  /// genug fuer einen anderen Parkplatz, eng genug, um Nachbarstrassen
  /// auseinanderzuhalten.
  static const double radiusMeters = 300;

  /// Ab wann es eine Gewohnheit ist und kein Zufall.
  static const int minTrips = 3;

  /// Wie stark die Strecke abweichen darf. Wer auf dem Rueckweg noch
  /// einkaufen faehrt, faehrt nicht mehr dieselbe Strecke.
  static const double distanceTolerance = 0.25;

  /// Alle wiederkehrenden Strecken, die haeufigste zuerst.
  static List<RecurringRoute> from(List<Trip> trips) {
    final groups = <List<Trip>>[];

    for (final trip in trips) {
      final ends = _endsOf(trip);
      if (ends == null) continue;

      final match = groups.firstWhere(
        (group) => _matches(group.first, trip),
        orElse: () => <Trip>[],
      );

      if (match.isEmpty) {
        groups.add([trip]);
      } else {
        match.add(trip);
      }
    }

    final routes = [
      for (final group in groups)
        if (group.length >= minTrips) RecurringRoute(trips: group),
    ]..sort((a, b) => b.count.compareTo(a.count));

    return routes;
  }

  /// Die Strecke, zu der [trip] gehoert -- oder `null`, wenn er sie
  /// bisher zu selten gefahren ist.
  static RecurringRoute? forTrip(List<Trip> all, Trip trip) {
    if (_endsOf(trip) == null) return null;

    for (final route in from(all)) {
      if (route.trips.any((t) => t.clientUuid == trip.clientUuid)) {
        return route;
      }
    }

    return null;
  }

  static bool _matches(Trip a, Trip b) {
    final first = _endsOf(a);
    final second = _endsOf(b);
    if (first == null || second == null) return false;

    final longer = a.distance > b.distance ? a.distance : b.distance;
    if (longer > 0 &&
        (a.distance - b.distance).abs() / longer > distanceTolerance) {
      return false;
    }

    return _near(first.start, second.start) && _near(first.end, second.end);
  }

  static bool _near(LatLng a, LatLng b) =>
      StatsEngine.haversineMeters(a.lat, a.lng, b.lat, b.lng) <= radiusMeters;

  /// Anfang und Ende aus der gespeicherten Streckenvorschau.
  ///
  /// Fahrten von einem anderen Geraet tragen keine und bleiben damit
  /// aussen vor -- erfinden laesst sich der Weg nicht.
  static ({LatLng start, LatLng end})? _endsOf(Trip trip) {
    final points = RoutePreview.decode(trip.routePreview);
    if (points.length < 2) return null;

    return (start: points.first, end: points.last);
  }
}
