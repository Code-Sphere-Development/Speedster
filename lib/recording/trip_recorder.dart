import 'dart:async';

import 'package:speedster/data/trip_repository.dart';
import 'package:speedster/detection/trip_detector.dart';
import 'package:speedster/domain/sample.dart';
import 'package:speedster/domain/track_point.dart';
import 'package:speedster/domain/trip.dart';
import 'package:speedster/heat/usual_speed.dart';
import 'package:speedster/live/live_activity.dart';
import 'package:speedster/sensors/location_service.dart';
import 'package:speedster/stats/stats_engine.dart';

/// Snapshot of the recorder for the UI.
class RecorderState {
  const RecorderState({
    this.isDriving = false,
    this.activeTripId,
    this.last,
    this.awaitingConfirmationTripId,
    this.distanceMeters = 0,
    this.elapsedSeconds = 0,
  });

  final bool isDriving;
  final int? activeTripId;
  final Sample? last;

  /// Set once when a trip just ended and needs the driver/passenger prompt.
  final int? awaitingConfirmationTripId;

  /// Distance covered so far in the active trip (meters).
  final double distanceMeters;

  /// Elapsed time since the active trip started (seconds).
  final int elapsedSeconds;
}

/// Orchestrates: sensor samples -> detection -> point recording -> finalization.
class TripRecorder {
  TripRecorder({
    required this.source,
    required this.detector,
    required this.repo,
    this.carConnected,
    this.liveActivity,
    this.usualSpeed,
    this.comparison = const SpeedComparison(),
    this.defaultVehicleId,
    this.flushEvery = 10,
  });

  final SampleSource source;
  final TripDetector detector;
  final TripRepository repo;

  /// Meldet CarPlay- und Android-Auto-Verbindungen an den Detektor weiter.
  ///
  /// Bewusst ein blosser `Stream<bool>` statt der CarConnection-Klasse:
  /// die Aufzeichnung soll nichts aus der App-Schicht kennen, und ein
  /// Strom laesst sich im Test ohne Plattformkanal fuettern.
  ///
  /// Optional, weil ein Geraet ohne beides -- und jeder Test, den die
  /// Verbindung nicht interessiert -- ohne auskommen muss.
  final Stream<bool>? carConnected;

  /// Liefert das Fahrzeug, dem eine endende Fahrt zugeordnet wird.
  ///
  /// Eine Funktion und kein Wert: die Garage kann sich waehrend der Fahrt
  /// aendern, und maßgeblich ist der Stand am Fahrtende. Fehlt sie oder
  /// gibt sie null zurueck, bleibt die Fahrt ohne Fahrzeug -- ohne Cloud
  /// gibt es keine Garage, und das darf die Aufzeichnung nicht stoeren.
  final Future<int?> Function()? defaultVehicleId;

  /// Anzeige auf dem Sperrbildschirm. Optional -- fehlt sie, wird
  /// aufgezeichnet wie zuvor. Die Anzeige ist Beiwerk und darf nie der
  /// Grund sein, dass eine Fahrt nicht zustande kommt.
  final LiveActivity? liveActivity;

  /// Liefert die gewohnte Geschwindigkeit am aktuellen Ort, den Massstab
  /// fuer "schneller/langsamer als sonst".
  final UsualSpeedReader? usualSpeed;

  final SpeedComparison comparison;

  final int flushEvery;

  final _stateController = StreamController<RecorderState>.broadcast();
  Stream<RecorderState> get state => _stateController.stream;

  StreamSubscription<bool>? _carSubscription;

  /// Wann die Anzeige zuletzt aktualisiert wurde.
  ///
  /// GPS liefert je nach Geraet mehrfach pro Sekunde; jede Meldung an
  /// ActivityKit weiterzureichen waere Arbeit ohne sichtbaren Gewinn --
  /// und das System drosselt zu haeufige Aktualisierungen ohnehin.
  DateTime? _lastActivityUpdate;
  static const _activityInterval = Duration(seconds: 1);

  int? _tripId;
  final List<TrackPoint> _buffer = [];
  int _savedCount = 0;
  bool _stopped = false;
  DateTime? _startTime;
  double _distance = 0;

  /// Consumes the sample stream until it ends or [stop] is called.
  /// For an infinite (real device) stream, callers should NOT await this.
  Future<void> start() async {
    _stopped = false;
    // Faellt der Plattformkanal aus, meldet er nichts, und der Detektor
    // bleibt bei `false` -- die Erkennung verhaelt sich dann wie vor
    // dieser Aenderung, statt haengen zu bleiben.
    _carSubscription ??= carConnected?.listen(
      (connected) => detector.carConnected = connected,
      onError: (Object _) {},
    );
    await for (final s in source.samples()) {
      if (_stopped) break;
      await _process(s);
    }
  }

