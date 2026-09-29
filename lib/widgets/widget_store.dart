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

  // Kein Tempo und keine 0-100 mehr. Die Widgets trugen "Max" und
  // "0-100" auf den Startbildschirm, und Apple hat die App genau dafuer
  // abgelehnt (Guideline 5): "your app still includes widgets for top
  // speed and best 0-100 for drives on public roads". Eine Bestmarke auf
  // dem Startbildschirm laedt dazu ein, sie zu brechen.
  //
  // An ihre Stelle tritt die Dauer -- dieselbe Kennzahl, nach der auch
  // die Bestenliste wertet.
  static const tripCount = 'trip_count';
  static const totalDistance = 'total_distance';
  static const totalDuration = 'total_duration';

  static const lastTripAt = 'last_trip_at';
  static const lastTripDistance = 'last_trip_distance';
  static const lastTripDuration = 'last_trip_duration';

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
