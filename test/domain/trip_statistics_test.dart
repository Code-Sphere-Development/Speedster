import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/domain/trip.dart';
import 'package:speedster/domain/trip_statistics.dart';

Trip trip({
  required DateTime start,
  double distance = 1000,
  double maxSpeed = 20,
  int seconds = 600,
  double? sprint,
  String? purpose,
}) =>
    Trip(
      startTime: start,
      endTime: start.add(Duration(seconds: seconds)),
      maxSpeed: maxSpeed,
      avgSpeed: 10,
      distance: distance,
      elevationGain: 0,
      durationSeconds: seconds,
      zeroToHundredSeconds: sprint,
      kept: true,
      purpose: purpose,
    );

final now = DateTime(2026, 8, 20, 12);

void main() {
  test('ohne Fahrten bleibt alles leer', () {
    final stats = TripStatistics.of(const [], now);

    expect(stats.isEmpty, isTrue);
    expect(stats.longest, isNull);
    expect(stats.byWeekday, hasLength(7));
  });

  test('summiert nach Kalender, nicht nach gleitendem Fenster', () {
    // "Diesen Monat" heisst seit dem Ersten. Ein gleitendes Fenster laege
    // am Monatsanfang jedes Mal ueberraschend hoch.
    final stats = TripStatistics.of([
      trip(start: DateTime(2026, 8, 2), distance: 1000),
      trip(start: DateTime(2026, 7, 30), distance: 2000),
      trip(start: DateTime(2025, 8, 2), distance: 4000),
    ], now);

    expect(stats.month.distance, 1000);
    expect(stats.month.trips, 1);
    expect(stats.year.distance, 3000);
    expect(stats.total.distance, 7000);
    expect(stats.total.trips, 3);
  });

  test('findet die laengste und die schnellste Fahrt', () {
    final long = trip(start: DateTime(2026, 8, 1), distance: 90000);
    final fast = trip(start: DateTime(2026, 8, 2), maxSpeed: 60);

    final stats = TripStatistics.of([long, fast], now);

    expect(stats.longest?.value, 90000);
    expect(stats.longest?.trip.startTime, long.startTime);
    expect(stats.fastest?.value, 60);
    expect(stats.fastest?.trip.startTime, fast.startTime);
  });

  test('beim Sprint gewinnt der kleinste Wert', () {
    final stats = TripStatistics.of([
      trip(start: DateTime(2026, 8, 1), sprint: 8.2),
      trip(start: DateTime(2026, 8, 2), sprint: 6.4),
      trip(start: DateTime(2026, 8, 3)),
    ], now);

    expect(stats.quickestSprint?.value, 6.4);
  });

  test('ohne erreichte Marke gibt es keinen Sprintrekord', () {
    final stats = TripStatistics.of([trip(start: DateTime(2026, 8, 1))], now);

    expect(stats.quickestSprint, isNull);
  });

  test('zaehlt Fahrten desselben Tages zusammen', () {
    // Der Rekord ist der Tag, nicht die einzelne Fahrt.
    final stats = TripStatistics.of([
      trip(start: DateTime(2026, 8, 5, 8), distance: 30000),
      trip(start: DateTime(2026, 8, 5, 18), distance: 30000),
      trip(start: DateTime(2026, 8, 6, 9), distance: 50000),
    ], now);

    expect(stats.busiestDay?.day, DateTime(2026, 8, 5));
    expect(stats.busiestDay?.distance, 60000);
  });

  test('verteilt auf Wochentage, Montag zuerst', () {
    // Der 3. August 2026 war ein Montag, der 9. ein Sonntag.
    final stats = TripStatistics.of([
      trip(start: DateTime(2026, 8, 3), distance: 1000),
      trip(start: DateTime(2026, 8, 9), distance: 5000),
    ], now);

    expect(stats.byWeekday.first, 1000);
    expect(stats.byWeekday.last, 5000);
  });

  test('gruppiert nach Zweck, ohne Zweck als eigener Schluessel', () {
    final stats = TripStatistics.of([
      trip(start: DateTime(2026, 8, 3), distance: 1000, purpose: 'commute'),
      trip(start: DateTime(2026, 8, 4), distance: 2000, purpose: 'commute'),
      trip(start: DateTime(2026, 8, 5), distance: 500),
    ], now);

    expect(stats.byPurpose['commute'], 3000);
    expect(stats.byPurpose[null], 500);
  });
}
