import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:speedster/notifications/local_notifications.dart';

/// Meldet den Beginn einer Fahrt als Mitteilung.
///
/// Zweck ist die Gegenprobe: dass die Aufzeichnung angesprungen ist,
/// sieht man sonst erst hinterher an der Fahrtenliste -- und wenn sie
/// nicht angesprungen ist, gar nicht. Eine Mitteilung spiegelt iOS von
/// selbst auf eine gekoppelte Apple Watch, solange die Uhr am Handgelenk
/// und das iPhone gesperrt ist.
///
/// Wie die Anzeige auf dem Sperrbildschirm Beiwerk: schlaegt sie fehl,
/// wird trotzdem aufgezeichnet.
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
  LocalTripNotifier({required this.enabled, LocalNotifications? notifications})
      : _notifications = notifications ?? LocalNotifications();

  /// Ob der Nutzer die Meldung eingeschaltet hat.
  ///
  /// Eine Funktion und kein Wert: die Einstellung kann sich waehrend einer
  /// Fahrt aendern, und massgeblich ist der Stand im Moment des
  /// Fahrtbeginns. Ausserdem darf der Rekorder darueber nichts wissen --
  /// er haengt sonst an der Einstellungsschicht.
  final bool Function() enabled;

  final LocalNotifications _notifications;

  /// Eine feste Kennung: es gibt immer hoechstens eine laufende Fahrt,
  /// und [tripEnded] muss genau diese Meldung wieder wegnehmen koennen.
  static const int notificationId = 1;

  /// Zwei Kanaele, weil Android seit Version 8 den Ton am Kanal festmacht
  /// und nicht an der einzelnen Meldung: derselbe Kanal liesse sich
  /// nachtraeglich nicht mehr von still auf hoerbar umstellen.
  static const String _channelId = 'trip_start';
  static const String _channelIdAudible = 'trip_start_audible';

  @override
  Future<void> tripStarted({required bool inCar}) async {
    if (!enabled()) return;

    final l = _notifications.strings();

    await _notifications.show(
      id: notificationId,
      title: l.notificationTripStartedTitle,
      body: l.notificationTripStartedBody,
      details: NotificationDetails(
        android: AndroidNotificationDetails(
          inCar ? _channelIdAudible : _channelId,
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
  }

  @override
  Future<void> tripEnded() => _notifications.cancel(notificationId);

  @override
  Future<bool> requestPermission() => _notifications.requestPermission();
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
