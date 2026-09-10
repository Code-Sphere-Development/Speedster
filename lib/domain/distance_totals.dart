import 'package:speedster/domain/trip.dart';

/// Gefahrene Strecke im laufenden Monat und im laufenden Jahr.
///
/// Die beiden Zahlen im Kopfbereich der App. Sie stehen dort und sonst
/// nirgends -- die Fahrtenliste nennt Einzelfahrten, die Summe daneben
/// beantwortet eine andere Frage.
class DistanceTotals {
  const DistanceTotals({required this.month, required this.year});

  /// Meter, wie ueberall in dieser App.
  final double month;
  final double year;

  static const empty = DistanceTotals(month: 0, year: 0);

  /// Summiert nach dem Kalender, nicht nach den letzten 30 bzw. 365
  /// Tagen: "diesen Monat" heisst seit dem Ersten, und ein gleitendes
  /// Fenster laege am Monatsanfang jedes Mal ueberraschend hoch.
  ///
  /// [now] kommt von aussen, damit die Rechnung ohne Uhr pruefbar ist.
  factory DistanceTotals.of(List<Trip> trips, DateTime now) {
    var month = 0.0;
    var year = 0.0;

    for (final trip in trips) {
      if (trip.startTime.year != now.year) continue;
      year += trip.distance;
      if (trip.startTime.month == now.month) month += trip.distance;
    }

    return DistanceTotals(month: month, year: year);
  }
}
