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
  });

  final UnitSystem unit;
  final bool trackingPaused;
  final bool consentAccepted;
  final bool cloudEnabled;

  SettingsState copyWith({
    UnitSystem? unit,
    bool? trackingPaused,
    bool? consentAccepted,
    bool? cloudEnabled,
  }) {
    return SettingsState(
      unit: unit ?? this.unit,
      trackingPaused: trackingPaused ?? this.trackingPaused,
      consentAccepted: consentAccepted ?? this.consentAccepted,
      cloudEnabled: cloudEnabled ?? this.cloudEnabled,
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

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  SettingsState build() {
    final p = _prefs;
    return SettingsState(
      unit: (p.getString(_kUnit) == 'mph') ? UnitSystem.mph : UnitSystem.kmh,
      trackingPaused: p.getBool(_kPaused) ?? false,
      consentAccepted: p.getBool(_kConsent) ?? false,
      cloudEnabled: p.getBool(_kCloud) ?? false,
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

  Future<void> setCloudEnabled(bool enabled) async {
    state = state.copyWith(cloudEnabled: enabled);
    await _prefs.setBool(_kCloud, enabled);
  }
}
