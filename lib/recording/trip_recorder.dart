import 'dart:async';

import 'package:speedster/data/trip_repository.dart';
import 'package:speedster/detection/trip_detector.dart';
import 'package:speedster/domain/sample.dart';
import 'package:speedster/domain/track_point.dart';
import 'package:speedster/domain/trip.dart';
import 'package:speedster/sensors/location_service.dart';
import 'package:speedster/stats/stats_engine.dart';

/// Snapshot of the recorder for the UI.
class RecorderState {
  const RecorderState({
    this.isDriving = false,
    this.activeTripId,
    this.last,
    this.awaitingConfirmationTripId,
  });

  final bool isDriving;
  final int? activeTripId;
  final Sample? last;

  /// Set once when a trip just ended and needs the driver/passenger prompt.
  final int? awaitingConfirmationTripId;
}

/// Orchestrates: sensor samples -> detection -> point recording -> finalization.
class TripRecorder {
  TripRecorder({
    required this.source,
    required this.detector,
    required this.repo,
    this.flushEvery = 10,
  });

  final SampleSource source;
  final TripDetector detector;
  final TripRepository repo;
  final int flushEvery;

  final _stateController = StreamController<RecorderState>.broadcast();
  Stream<RecorderState> get state => _stateController.stream;

  int? _tripId;
  final List<TrackPoint> _buffer = [];
  int _savedCount = 0;
  bool _stopped = false;

  /// Consumes the sample stream until it ends or [stop] is called.
  /// For an infinite (real device) stream, callers should NOT await this.
  Future<void> start() async {
    _stopped = false;
    await for (final s in source.samples()) {
      if (_stopped) break;
      await _process(s);
    }
  }

  Future<void> stop() async {
    _stopped = true;
    await _stateController.close();
  }

  Future<void> _process(Sample s) async {
    final event = detector.update(s);

    if (event == TripEvent.started) {
      _tripId = await repo.createTrip(_placeholderTrip(s.timestamp));
      _buffer
        ..clear()
        ..add(_toPoint(_tripId!, s));
      _savedCount = 0;
      _emit(isDriving: true, last: s);
      return;
    }

    if (_tripId == null) {
      _emit(isDriving: detector.isDriving, last: s);
      return;
    }

    _buffer.add(_toPoint(_tripId!, s));

    if (event == TripEvent.stopped) {
      await _flush();
      final stats = StatsEngine.compute(_buffer);
      final endedTripId = _tripId!;
      await repo.finalizeTrip(endedTripId, stats, s.timestamp);
      _tripId = null;
      _buffer.clear();
      _savedCount = 0;
      _emit(isDriving: false, last: s, awaitingConfirmationTripId: endedTripId);
      return;
    }

    if (_buffer.length - _savedCount >= flushEvery) {
      await _flush();
    }
    _emit(isDriving: true, activeTripId: _tripId, last: s);
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
    _stateController.add(
      RecorderState(
        isDriving: isDriving,
        activeTripId: activeTripId ?? _tripId,
        last: last,
        awaitingConfirmationTripId: awaitingConfirmationTripId,
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
