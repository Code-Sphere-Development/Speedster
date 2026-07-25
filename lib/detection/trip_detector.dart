import 'package:speedster/domain/sample.dart';

enum TripEvent { started, stopped }

/// Tunable thresholds for drive detection. Defaults in SI (m/s).
class DetectorConfig {
  const DetectorConfig({
    this.startSpeed = 2.8, // ~10 km/h
    this.stopSpeed = 0.8, // ~3 km/h
    this.startWindow = const Duration(seconds: 5),
    this.stopWindow = const Duration(seconds: 45),
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

  bool get isDriving => _driving;

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