  Future<void> stop() async {
    _stopped = true;
    await _carSubscription?.cancel();
    _carSubscription = null;
    await _stateController.close();
  }

  Future<void> _process(Sample s) async {
    final event = detector.update(s);

    if (event == TripEvent.started) {
      _tripId = await repo.createTrip(_placeholderTrip(s.timestamp));
      _startTime = s.timestamp;
      _distance = 0;
      _buffer
        ..clear()
        ..add(_toPoint(_tripId!, s));
      _savedCount = 0;
      _lastActivityUpdate = null;
      await _pushActivity(s, start: true);
      _emit(isDriving: true, last: s);
      return;
    }

    if (_tripId == null) {
      _emit(isDriving: detector.isDriving, last: s);
      return;
    }

    final prev = _buffer.last;
    _distance += StatsEngine.haversineMeters(prev.lat, prev.lng, s.lat, s.lng);
    _buffer.add(_toPoint(_tripId!, s));

    if (event == TripEvent.stopped) {
      await _flush();
      final stats = StatsEngine.compute(_buffer);
      final endedTripId = _tripId!;
      await repo.finalizeTrip(
        endedTripId,
        stats,
        s.timestamp,
        cloudVehicleId: await defaultVehicleId?.call(),
      );
      _tripId = null;
      _buffer.clear();
      _savedCount = 0;
      await liveActivity?.end();
      _emit(isDriving: false, last: s, awaitingConfirmationTripId: endedTripId);
      _startTime = null;
      _distance = 0;
      return;
    }

    if (_buffer.length - _savedCount >= flushEvery) {
      await _flush();
    }
    await _pushActivity(s, start: false);
    _emit(isDriving: true, activeTripId: _tripId, last: s);
  }

  /// Schickt den aktuellen Stand an den Sperrbildschirm.
  ///
  /// Das Urteil vergleicht mit der eigenen Gewohnheit an genau diesem Ort
  /// (siehe UsualSpeedReader). Liegt dort noch nichts vor, bleibt es bei
  /// `noReference` -- lieber keine Aussage als eine erfundene.
  Future<void> _pushActivity(Sample s, {required bool start}) async {
    final activity = liveActivity;
    if (activity == null) return;

    final now = s.timestamp;
    if (!start &&
        _lastActivityUpdate != null &&
        now.difference(_lastActivityUpdate!) < _activityInterval) {
      return;
    }
    _lastActivityUpdate = now;

    final usual = await usualSpeed?.at(s.lat, s.lng);
    final state = LiveActivityState(
      speedKmh: (s.speed * 3.6).round(),
      verdict: comparison.verdict(s.speed, usual),
      distanceMeters: _distance,
      elapsedSeconds:
          _startTime == null ? 0 : now.difference(_startTime!).inSeconds,
    );

    if (start) {
      await activity.start(state);
    } else {
      await activity.update(state);
    }
  }

  Future<void> _flush() async {
    if (_tripId == null) return;
    final pending = _buffer.sublist(_savedCount);
    if (pending.isEmpty) return;
    await repo.addPoints(_tripId!, pending);
    _savedCount = _buffer.length;
  }

  void _emit({
    required bool isDriving,
    int? activeTripId,
    Sample? last,
    int? awaitingConfirmationTripId,
  }) {
    if (_stateController.isClosed) return;
    final elapsed = (_startTime != null && last != null)
        ? last.timestamp.difference(_startTime!).inSeconds
        : 0;
    _stateController.add(
      RecorderState(
        isDriving: isDriving,
        activeTripId: activeTripId ?? _tripId,
        last: last,
        awaitingConfirmationTripId: awaitingConfirmationTripId,
        distanceMeters: _distance,
        elapsedSeconds: elapsed,
      ),
    );
  }

  Trip _placeholderTrip(DateTime start) => Trip(
        startTime: start,
        endTime: null,
        maxSpeed: 0,
        avgSpeed: 0,
        distance: 0,
        elevationGain: 0,
        durationSeconds: 0,
        zeroToHundredSeconds: null,
        kept: true,
      );

  TrackPoint _toPoint(int tripId, Sample s) => TrackPoint(
        tripId: tripId,
        lat: s.lat,
        lng: s.lng,
        speed: s.speed,
        altitude: s.altitude,
        accuracy: s.accuracy,
        timestamp: s.timestamp,
      );
}
