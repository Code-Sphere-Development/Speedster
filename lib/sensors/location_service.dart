import 'dart:async';
import 'dart:io' show Platform;
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

/// Auf welcher Plattform die Aufzeichnung laeuft. Ausgelagert, damit die
/// Einstellungen ohne echtes Geraet pruefbar sind.
enum SamplePlatform { ios, android, other }

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

    return Geolocator.getPositionStream(
      locationSettings: settingsFor(currentPlatform()),
    ).map(
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

  static SamplePlatform currentPlatform() {
    if (Platform.isIOS || Platform.isMacOS) return SamplePlatform.ios;
    if (Platform.isAndroid) return SamplePlatform.android;
    return SamplePlatform.other;
  }

  /// Plattformspezifische Einstellungen fuer die Positionsverfolgung.
  ///
  /// Der springende Punkt sind die Hintergrund-Optionen: Eine Fahrt dauert
  /// laenger als ein Blick aufs Display, das Telefon liegt gesperrt in der
  /// Halterung. Ohne die folgenden Angaben stellen beide Systeme die
  /// Lieferung ein, sobald die App in den Hintergrund geht -- die
  /// Deklarationen in Info.plist und Manifest allein genuegen nicht.
  static LocationSettings settingsFor(SamplePlatform platform) {
    switch (platform) {
      case SamplePlatform.ios:
        return AppleSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
          activityType: ActivityType.automotiveNavigation,
          // Ohne dieses Flag setzt geolocator allowsBackgroundLocationUpdates
          // auf NO und iOS beendet die Lieferung beim Sperren des Displays.
          allowBackgroundLocationUpdates: true,
          // Blaue Statusleiste: der Nutzer soll sehen, dass aufgezeichnet
          // wird, solange die App im Hintergrund liegt.
          showBackgroundLocationIndicator: true,
          // iOS pausiert sonst bei laengerem Stillstand und nimmt nicht
          // zuverlaessig von selbst wieder auf -- eine Ampel wuerde reichen.
          pauseLocationUpdatesAutomatically: false,
        );
      case SamplePlatform.android:
        return AndroidSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
          // Android beendet die Lieferung im Hintergrund ohne sichtbaren
          // Vordergrunddienst, trotz der Rechte im Manifest.
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationTitle: 'Speedster zeichnet auf',
            notificationText: 'Deine Fahrt wird aufgezeichnet.',
            notificationChannelName: 'Fahrtaufzeichnung',
            enableWakeLock: true,
            setOngoing: true,
          ),
        );
      case SamplePlatform.other:
        return const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
        );
    }
  }

  Future<void> dispose() async {
    await _accelSub?.cancel();
    _accelSub = null;
  }
}
