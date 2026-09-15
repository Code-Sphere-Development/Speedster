import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:speedster/notifications/local_notifications.dart';
import 'package:speedster/settings/unit_system.dart';
import 'package:speedster/stats/stats_engine.dart';
// Reine Textaufbereitung ohne Widgets -- dieselben Zahlen wie in der
// Fahrtenliste, damit die Mitteilung und die Ansicht dahinter nicht
// unterschiedlich runden.
import 'package:speedster/ui/formatters.dart';

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

  /// Nimmt die laufende Meldung weg und zeigt die Uebersicht.
  ///
  /// Das Wegnehmen laeuft unabhaengig von jeder Einstellung: ohne das
  /// behauptete die Meldung auf dem Sperrbildschirm noch Stunden nach dem
  /// Parken, es werde aufgezeichnet -- und wer sie waehrend der Fahrt
  /// abschaltet, soll die stehende Meldung trotzdem los werden.
  ///
  /// Die Uebersicht danach haengt an ihrem eigenen Schalter. [tripId]
  /// reist als Nutzlast mit, damit ein Tippen die Fahrt oeffnen kann.
  Future<void> tripEnded({required int tripId, required TripStats stats});

  /// Fragt die Erlaubnis fuer Mitteilungen ab. `true`, wenn erteilt.
  Future<bool> requestPermission();
}

class LocalTripNotifier implements TripNotifier {
  LocalTripNotifier({
    required this.enabled,
    required this.summaryEnabled,
    required this.unit,
    LocalNotifications? notifications,
  }) : _notifications = notifications ?? LocalNotifications();

  /// Ob der Nutzer die Meldung eingeschaltet hat.
  ///
  /// Eine Funktion und kein Wert: die Einstellung kann sich waehrend einer
  /// Fahrt aendern, und massgeblich ist der Stand im Moment des
  /// Fahrtbeginns. Ausserdem darf der Rekorder darueber nichts wissen --
  /// er haengt sonst an der Einstellungsschicht.
  final bool Function() enabled;

  /// Ob die Uebersicht nach dem Parken erscheint. Aus demselben Grund eine
  /// Funktion wie [enabled].
  final bool Function() summaryEnabled;

  /// Die Einheit fuer die Zahlen in der Uebersicht. Ebenfalls frisch
  /// gelesen: sie laesst sich waehrend der Fahrt umstellen.
  final UnitSystem Function() unit;

  final LocalNotifications _notifications;

  /// Eine feste Kennung: es gibt immer hoechstens eine laufende Fahrt,
  /// und [tripEnded] muss genau diese Meldung wieder wegnehmen koennen.
  static const int notificationId = 1;

  /// Zwei Kanaele, weil Android seit Version 8 den Ton am Kanal festmacht
  /// und nicht an der einzelnen Meldung: derselbe Kanal liesse sich
  /// nachtraeglich nicht mehr von still auf hoerbar umstellen.
  static const String _channelId = 'trip_start';
  static const String _channelIdAudible = 'trip_start_audible';

  /// Die Uebersicht bleibt stehen, bis der Nutzer sie wegwischt -- sie ist
  /// das Ergebnis und keine Zustandsanzeige. Deshalb eine eigene Kennung:
  /// [notificationId] wird beim Fahrtende gerade geloescht.
  static const int summaryId = 3;
  static const String _channelIdSummary = 'trip_summary';

  /// Das Format der Nutzlast steht hier, weil es hier entsteht.
  static String payloadFor(int tripId) => 'trip:$tripId';

  /// Die Fahrt hinter einer Nutzlast, oder null.
  ///
  /// Mit Praefix, damit spaetere Mitteilungen anderer Art dieselbe
  /// Nutzlast nutzen koennen, ohne dass eine fremde Zahl hier als
  /// Fahrt-Kennung durchginge.
  static int? tripIdFrom(String payload) => payload.startsWith('trip:')
      ? int.tryParse(payload.substring('trip:'.length))
      : null;

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
  Future<void> tripEnded({
    required int tripId,
    required TripStats stats,
  }) async {
    await _notifications.cancel(notificationId);

    if (!summaryEnabled()) return;

    final l = _notifications.strings();
    final u = unit();

    await _notifications.show(
      id: summaryId,
      title: l.notificationTripEndedTitle,
      body: l.notificationTripEndedBody(
        SpeedFormat.distance(stats.distance, u),
        Formatters.duration(stats.durationSeconds),
        SpeedFormat.speed(stats.maxSpeed, u),
      ),
      details: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelIdSummary,
          l.notificationChannelNameSummary,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: false,
        ),
      ),
      payload: payloadFor(tripId),
    );
  }

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

  /// Die Fahrten, deren Uebersicht gemeldet wurde.
  final List<int> endedTripIds = [];

  @override
  Future<void> tripEnded({
    required int tripId,
    required TripStats stats,
  }) async {
    ended++;
    endedTripIds.add(tripId);
  }

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permission;
  }
}
