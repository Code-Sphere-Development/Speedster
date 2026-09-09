import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:speedster/domain/sample.dart';

/// Emits a stream of normalized [Sample]s from device sensors.
abstract class SampleSource {
  Stream<Sample> samples();

  /// Schaltet zwischen feiner und sparsamer Ortung um.
  ///
  /// Feine Ortung -- volle Genauigkeit, jeder Fix -- kostet den
  /// Loewenanteil der Batterie und ist nur waehrend einer Fahrt noetig.
  /// Im Stand genuegt eine grobe Ortung, um Bewegung ueberhaupt zu
  /// bemerken; das System darf sie dann aus Funkzellen und WLAN
  /// beantworten, statt den GPS-Empfaenger laufen zu lassen.
  ///
  /// Vorbelegt als leere Umsetzung: die meisten Quellen -- Testdoubles,
  /// Wiedergaben -- haben keine Ortung, die sich drosseln liesse.
  void setPrecise(bool precise) {}
}

/// Replays a fixed list of samples. Used in tests and widget previews.
class FakeSampleSource extends SampleSource {
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
class GeolocatorSampleSource extends SampleSource {
  GeolocatorSampleSource();

  double? _lastAccelMagnitude;
  StreamSubscription<UserAccelerometerEvent>? _accelSub;
  StreamSubscription<Position>? _positionSub;
  bool _precise = false;

  /// Nach aussen ein durchgehender Strom, obwohl die Quelle darunter beim
  /// Umschalten neu aufgesetzt wird -- geolocator kennt keine Aenderung
  /// laufender Einstellungen.
  final _out = StreamController<Sample>.broadcast();

  @override
  Stream<Sample> samples() {
    _accelSub ??= userAccelerometerEventStream().listen((e) {
      _lastAccelMagnitude = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
    });

    _subscribe();

    return _out.stream;
  }

  @override
  void setPrecise(bool precise) {
    if (precise == _precise) return;

    _precise = precise;
    _subscribe();
  }

  void _subscribe() {
    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: settingsFor(currentPlatform(), precise: _precise),
    ).listen(
      (p) => _out.add(
        Sample(
          lat: p.latitude,
          lng: p.longitude,
          speed: p.speed < 0 ? 0 : p.speed,
          altitude: p.altitude,
          accuracy: p.accuracy,
          timestamp: p.timestamp,
          accelMagnitude: _lastAccelMagnitude,
        ),
      ),
      onError: _out.addError,
    );
  }

  Future<void> dispose() async {
    await _positionSub?.cancel();
    await _accelSub?.cancel();
    await _out.close();
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
  /// Plattformspezifische Einstellungen, in zwei Staerken.
  ///
  /// [precise] gilt waehrend einer Fahrt: volle Genauigkeit, jeder Fix.
  /// Ohne sie -- im Stand -- laeuft die Ortung grob und mit Mindestabstand.
  /// Das kostet: die ersten Meter einer Fahrt kommen ungenauer und ein
  /// paar Sekunden spaeter, weil erst die grobe Ortung Bewegung bemerken
  /// muss. Dafuer laeuft der GPS-Empfaenger nicht mehr durch, waehrend das
  /// Telefon auf dem Sofa liegt.
  static LocationSettings settingsFor(
    SamplePlatform platform, {
    bool precise = true,
  }) {
    // Im Stand seltener, aber nicht gröber als der Detektor vertraegt.
    //
    // Das ist die entscheidende Kopplung: TripDetector verwirft jede
    // Position, deren Genauigkeit schlechter als DetectorConfig.minAccuracy
    // (30 m) ist. Mit LocationAccuracy.low -- auf iOS ein Kilometer --
    // saehe er nie eine Position, und es begaenne nie eine Fahrt. Ein
    // erster Versuch hat genau das getan.
    //
    // LocationAccuracy.high liegt bei rund zehn Metern und liefert eine
    // brauchbare Geschwindigkeit; gespart wird ueber den Mindestabstand,
    // der die App nicht mehr zu jedem Fix aufweckt.
    final accuracy = precise ? LocationAccuracy.best : LocationAccuracy.high;
    final distanceFilter = precise ? 0 : 25;

    switch (platform) {
      case SamplePlatform.ios:
        return AppleSettings(
          accuracy: accuracy,
          distanceFilter: distanceFilter,
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
          accuracy: accuracy,
          distanceFilter: distanceFilter,
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
        return LocationSettings(
          accuracy: accuracy,
          distanceFilter: distanceFilter,
        );
    }
  }

}
