import 'dart:math' as math;

import 'package:speedster/domain/sample.dart';
import 'package:speedster/recording/trip_recorder.dart';

/// Eine erfundene Fahrt fuer die Vorschau der Live-Ansicht.
///
/// Damit sich der Tacho ansehen laesst, ohne dafuer loszufahren. Sie
/// speist **nur die Anzeige**: der Rekorder bekommt davon nichts mit, es
/// wird keine Fahrt angelegt und nichts hochgeladen.
///
/// Der Verlauf ist derselbe, den eine Fahrt auch sonst nimmt -- anfahren,
/// Landstrasse, Ortsdurchfahrt, Autobahn --, damit man den Bogen ueber
/// seine ganze Laenge sieht und nicht nur bei einem Wert.
abstract final class DemoRide {
  /// Wie oft ein neuer Wert kommt. Nah an dem, was GPS liefert.
  static const tick = Duration(milliseconds: 400);

  /// Eine volle Runde durch den Verlauf.
  static const _period = 90;

  static Stream<RecorderState> stream() =>
      Stream<int>.periodic(tick, (i) => i).map(stateAt);

  /// Der Zustand nach [step] Schritten.
  ///
  /// Ausgelagert und ohne Uhr, damit sich der Verlauf ohne Warten pruefen
  /// laesst.
  static RecorderState stateAt(int step) {
    final seconds = (step * tick.inMilliseconds / 1000).round();
    final speed = speedAt(step);

    return RecorderState(
      isDriving: true,
      activeTripId: -1,
      last: Sample(
        lat: 52.5,
        lng: 13.4,
        speed: speed,
        altitude: 100,
        accuracy: 5,
        // Ohne echte Uhr: der Zeitstempel muss nur monoton sein.
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          step * tick.inMilliseconds,
        ),
      ),
      // Grob aus dem Tempo aufsummiert -- genau genug fuer eine Vorschau.
      distanceMeters: _distanceAfter(step),
      elapsedSeconds: seconds,
    );
  }

  /// Tempo in m/s, als weicher Verlauf ueber eine Runde.
  static double speedAt(int step) {
    final phase = (step % _period) / _period;
    // Zwei ueberlagerte Wellen: eine lange fuer den Grundverlauf, eine
    // kurze fuer das Auf und Ab dazwischen.
    final base = math.sin(phase * 2 * math.pi - math.pi / 2) * 0.5 + 0.5;
    final ripple = math.sin(phase * 8 * math.pi) * 0.06;

    // Bis rund 145 km/h -- weit genug, um den Bogen auf die zweite
    // Skalenstufe springen zu sehen.
    return math.max(0, (base + ripple) * 40);
  }

  static double _distanceAfter(int step) {
    var metres = 0.0;
    for (var i = 0; i < step; i++) {
      metres += speedAt(i) * tick.inMilliseconds / 1000;
    }

    return metres;
  }
}
