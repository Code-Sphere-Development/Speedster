import 'package:flutter/services.dart';
import 'package:speedster/heat/usual_speed.dart';

/// Zustand, den der Sperrbildschirm zeigt.
class LiveActivityState {
  const LiveActivityState({
    required this.speedKmh,
    required this.verdict,
    required this.distanceMeters,
    required this.elapsedSeconds,
  });

  final int speedKmh;
  final SpeedVerdict verdict;
  final double distanceMeters;
  final int elapsedSeconds;

  Map<String, dynamic> toArguments() => {
        'speedKmh': speedKmh,
        'verdict': verdict.name,
        'distanceMeters': distanceMeters,
        'elapsedSeconds': elapsedSeconds,
      };
}

/// Startet, aktualisiert und beendet die Anzeige auf dem Sperrbildschirm.
///
/// Auf Android und aelteren iOS-Fassungen tut die native Seite nichts und
/// meldet `false` zurueck -- die Aufzeichnung laeuft unveraendert weiter.
/// Die Anzeige ist Beiwerk und darf nie der Grund sein, dass eine Fahrt
/// nicht aufgezeichnet wird.
abstract class LiveActivity {
  Future<void> start(LiveActivityState state);

  Future<void> update(LiveActivityState state);

  Future<void> end();
}

class PlatformLiveActivity implements LiveActivity {
  const PlatformLiveActivity();

  static const _channel =
      MethodChannel('de.codesphere.speedster/live_activity');

  @override
  Future<void> start(LiveActivityState state) =>
      _invoke('start', state.toArguments());

  @override
  Future<void> update(LiveActivityState state) =>
      _invoke('update', state.toArguments());

  @override
  Future<void> end() => _invoke('end', null);

  /// Fehler werden geschluckt, nicht weitergereicht: ein fehlender
  /// Plattformkanal -- etwa auf Android -- darf die Aufzeichnung nicht
  /// abbrechen.
  Future<void> _invoke(String method, Map<String, dynamic>? arguments) async {
    try {
      await _channel.invokeMethod<bool>(method, arguments);
    } on PlatformException {
      // Anzeige nicht verfuegbar.
    } on MissingPluginException {
      // Plattform ohne Live Activities.
    }
  }
}

/// Fuer Tests: merkt sich, was gesendet wurde.
class RecordingLiveActivity implements LiveActivity {
  final List<LiveActivityState> started = [];
  final List<LiveActivityState> updated = [];
  int ended = 0;

  @override
  Future<void> start(LiveActivityState state) async => started.add(state);

  @override
  Future<void> update(LiveActivityState state) async => updated.add(state);

  @override
  Future<void> end() async => ended++;
}
