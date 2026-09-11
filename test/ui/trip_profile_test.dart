import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/app/theme.dart';
import 'package:speedster/domain/track_point.dart';
import 'package:speedster/settings/unit_system.dart';
import 'package:speedster/ui/components/trip_profile.dart';

List<TrackPoint> ride({
  int count = 30,
  double altitude = 100,
  bool climbing = false,
}) =>
    [
      for (var i = 0; i < count; i++)
        TrackPoint(
          tripId: 1,
          lat: 52.5,
          lng: 13.4,
          speed: 10 + i.toDouble(),
          altitude: climbing ? altitude + i * 2 : altitude,
          accuracy: 5,
          timestamp: DateTime(2026, 1, 1, 12).add(Duration(seconds: i)),
        ),
    ];

Future<void> pump(WidgetTester tester, List<TrackPoint> points) =>
    tester.pumpWidget(
      MaterialApp(
        theme: SpeedsterTheme.dark,
        home: Scaffold(
          body: TripProfile(points: points, unit: UnitSystem.kmh),
        ),
      ),
    );

void main() {
  test('unter zwei Punkten gibt es keinen Verlauf', () {
    expect(TripProfile.worthShowing(const []), isFalse);
    expect(TripProfile.worthShowing(ride(count: 1)), isFalse);
    expect(TripProfile.worthShowing(ride(count: 2)), isTrue);
  });

  testWidgets('zeichnet den Tempoverlauf', (tester) async {
    await pump(tester, ride());

    expect(find.byType(CustomPaint), findsWidgets);
    // Der Hoechstwert steht als Beschriftung darueber: 39 m/s = 140 km/h.
    expect(find.text('140 km/h'), findsOneWidget);
  });

  testWidgets('laesst den Hoehenverlauf weg, wenn es flach war',
      (tester) async {
    // Ein Strich auf halber Hoehe waere keine Auskunft, sondern Zierat.
    await pump(tester, ride());

    expect(find.textContaining('Δ'), findsNothing);
  });

  testWidgets('zeigt den Hoehenverlauf, sobald es hoch geht', (tester) async {
    await pump(tester, ride(climbing: true));

    expect(find.textContaining('Δ'), findsOneWidget);
  });

  testWidgets('Messungen in derselben Millisekunde stuerzen nicht ab',
      (tester) async {
    // Ohne Zeitspanne gibt es keine Waagerechte, ueber die sich etwas
    // auftragen liesse -- der Maler muss das aushalten.
    final frozen = [
      for (var i = 0; i < 5; i++)
        TrackPoint(
          tripId: 1,
          lat: 52.5,
          lng: 13.4,
          speed: 10,
          altitude: 100,
          accuracy: 5,
          timestamp: DateTime(2026, 1, 1, 12),
        ),
    ];

    await pump(tester, frozen);

    expect(tester.takeException(), isNull);
  });
}
