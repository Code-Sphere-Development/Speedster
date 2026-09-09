import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speedster/settings/unit_system.dart';

/// Persisted user settings.
class SettingsState {
  const SettingsState({
    this.unit = UnitSystem.kmh,
    this.trackingPaused = false,
    this.consentAccepted = false,
    this.cloudEnabled = false,
    this.tourSeen = false,
  });

  final UnitSystem unit;
  final bool trackingPaused;
  final bool consentAccepted;
  final bool cloudEnabled;

  /// Ob der Rundgang schon einmal gezeigt wurde.
  ///
  /// Getrennt von der Einwilligung: die eine ist Pflicht, der andere ein
  /// Angebot. Wer den Rundgang ueberspringt, hat ihn gesehen -- er soll
  /// nicht bei jedem Start wiederkommen.
  final bool tourSeen;

  SettingsState copyWith({
    UnitSystem? unit,
    bool? trackingPaused,
    bool? consentAccepted,
    bool? cloudEnabled,
    bool? tourSeen,
  }) {
    return SettingsState(
      unit: unit ?? this.unit,
      trackingPaused: trackingPaused ?? this.trackingPaused,
      consentAccepted: consentAccepted ?? this.consentAccepted,
      cloudEnabled: cloudEnabled ?? this.cloudEnabled,
      tourSeen: tourSeen ?? this.tourSeen,
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
  static const _kCloud = 'cloudEnabled';
  static const _kTour = 'tourSeen';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  SettingsState build() {
    final p = _prefs;
    return SettingsState(
      unit: (p.getString(_kUnit) == 'mph') ? UnitSystem.mph : UnitSystem.kmh,
      trackingPaused: p.getBool(_kPaused) ?? false,
      consentAccepted: p.getBool(_kConsent) ?? false,
      cloudEnabled: p.getBool(_kCloud) ?? false,
      tourSeen: p.getBool(_kTour) ?? false,
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

  Future<void> setCloudEnabled(bool enabled) async {
    state = state.copyWith(cloudEnabled: enabled);
    await _prefs.setBool(_kCloud, enabled);
  }
}
