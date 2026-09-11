import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speedster/cloud/vehicle_repository.dart';
import 'package:speedster/notifications/local_notifications.dart';

/// Meldet faellige Wartungen.
///
/// **Nicht geplant, sondern beim Nachsehen gemeldet.** Eine geplante
/// Mitteilung braeuchte Zeitzonen und einen festen Zeitpunkt -- und
/// erwischte einen dann am Schreibtisch. Geprueft wird stattdessen beim
/// Start der App und nach jedem Fahrtende: dann steht man am Auto, und
/// genau dort ist die Auskunft "die HU ist naechste Woche faellig" etwas
/// wert.
///
/// Die Garage haengt am Cloud-Konto; ohne Anmeldung gibt es keine
/// Fahrzeuge und damit nichts zu erinnern.
class MaintenanceReminder {
  const MaintenanceReminder({
    required this.notifications,
    required this.prefs,
    required this.enabled,
  });

  final LocalNotifications notifications;
  final SharedPreferences prefs;
  final bool Function() enabled;

  /// Eigene Kennung, damit die Meldung die des Fahrtbeginns nicht
  /// ueberschreibt.
  static const int notificationId = 2;

  static const String _channelId = 'maintenance';

  /// Ab wann als faellig gilt. Zwei Wochen reichen fuer einen Termin in
  /// der Werkstatt; 500 Kilometer sind gut eine Woche Pendeln.
  static const int leadDays = 14;
  static const int leadKm = 500;

  static const String _prefix = 'maintenanceNotified:';

  /// Prueft alle Fahrzeuge und meldet, was ansteht.
  ///
  /// Gibt zurueck, wie viele Eintraege gemeldet wurden -- null, wenn
  /// nichts faellig war oder alles Faellige schon gemeldet ist.
  Future<int> check(List<Vehicle> vehicles) async {
    if (!enabled()) return 0;

    final due = <String>[];

    for (final vehicle in vehicles) {
      for (final item in vehicle.maintenance) {
        if (!_isDue(item)) continue;

        // Der Schluessel merkt sich *wofuer* gemeldet wurde, nicht nur
        // dass gemeldet wurde: wer den Termin verschiebt oder die Wartung
        // erledigt und neu anlegt, soll wieder erinnert werden.
        final key = '$_prefix${vehicle.id}:${item.id}';
        if (prefs.getString(key) == _signature(item)) continue;

        await prefs.setString(key, _signature(item));
        due.add(item.title);
      }
    }

    if (due.isEmpty) return 0;

    final l = notifications.strings();
    await notifications.show(
      id: notificationId,
      title: l.notificationMaintenanceTitle,
      body: due.join(', '),
      details: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          l.notificationChannelNameMaintenance,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: false,
        ),
      ),
    );

    return due.length;
  }

  /// Ueberfaellig oder nah genug dran.
  ///
  /// Fehlt die Restangabe, gibt es nichts zu vergleichen: eine Wartung
  /// ohne Termin und ohne Zielstand ist eine Notiz, keine Faelligkeit.
  /// Der Restweg fehlt ausserdem, solange kein Tachostand vorliegt.
  static bool _isDue(MaintenanceItem item) {
    final days = item.daysLeft;
    if (days != null && days <= leadDays) return true;

    final km = item.kilometersLeft;
    return km != null && km <= leadKm;
  }

  static String _signature(MaintenanceItem item) =>
      '${item.dueOn?.toIso8601String() ?? ''}|${item.dueKm ?? ''}';
}
