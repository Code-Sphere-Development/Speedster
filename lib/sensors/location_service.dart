import 'dart:async';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:speedster/domain/sample.dart';

/// Emits a stream of normalized [Sample]s from device sensors.
abstract class SampleSource {
  Stream<Sample> samples();
}

/// Replays a fixed list of samples. Used in tests and widget previews.
class FakeSampleSource implements SampleSource {
  FakeSampleSource(this._samples);

  final List<Sample> _samples;

  @override
  Stream<Sample> samples() => Stream.fromIterable(_samples);
}

/// Real source: merges GPS position (geolocator) with the latest
/// accelerometer magnitude (sensors_plus).
class GeolocatorSampleSource implements SampleSource {
  GeolocatorSampleSource();

  double? _lastAccelMagnitude;
  StreamSubscription<UserAccelerometerEvent>? _accelSub;

  @override
  Stream<Sample> samples() {
    _accelSub ??= userAccelerometerEventStream().listen((e) {
      _lastAccelMagnitude = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
    });

    const settings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 0,
    );

    return Geolocator.getPositionStream(locationSettings: settings).map(
      (p) => Sample(
        lat: p.latitude,
        lng: p.longitude,
        speed: p.speed < 0 ? 0 : p.speed,
        altitude: p.altitude,
        accuracy: p.accuracy,
        timestamp: p.timestamp,
        accelMagnitude: _lastAccelMagnitude,
      ),
    );
  }

  Future<void> dispose() async {
    await _accelSub?.cancel();
    _accelSub = null;
  }
}
