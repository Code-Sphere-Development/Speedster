import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';

/// Die gemeinsame Verdrahtung aller Mitteilungen dieser App.
///
/// Einrichtung, Berechtigung, Sprache und das Schlucken von Fehlern
/// stehen hier ein Mal, damit Fahrtbeginn und Wartung sie sich teilen und
/// nicht jeder Melder seine eigene Fassung davon mitbringt.
class LocalNotifications {
  LocalNotifications({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  bool _initialised = false;

  /// Zeigt eine Mitteilung. Fehler bleiben hier: keine Mitteilung ist
  /// hinnehmbar, eine abgebrochene Aufzeichnung nicht.
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required NotificationDetails details,
  }) =>
      guard(() async {
        await _ensureInitialised();
        await _plugin.show(
          id: id,
          title: title,
          body: body,
          notificationDetails: details,
        );
      });

  Future<void> cancel(int id) => guard(() async {
        await _ensureInitialised();
        await _plugin.cancel(id: id);
      });

  /// Fragt die Erlaubnis fuer Mitteilungen ab. `true`, wenn erteilt.
  Future<bool> requestPermission() async {
    var granted = false;

    await guard(() async {
      await _ensureInitialised();

      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        granted = await ios.requestPermissions(alert: true, sound: true) ??
            false;
        return;
      }

      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      granted = await android?.requestNotificationsPermission() ?? false;
    });

    return granted;
  }

  /// Die Texte ohne `BuildContext`.
  ///
  /// Melder laufen ausserhalb des Widget-Baums, haben also keinen. Nicht
  /// unterstuetzte Systemsprachen fallen auf Englisch zurueck -- dieselbe
  /// Wahl, die `MaterialApp` mit `supportedLocales` trifft.
  AppLocalizations strings() {
    final locale = PlatformDispatcher.instance.locale;

    return AppLocalizations.delegate.isSupported(locale)
        ? lookupAppLocalizations(locale)
        : lookupAppLocalizations(const Locale('en'));
  }

  /// Bewusst ohne Berechtigungsabfrage: die laeuft ueber
  /// [requestPermission] und damit an klar benannten Stellen -- nach dem
  /// Rundgang und beim Umlegen des Schalters. Sie an die Einrichtung zu
  /// haengen hiesse, irgendwann waehrend des Starts zu fragen, ohne dass
  /// ein Anlass erkennbar waere.
  Future<void> _ensureInitialised() async {
    if (_initialised) return;

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialised = true;
  }

  Future<void> guard(Future<void> Function() action) async {
    try {
      await action();
    } on Exception {
      // Eine Plattform ohne Mitteilungen -- oder eine, die sie gerade
      // verweigert -- darf nichts abbrechen.
    }
  }
}
