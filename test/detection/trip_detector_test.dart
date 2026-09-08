import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/detection/trip_detector.dart';
import 'package:speedster/domain/sample.dart';

Sample mv(double speed, int sec, {double acc = 5}) => Sample(
      lat: 50,
      lng: 6,
      speed: speed,
      altitude: 100,
      accuracy: acc,
      timestamp: DateTime(2026, 1, 1, 12, 0, sec),
    );

void main() {
  test('emits started after sustained motion over startWindow', () {
    final d = TripDetector(const DetectorConfig());
    expect(d.update(mv(10, 0)), isNull); // moving begins
    expect(d.update(mv(10, 3)), isNull); // still within window
    expect(d.update(mv(10, 6)), TripEvent.started); // window elapsed
    expect(d.isDriving, isTrue);
  });

  test('brief stop under stopWindow does not end trip', () {
    final d = TripDetector(const DetectorConfig());
    d
      ..update(mv(10, 0))
      ..update(mv(10, 6)); // driving
    expect(d.update(mv(0, 10)), isNull); // red light
    expect(d.update(mv(10, 20)), isNull); // moving again
    expect(d.isDriving, isTrue);
  });

  test('emits stopped after stopWindow of stillness', () {
    final d = TripDetector(const DetectorConfig());
    d
      ..update(mv(10, 0))
      ..update(mv(10, 6));
    expect(d.update(mv(0, 10)), isNull);
    expect(d.update(mv(0, 75)), TripEvent.stopped); // >60s still
    expect(d.isDriving, isFalse);
  });

  test('ignores low-accuracy samples', () {
    final d = TripDetector(const DetectorConfig());
    expect(d.update(mv(10, 0, acc: 100)), isNull);
    expect(d.update(mv(10, 6, acc: 100)), isNull);
    expect(d.isDriving, isFalse);
  });

  group('Auto-Verbindung', () {
    TripDetector driving() {
      final d = TripDetector(const DetectorConfig())
        ..update(mv(10, 0))
        ..update(mv(10, 6));
      expect(d.isDriving, isTrue);

      return d;
    }

    test('beendet die Fahrt nicht, solange das Auto verbunden ist', () {
      final d = driving()..carConnected = true;

      // Ampel, Stau, Tankstelle: der Nutzer sitzt nachweislich im Auto.
      // Ohne diese Unterdrueckung zaehlte der Rest der Fahrt als neue.
      expect(d.update(mv(0, 10)), isNull);
      expect(d.update(mv(0, 300)), isNull);
      expect(d.isDriving, isTrue);
    });

    test('beendet sie nach dem Abbruch, sobald das Fenster voll ist', () {
      final d = driving()..carConnected = true;
      d.update(mv(0, 10));

      d.carConnected = false;
      expect(d.update(mv(0, 20)), isNull);
      expect(d.update(mv(0, 85)), TripEvent.stopped);
    });

    test('zaehlt die Standzeit nach dem Abbruch neu, nicht von vorher', () {
      final d = driving()..carConnected = true;
      // Fuenf Minuten im Stau, verbunden.
      d.update(mv(0, 300));

      d.carConnected = false;
      // Waere das alte Fenster weitergelaufen, endete die Fahrt sofort.
      expect(d.update(mv(0, 305)), isNull);
      expect(d.update(mv(0, 350)), isNull);
      expect(d.update(mv(0, 370)), TripEvent.stopped);
    });

    test('verwirft ein laufendes Stopp-Fenster beim Wiederverbinden', () {
      final d = driving();
      d.update(mv(0, 10));

      // Kurzer Abbruch im Tunnel, danach wieder verbunden: die Standzeit
      // von vorher darf nicht weiterzaehlen.
      d.carConnected = true;
      d.carConnected = false;
      expect(d.update(mv(0, 60)), isNull);
      expect(d.update(mv(0, 125)), TripEvent.stopped);
    });

    test('beginnt von sich aus keine Fahrt', () {
      final d = TripDetector(const DetectorConfig())..carConnected = true;

      // Verbinden in der Einfahrt darf keine Fahrt anlegen -- die
      // Standzeit vor dem Losfahren drueckte sonst den Durchschnitt.
      expect(d.update(mv(0, 0)), isNull);
      expect(d.update(mv(0, 120)), isNull);
      expect(d.isDriving, isFalse);

      // Losgefahren wird weiterhin ueber die Geschwindigkeit erkannt.
      d.update(mv(10, 130));
      expect(d.update(mv(10, 136)), TripEvent.started);
    });
  });
}
