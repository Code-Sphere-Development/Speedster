import 'package:speedster/domain/trip.dart';

/// Rekord samt der Fahrt, die ihn haelt.
class TripRecord {
  const TripRecord({required this.trip, required this.value});

  final Trip trip;

  /// In der Einheit der jeweiligen Kennzahl -- Meter, m/s oder Sekunden.
  final double value;
}

/// Was sich aus den eigenen Fahrten ablesen laesst.
///
/// Rein gerechnet und ohne Netz: die Fahrtenliste liegt vollstaendig vor
/// (CloudTripSource blaettert alle Seiten durch), und dieselben Zahlen ein
/// zweites Mal am Server zu fuehren hiesse, zwei Wahrheiten zu pflegen.
///
/// Anders als die Bestenliste braucht das hier **kein Konto**: es
/// vergleicht nur mit einem selbst.
class TripStatistics {
  const TripStatistics({
    required this.month,
    required this.year,
    required this.total,
    required this.longest,
    required this.fastest,
    required this.quickestSprint,
    required this.busiestDay,
    required this.byWeekday,
    required this.byPurpose,
  });

  final TripSpan month;
  final TripSpan year;
  final TripSpan total;

  final TripRecord? longest;
  final TripRecord? fastest;
  final TripRecord? quickestSprint;

  /// Der Tag mit den meisten Kilometern, samt dieser Summe in Metern.
  final ({DateTime day, double distance})? busiestDay;

  /// Strecke je Wochentag, Montag zuerst. Immer sieben Eintraege.
  final List<double> byWeekday;

  /// Strecke je Zweck. `null` steht fuer Fahrten ohne Zweck und ist ein
  /// gueltiger Schluessel, kein fehlender Wert.
  final Map<String?, double> byPurpose;

  static const empty = TripStatistics(
    month: TripSpan.empty,
    year: TripSpan.empty,
    total: TripSpan.empty,
    longest: null,
    fastest: null,
    quickestSprint: null,
    busiestDay: null,
    byWeekday: [0, 0, 0, 0, 0, 0, 0],
    byPurpose: {},
  );

  bool get isEmpty => total.trips == 0;

  factory TripStatistics.of(List<Trip> trips, DateTime now) {
    if (trips.isEmpty) return empty;

    var month = TripSpan.empty;
    var year = TripSpan.empty;
    var total = TripSpan.empty;

    TripRecord? longest;
    TripRecord? fastest;
    TripRecord? quickestSprint;

    final byWeekday = List<double>.filled(7, 0);
    final byPurpose = <String?, double>{};
    final perDay = <DateTime, double>{};

    for (final trip in trips) {
      total = total.plus(trip);
      if (trip.startTime.year == now.year) {
        year = year.plus(trip);
        if (trip.startTime.month == now.month) month = month.plus(trip);
      }

      // DateTime.weekday ist 1..7 ab Montag.
      byWeekday[trip.startTime.weekday - 1] += trip.distance;
      byPurpose[trip.purpose] = (byPurpose[trip.purpose] ?? 0) + trip.distance;

      final day = DateTime(
        trip.startTime.year,
        trip.startTime.month,
        trip.startTime.day,
      );
      perDay[day] = (perDay[day] ?? 0) + trip.distance;

      if (longest == null || trip.distance > longest.value) {
        longest = TripRecord(trip: trip, value: trip.distance);
      }
      if (fastest == null || trip.maxSpeed > fastest.value) {
        fastest = TripRecord(trip: trip, value: trip.maxSpeed);
      }

      // Beim Sprint gewinnt der *kleinste* Wert -- und nur Fahrten, die
      // die Marke ueberhaupt erreicht haben, zaehlen mit.
      final sprint = trip.zeroToHundredSeconds;
      if (sprint != null &&
          (quickestSprint == null || sprint < quickestSprint.value)) {
        quickestSprint = TripRecord(trip: trip, value: sprint);
      }
    }

    ({DateTime day, double distance})? busiest;
    for (final entry in perDay.entries) {
      if (busiest == null || entry.value > busiest.distance) {
        busiest = (day: entry.key, distance: entry.value);
      }
    }

    return TripStatistics(
      month: month,
      year: year,
      total: total,
      longest: longest,
      fastest: fastest,
      quickestSprint: quickestSprint,
      busiestDay: busiest,
      byWeekday: byWeekday,
      byPurpose: byPurpose,
    );
  }
}

/// Summen ueber einen Zeitraum.
class TripSpan {
  const TripSpan({
    required this.distance,
    required this.trips,
    required this.seconds,
  });

  /// Meter, wie ueberall in dieser App.
  final double distance;
  final int trips;
  final int seconds;

  static const empty = TripSpan(distance: 0, trips: 0, seconds: 0);

  TripSpan plus(Trip trip) => TripSpan(
        distance: distance + trip.distance,
        trips: trips + 1,
        seconds: seconds + trip.durationSeconds,
      );
}
