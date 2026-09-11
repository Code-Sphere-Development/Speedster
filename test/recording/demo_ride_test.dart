import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/recording/demo_ride.dart';

void main() {
  test('die Vorschau faehrt immer', () {
    // Ohne das erschiene der Live-Reiter nicht: die Leiste blendet ihn
    // aus, solange nicht gefahren wird.
    expect(DemoRide.stateAt(0).isDriving, isTrue);
    expect(DemoRide.stateAt(50).isDriving, isTrue);
  });

  test('das Tempo laeuft ueber die ganze Skala', () {
    // Sonst saehe man den Bogen nur bei einem Wert.
    final speeds = [for (var i = 0; i < 90; i++) DemoRide.speedAt(i)];

    expect(speeds.reduce((a, b) => a < b ? a : b), lessThan(5));
    expect(speeds.reduce((a, b) => a > b ? a : b), greaterThan(30));
  });

  test('Tempo wird nie negativ', () {
    for (var i = 0; i < 200; i++) {
      expect(DemoRide.speedAt(i), greaterThanOrEqualTo(0));
    }
  });

  test('Strecke und Dauer wachsen', () {
    final early = DemoRide.stateAt(10);
    final late = DemoRide.stateAt(60);

    expect(late.distanceMeters, greaterThan(early.distanceMeters));
    expect(late.elapsedSeconds, greaterThan(early.elapsedSeconds));
  });

  test('der Verlauf wiederholt sich', () {
    // Eine Runde ist neunzig Schritte; danach faengt es von vorn an.
    expect(DemoRide.speedAt(5), closeTo(DemoRide.speedAt(95), 0.0001));
  });
}
