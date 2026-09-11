import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speedster/settings/unit_system.dart';

/// Persisted user settings.
///
/// Ob die Cloud benutzt wird, steht hier bewusst **nicht**: das sagt der
/// Token im Schluesselbund (cloudActiveProvider). Beides nebeneinander
/// zu fuehren ging schief -- der Schluesselbund ueberlebt eine
/// Neuinstallation, die Einstellungen nicht, und ein abgelaufenes Token
/// loescht sich selbst. Dann zeigte die App Cloud-Daten an und lud nie
/// etwas hoch, oder umgekehrt.
class SettingsState {
  const SettingsState({
    this.unit = UnitSystem.kmh,
    this.trackingPaused = false,
    this.consentAccepted = false,
    this.tourSeen = false,
    this.notifyOnTripStart = true,
    this.notifyMaintenance = true,
    this.demoRide = false,
  });

  final UnitSystem unit;
  final bool trackingPaused;
  final bool consentAccepted;

  /// Ob der Rundgang schon einmal gezeigt wurde.
  ///
  /// Getrennt von der Einwilligung: die eine ist Pflicht, der andere ein
  /// Angebot. Wer den Rundgang ueberspringt, hat ihn gesehen -- er soll
  /// nicht bei jedem Start wiederkommen.
  final bool tourSeen;

  /// Ob der Beginn einer Fahrt als Mitteilung gemeldet wird.
  ///
  /// Voreingestellt an: dass die Aufzeichnung angesprungen ist, sieht man
  /// sonst erst hinterher an der Fahrtenliste -- und wenn sie nicht
  /// angesprungen ist, gar nicht. Wem das zu viel ist, schaltet es in den
  /// Einstellungen ab.
  final bool notifyOnTripStart;

  /// Ob an faellige Wartungen erinnert wird.
  ///
  /// Getrennt vom Fahrtbeginn: das eine ist eine Gegenprobe waehrend der
  /// Fahrt, das andere eine Erinnerung an etwas, das ansteht. Wer das
  /// eine will, will nicht zwangslaeufig das andere.
  final bool notifyMaintenance;

  /// Zeigt die Live-Ansicht mit erfundenen Werten.
  ///
  /// Damit sich der Tacho ansehen laesst, ohne dafuer loszufahren. Sie
  /// speist **nur die Anzeige**: es wird nichts aufgezeichnet, keine Fahrt
  /// angelegt und nichts hochgeladen.
  final bool demoRide;

  SettingsState copyWith({
    UnitSystem? unit,
    bool? trackingPaused,
    bool? consentAccepted,
    bool? tourSeen,
    bool? notifyOnTripStart,
    bool? notifyMaintenance,
    bool? demoRide,
  }) {
    return SettingsState(
      unit: unit ?? this.unit,
      trackingPaused: trackingPaused ?? this.trackingPaused,
      consentAccepted: consentAccepted ?? this.consentAccepted,
      tourSeen: tourSeen ?? this.tourSeen,
      notifyOnTripStart: notifyOnTripStart ?? this.notifyOnTripStart,
      notifyMaintenance: notifyMaintenance ?? this.notifyMaintenance,
      demoRide: demoRide ?? this.demoRide,
    );
  }
}

/// Injected in main() via override; tests can override with a mock.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(SettingsController.new);

class SettingsController extends Notifier<SettingsState> {
  static const _kUnit = 'unit';
  static const _kPaused = 'trackingPaused';
  static const _kConsent = 'consentAccepted';
  static const _kTour = 'tourSeen';
  static const _kNotifyStart = 'notifyOnTripStart';
  static const _kNotifyMaintenance = 'notifyMaintenance';
  static const _kDemoRide = 'demoRide';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  SettingsState build() {
    final p = _prefs;
    return SettingsState(
      unit: (p.getString(_kUnit) == 'mph') ? UnitSystem.mph : UnitSystem.kmh,
      trackingPaused: p.getBool(_kPaused) ?? false,
      consentAccepted: p.getBool(_kConsent) ?? false,
      tourSeen: p.getBool(_kTour) ?? false,
      notifyOnTripStart: p.getBool(_kNotifyStart) ?? true,
      notifyMaintenance: p.getBool(_kNotifyMaintenance) ?? true,
      demoRide: p.getBool(_kDemoRide) ?? false,
    );
  }

  Future<void> setUnit(UnitSystem unit) async {
    state = state.copyWith(unit: unit);
    await _prefs.setString(_kUnit, unit == UnitSystem.mph ? 'mph' : 'kmh');
  }

  Future<void> setTrackingPaused(bool paused) async {
    state = state.copyWith(trackingPaused: paused);
    await _prefs.setBool(_kPaused, paused);
  }

  Future<void> acceptConsent() async {
    state = state.copyWith(consentAccepted: true);
    await _prefs.setBool(_kConsent, true);
  }

  /// Merkt sich, dass der Rundgang gezeigt wurde -- auch beim
  /// Ueberspringen. Wer ihn wegwischt, will ihn nicht beim naechsten Start
  /// wiederhaben; erneut aufrufen laesst er sich in den Einstellungen.
  Future<void> setTourSeen(bool seen) async {
    state = state.copyWith(tourSeen: seen);
    await _prefs.setBool(_kTour, seen);
  }

  Future<void> setNotifyOnTripStart(bool notify) async {
    state = state.copyWith(notifyOnTripStart: notify);
    await _prefs.setBool(_kNotifyStart, notify);
  }

  Future<void> setNotifyMaintenance(bool notify) async {
    state = state.copyWith(notifyMaintenance: notify);
    await _prefs.setBool(_kNotifyMaintenance, notify);
  }

  Future<void> setDemoRide(bool demo) async {
    state = state.copyWith(demoRide: demo);
    await _prefs.setBool(_kDemoRide, demo);
  }

}
