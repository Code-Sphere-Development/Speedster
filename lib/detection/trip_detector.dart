import 'package:speedster/domain/sample.dart';

enum TripEvent { started, stopped }

/// Tunable thresholds for drive detection. Defaults in SI (m/s).
class DetectorConfig {
  const DetectorConfig({
    this.startSpeed = 2.8, // ~10 km/h
    this.stopSpeed = 0.8, // ~3 km/h
    this.startWindow = const Duration(seconds: 5),
    this.stopWindow = const Duration(seconds: 60),
    this.minAccuracy = 30,
  });

  final double startSpeed;
  final double stopSpeed;
  final Duration startWindow;
  final Duration stopWindow;

  /// Samples with accuracy worse (larger) than this are ignored.
  final double minAccuracy;
}

/// Pure state machine turning a stream of [Sample]s into trip lifecycle events.
/// No I/O — driven entirely by sample timestamps, so fully unit-testable.
class TripDetector {
  TripDetector(this.config);

  final DetectorConfig config;

  bool _driving = false;
  DateTime? _movingSince;
  DateTime? _stillSince;
  bool _carConnected = false;

  bool get isDriving => _driving;

  /// Ob das Geraet gerade mit CarPlay oder Android Auto verbunden ist.
  ///
  /// Die Verbindung ist ein starkes Start-, aber ein schwaches
  /// Stopp-Signal, und genau so wird sie hier behandelt: Sie **beendet
  /// keine Fahrt** -- ein Abbruch im Tunnel oder in der Tiefgarage darf
  /// die Aufzeichnung nicht zerreissen -- und sie **beginnt auch keine**.
  /// Ihre einzige Wirkung ist, das Beenden zu unterdruecken, solange sie
  /// besteht.
  ///
  /// Ohne diese Unterdrueckung endete jede Fahrt an einer laengeren
  /// Ampel oder im Stau, und der Rest der Fahrt zaehlte als neue -- mit
  /// falschen Distanzen, falschen 0-100-Zeiten und einer zerstueckelten
  /// Heatmap.
  ///
  /// Dass die Fahrt nicht schon beim Verbinden beginnt, ist Absicht: die
  /// Standzeit vor dem Losfahren gehoerte sonst zur Fahrt und drueckte
  /// den Durchschnitt. Losgefahren wird weiterhin ueber [startSpeed]
  /// erkannt.
  set carConnected(bool connected) {
    _carConnected = connected;
    if (connected) {
      // Das laufende Stopp-Fenster verwerfen: nach einem Wiederverbinden
      // soll nicht die Standzeit von vorher weiterzaehlen.
      _stillSince = null;
    }
  }

  bool get carConnected => _carConnected;

  TripEvent? update(Sample s) {
    if (s.accuracy > config.minAccuracy) return null;
    final now = s.timestamp;

    if (!_driving) {
      if (s.speed >= config.startSpeed) {
        _movingSince ??= now;
        if (now.difference(_movingSince!) >= config.startWindow) {
          _driving = true;
          _movingSince = null;
          _stillSince = null;
          return TripEvent.started;
        }
      } else {
        _movingSince = null;
      }
      return null;
    }

    // Driving.
    if (_carConnected) {
      // Solange das Auto verbunden ist, sitzt der Nutzer nachweislich
      // darin. Stehen heisst dann Ampel, Stau oder Tankstelle -- nicht
      // Fahrtende.
      _stillSince = null;
      return null;
    }

    if (s.speed <= config.stopSpeed) {
      _stillSince ??= now;
      if (now.difference(_stillSince!) >= config.stopWindow) {
        _driving = false;
        _stillSince = null;
        _movingSince = null;
        return TripEvent.stopped;
      }
    } else {
      _stillSince = null;
    }
    return null;
  }
}
