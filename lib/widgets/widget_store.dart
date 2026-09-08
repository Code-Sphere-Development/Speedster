import 'package:flutter/services.dart';

/// Schluessel der gemeinsamen Ablage.
///
/// Zeilengetreu abgestimmt mit `WidgetKeys` in
/// `ios/SpeedsterWidgets/SharedStore.swift`. Ein Tippfehler auf einer
/// Seite faellt nirgends auf -- das Widget zeigt dann nur seinen
/// Ersatztext -- deshalb stehen sie hier als Konstanten und nicht
/// verstreut als Zeichenketten.
class WidgetKeys {
  const WidgetKeys._();

  static const tripCount = 'trip_count';
  static const totalDistance = 'total_distance';
  static const maxSpeed = 'max_speed';
  static const bestZeroToHundred = 'best_zero_to_hundred';

  static const lastTripAt = 'last_trip_at';
  static const lastTripDistance = 'last_trip_distance';
  static const lastTripMaxSpeed = 'last_trip_max_speed';

  static const rank = 'rank';
  static const rankScope = 'rank_scope';
  static const rankValue = 'rank_value';

  static const heatmapImage = 'heatmap_image';
  static const updatedAt = 'updated_at';
}

/// Schreibt Werte in die geteilte Ablage und stoesst das Neuzeichnen an.
abstract class WidgetStore {
  Future<void> put(Map<String, Object?> values);
}

class PlatformWidgetStore implements WidgetStore {
  const PlatformWidgetStore();

  static const _channel = MethodChannel('de.codesphere.speedster/widget_store');

  @override
  Future<void> put(Map<String, Object?> values) async {
    // Null-Werte weglassen statt zu uebertragen: der Plattformkanal
    // wandelt sie zu NSNull, und die Ablage haette dann einen Eintrag,
    // der weder Wert noch Abwesenheit bedeutet.
    final payload = <String, Object>{
      for (final entry in values.entries)
        if (entry.value != null) entry.key: entry.value!,
    };
    if (payload.isEmpty) return;

    try {
      await _channel.invokeMethod<bool>('put', payload);
    } on PlatformException {
      // Ablage nicht erreichbar -- Widgets bleiben auf dem letzten Stand.
    } on MissingPluginException {
      // Plattform ohne Widgets.
    }
  }
}

/// Fuer Tests: merkt sich das Geschriebene.
class RecordingWidgetStore implements WidgetStore {
  final Map<String, Object?> values = {};
  int writes = 0;

  @override
  Future<void> put(Map<String, Object?> next) async {
    writes++;
    values.addAll(next);
  }
}
