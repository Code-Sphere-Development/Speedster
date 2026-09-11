import 'package:flutter/services.dart';

/// Laesst iOS die App wieder starten, wenn der Nutzer losfaehrt.
///
/// Die Gegenmassnahme gegen den Fall, dass iOS die App beendet und
/// niemand sie wieder startet -- bis dahin zeichnete Speedster nur auf,
/// wenn sie zufaellig noch lief.
///
/// Zwei Dienste nebeneinander, weil sie verschiedene Faelle abdecken:
///
/// - [watchDeparture] legt einen Kreis um den Parkplatz. Wird er
///   verlassen, startet iOS die App -- nach rund 150 Metern statt 500.
/// - [startCoarse] ueberwacht grobe Ortsaenderungen (rund 500 Meter oder
///   ein Funkzellenwechsel). Faengt ab, wenn woanders losgefahren wird.
///
/// Beides setzt **"Immer"** voraus (siehe LocationAccess). Auf Android
/// und ueberall sonst tut die Gegenseite nichts.
abstract class LocationWake {
  Future<void> startCoarse();

  Future<void> stopCoarse();

  /// Ueberwacht den Parkplatz. Ein zweiter Aufruf ersetzt den ersten.
  Future<void> watchDeparture({required double lat, required double lng});

  Future<void> clearDeparture();

  /// Ob dieser Start von iOS wegen einer Ortsaenderung ausgeloest wurde.
  Future<bool> launchedByLocation();
}

class PlatformLocationWake implements LocationWake {
  const PlatformLocationWake();

  static const _channel =
      MethodChannel('de.codesphere.speedster/location_wake');

  @override
  Future<void> startCoarse() => _invoke('startCoarse');

  @override
  Future<void> stopCoarse() => _invoke('stopCoarse');

  @override
  Future<void> watchDeparture({required double lat, required double lng}) =>
      _invoke('watchDeparture', {'lat': lat, 'lng': lng});

  @override
  Future<void> clearDeparture() => _invoke('clearDeparture');

  @override
  Future<bool> launchedByLocation() async {
    try {
      return await _channel.invokeMethod<bool>('launchedByLocation') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Fehler werden geschluckt: eine Plattform ohne diesen Kanal -- etwa
  /// Android -- darf die Aufzeichnung nicht abbrechen.
  Future<void> _invoke(String method, [Map<String, dynamic>? arguments]) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on PlatformException {
      // Dienst nicht verfuegbar.
    } on MissingPluginException {
      // Plattform ohne Ortsueberwachung.
    }
  }
}

/// Fuer Tests: merkt sich, was verlangt wurde.
class RecordingLocationWake implements LocationWake {
  RecordingLocationWake({this.launched = false});

  final bool launched;

  int coarseStarts = 0;
  int coarseStops = 0;
  int departureClears = 0;
  final List<({double lat, double lng})> departures = [];

  @override
  Future<void> startCoarse() async => coarseStarts++;

  @override
  Future<void> stopCoarse() async => coarseStops++;

  @override
  Future<void> watchDeparture({required double lat, required double lng}) async =>
      departures.add((lat: lat, lng: lng));

  @override
  Future<void> clearDeparture() async => departureClears++;

  @override
  Future<bool> launchedByLocation() async => launched;
}
