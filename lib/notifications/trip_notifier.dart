import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';

/// Meldet den Beginn einer Fahrt als Mitteilung.
///
/// Zweck ist die Gegenprobe: dass die Aufzeichnung angesprungen ist,
/// sieht man sonst erst hinterher an der Fahrtenliste -- und wenn sie
/// nicht angesprungen ist, gar nicht. Eine Mitteilung spiegelt iOS von
/// selbst auf eine gekoppelte Apple Watch, solange die Uhr am Handgelenk
/// und das iPhone gesperrt ist.
///
/// Wie [LiveActivity] Beiwerk: schlaegt sie fehl, wird trotzdem
/// aufgezeichnet. Eine Mitteilung darf nie der Grund sein, dass eine
/// Fahrt nicht zustande kommt.
abstract class TripNotifier {
  /// Zeigt die Meldung, sofern der Nutzer sie eingeschaltet hat.
  ///
  /// [inCar] macht sie hoerbar. Im Auto sieht man weder auf die Uhr noch
  /// aufs Display -- dort ist ein kurzer Ton die einzige Rueckmeldung,
  /// die tatsaechlich ankommt. Ausserhalb bleibt sie still: die Uhr tippt
  /// ohnehin ans Handgelenk.
  Future<void> tripStarted({required bool inCar});

  /// Nimmt sie wieder weg.
  ///
  /// Ohne das behauptete die Meldung auf dem Sperrbildschirm noch Stunden
  /// nach dem Parken, es werde aufgezeichnet. Laeuft unabhaengig von der
  /// Einstellung: wer sie waehrend der Fahrt abschaltet, soll die stehende
  /// Meldung trotzdem los werden.
  Future<void> tripEnded();

  /// Fragt die Erlaubnis fuer Mitteilungen ab. `true`, wenn erteilt.
  Future<bool> requestPermission();
}

class LocalTripNotifier implements TripNotifier {
  LocalTripNotifier({required this.enabled, FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// Ob der Nutzer die Meldung eingeschaltet hat.
  ///
  /// Eine Funktion und kein Wert: die Einstellung kann sich waehrend einer
  /// Fahrt aendern, und massgeblich ist der Stand im Moment des
  /// Fahrtbeginns. Ausserdem darf der Rekorder darueber nichts wissen --
  /// er haengt sonst an der Einstellungsschicht.
  final bool Function() enabled;

  final FlutterLocalNotificationsPlugin _plugin;

  /// Eine feste Kennung: es gibt immer hoechstens eine laufende Fahrt,
  /// und [tripEnded] muss genau diese Meldung wieder wegnehmen koennen.
  static const int notificationId = 1;

  /// Zwei Kanaele, weil Android seit Version 8 den Ton am Kanal
  /// festmacht und nicht an der einzelnen Meldung: derselbe Kanal liesse
  /// sich nachtraeglich nicht mehr von still auf hoerbar umstellen.
  static const String _androidChannelId = 'trip_start';
  static const String _androidChannelIdAudible = 'trip_start_audible';

  bool _initialised = false;

  @override
  Future<void> tripStarted({required bool inCar}) async {
    if (!enabled()) return;

    await _guard(() async {
      await _ensureInitialised();
      final l = _strings();

      await _plugin.show(
        id: notificationId,
        title: l.notificationTripStartedTitle,
        body: l.notificationTripStartedBody,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            inCar ? _androidChannelIdAudible : _androidChannelId,
            inCar ? l.notificationChannelNameAudible : l.notificationChannelName,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            playSound: inCar,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: false,
            presentSound: inCar,
          ),
        ),
      );
    });
  }

  @override
  Future<void> tripEnded() => _guard(() async {
        await _ensureInitialised();
        await _plugin.cancel(id: notificationId);
      });

  @override
  Future<bool> requestPermission() async {
    var granted = false;

    await _guard(() async {
      await _ensureInitialised();

      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        granted = await ios.requestPermissions(alert: true) ?? false;
        return;
      }

      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      granted = await android?.requestNotificationsPermission() ?? false;
    });

    return granted;
  }

  /// Bewusst ohne Berechtigungsabfrage im Initialisierungsschritt: die
  /// laeuft ueber [requestPermission] und damit an zwei klar benannten
  /// Stellen -- nach dem Rundgang und beim Umlegen des Schalters. Sie an
  /// die Einrichtung zu haengen hiesse, irgendwann waehrend des Starts zu
  /// fragen, ohne dass ein Anlass erkennbar waere.
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

  /// Die Texte ohne `BuildContext`.
  ///
  /// Der Rekorder laeuft ausserhalb des Widget-Baums, hat also keinen.
  /// Nicht unterstuetzte Systemsprachen fallen auf Englisch zurueck --
  /// dieselbe Wahl, die `MaterialApp` mit `supportedLocales` trifft.
  AppLocalizations _strings() {
    final locale = PlatformDispatcher.instance.locale;

    return AppLocalizations.delegate.isSupported(locale)
        ? lookupAppLocalizations(locale)
        : lookupAppLocalizations(const Locale('en'));
  }

  /// Fehler werden geschluckt, nicht weitergereicht -- genau wie bei der
  /// Anzeige auf dem Sperrbildschirm.
  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on Exception {
      // Keine Mitteilung ist hinnehmbar. Eine abgebrochene Aufzeichnung
      // nicht.
    }
  }
}

/// Fuer Tests: merkt sich, was gemeldet wurde.
class RecordingTripNotifier implements TripNotifier {
  RecordingTripNotifier({this.permission = true});

  /// Was [requestPermission] zurueckgibt.
  final bool permission;

  int started = 0;
  int ended = 0;
  int permissionRequests = 0;

  final List<bool> startedInCar = [];

  @override
  Future<void> tripStarted({required bool inCar}) async {
    started++;
    startedInCar.add(inCar);
  }

  @override
  Future<void> tripEnded() async => ended++;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permission;
  }
}
