import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speedster/notifications/local_notifications.dart';
import 'package:speedster/notifications/trip_notifier.dart';
import 'package:speedster/settings/unit_system.dart';
import 'package:speedster/stats/stats_engine.dart';

class _MockPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

class _FakeInitSettings extends Fake implements InitializationSettings {}

class _FakeDetails extends Fake implements NotificationDetails {}

/// 12,5 km in 20 Minuten, Hoechstgeschwindigkeit 45 m/s (162 km/h).
const _stats = TripStats(
  maxSpeed: 45,
  avgSpeed: 10,
  distance: 12500,
  elevationGain: 0,
  durationSeconds: 1200,
  zeroToHundredSeconds: null,
);

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeInitSettings());
    registerFallbackValue(_FakeDetails());
  });

  late _MockPlugin plugin;

  setUp(() {
    plugin = _MockPlugin();
    when(
      () => plugin.initialize(
        settings: any(named: 'settings'),
        onDidReceiveNotificationResponse:
            any(named: 'onDidReceiveNotificationResponse'),
      ),
    ).thenAnswer((_) async => true);
    when(
      () => plugin.show(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        notificationDetails: any(named: 'notificationDetails'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});
    when(() => plugin.cancel(id: any(named: 'id'))).thenAnswer((_) async {});
  });

  LocalTripNotifier build({
    bool start = true,
    bool summary = true,
    UnitSystem unit = UnitSystem.kmh,
  }) =>
      LocalTripNotifier(
        enabled: () => start,
        summaryEnabled: () => summary,
        unit: () => unit,
        notifications: LocalNotifications(plugin: plugin),
      );

  /// Alle bisher angezeigten Meldungen.
  List<({int id, String body, String? payload, NotificationDetails details})>
      shown() {
    final calls = verify(
      () => plugin.show(
        id: captureAny(named: 'id'),
        title: any(named: 'title'),
        body: captureAny(named: 'body'),
        notificationDetails: captureAny(named: 'notificationDetails'),
        payload: captureAny(named: 'payload'),
      ),
    ).captured;

    return [
      for (var i = 0; i < calls.length; i += 4)
        (
          id: calls[i] as int,
          body: calls[i + 1] as String,
          details: calls[i + 2] as NotificationDetails,
          payload: calls[i + 3] as String?,
        ),
    ];
  }

  test('meldet den Fahrtbeginn, wenn eingeschaltet', () async {
    await build().tripStarted(inCar: false);

    expect(shown().single.id, LocalTripNotifier.notificationId);
  });

  test('schweigt, wenn der Nutzer sie abgeschaltet hat', () async {
    await build(start: false).tripStarted(inCar: false);

    verifyNever(
      () => plugin.show(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        notificationDetails: any(named: 'notificationDetails'),
        payload: any(named: 'payload'),
      ),
    );
  });

  test('nimmt die Meldung auch dann weg, wenn sie abgeschaltet wurde',
      () async {
    // Wer sie waehrend der Fahrt abschaltet, soll die stehende Meldung
    // trotzdem los werden -- sonst behauptet der Sperrbildschirm noch
    // Stunden nach dem Parken, es werde aufgezeichnet.
    await build(start: false, summary: false)
        .tripEnded(tripId: 7, stats: _stats);

    verify(() => plugin.cancel(id: LocalTripNotifier.notificationId))
        .called(1);
  });

  test('ein Fehler der Plattform bricht nichts ab', () async {
    // Die Meldung ist Beiwerk. Sie darf nie der Grund sein, dass eine
    // Fahrt nicht zustande kommt.
    when(
      () => plugin.show(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        notificationDetails: any(named: 'notificationDetails'),
        payload: any(named: 'payload'),
      ),
    ).thenThrow(Exception('kein Kanal'));

    await expectLater(build().tripStarted(inCar: false), completes);
    await expectLater(
      build().tripEnded(tripId: 1, stats: _stats),
      completes,
    );
  });

  test('richtet sich nur einmal ein', () async {
    final notifier = build();

    await notifier.tripStarted(inCar: false);
    await notifier.tripEnded(tripId: 1, stats: _stats);
    await notifier.tripStarted(inCar: false);

    verify(
      () => plugin.initialize(
        settings: any(named: 'settings'),
        onDidReceiveNotificationResponse:
            any(named: 'onDidReceiveNotificationResponse'),
      ),
    ).called(1);
  });

  test('nur im Auto mit Ton', () async {
    // Ausserhalb tippt die Uhr ohnehin ans Handgelenk. Im Auto sieht man
    // weder auf die Uhr noch aufs Display -- dort ist ein kurzer Ton die
    // einzige Rueckmeldung, die ankommt.
    final notifier = build();

    await notifier.tripStarted(inCar: false);
    await notifier.tripStarted(inCar: true);

    final details = shown().map((s) => s.details).toList();

    expect(details, hasLength(2));
    expect(details[0].iOS?.presentSound, isFalse);
    expect(details[1].iOS?.presentSound, isTrue);

    // Auf Android haengt der Ton am Kanal und nicht an der Meldung; ein
    // einziger Kanal liesse sich nachtraeglich nicht umstellen.
    expect(details[0].android?.playSound, isFalse);
    expect(details[1].android?.playSound, isTrue);
    expect(
      details[0].android?.channelId,
      isNot(details[1].android?.channelId),
    );
  });

  group('Uebersicht nach dem Parken', () {
    test('nennt Strecke, Dauer und Hoechstgeschwindigkeit', () async {
      await build().tripEnded(tripId: 42, stats: _stats);

      final summary = shown().single;

      expect(summary.body, contains('12,5 km'));
      expect(summary.body, contains('20m 00s'));
      expect(summary.body, contains('162 km/h'));
    });

    test('traegt die Fahrt als Nutzlast', () async {
      // Ohne sie wuesste das Tippen nicht, welche Fahrt es oeffnen soll.
      await build().tripEnded(tripId: 42, stats: _stats);

      expect(
        LocalTripNotifier.tripIdFrom(shown().single.payload!),
        42,
      );
    });

    test('nutzt eine eigene Kennung', () async {
      // Sonst loeschte das Wegnehmen der laufenden Meldung sie gleich
      // wieder -- beides passiert im selben Atemzug.
      expect(
        LocalTripNotifier.summaryId,
        isNot(LocalTripNotifier.notificationId),
      );

      await build().tripEnded(tripId: 1, stats: _stats);

      expect(shown().single.id, LocalTripNotifier.summaryId);
    });

    test('rechnet in Meilen um, wenn so eingestellt', () async {
      await build(unit: UnitSystem.mph).tripEnded(tripId: 1, stats: _stats);

      // Einmal abgefragt: verify verbraucht die Aufrufe, ein zweiter
      // Aufruf faende keine mehr.
      final body = shown().single.body;

      expect(body, contains('mi'));
      expect(body, contains('mph'));
    });

    test('bleibt weg, wenn abgeschaltet -- der Fahrtbeginn aber nicht',
        () async {
      // Zwei Schalter, zwei Zwecke: die Gegenprobe waehrend der Fahrt und
      // das Ergebnis danach.
      final notifier = build(summary: false);

      await notifier.tripStarted(inCar: false);
      await notifier.tripEnded(tripId: 1, stats: _stats);

      expect(shown().single.id, LocalTripNotifier.notificationId);
    });

    test('ist still: das Auto steht, man schaut ohnehin aufs Handy',
        () async {
      await build().tripEnded(tripId: 1, stats: _stats);

      expect(shown().single.details.iOS?.presentSound, isFalse);
    });

    test('eine fremde Nutzlast ist keine Fahrt', () {
      expect(LocalTripNotifier.tripIdFrom('42'), isNull);
      expect(LocalTripNotifier.tripIdFrom('maintenance:3'), isNull);
      expect(LocalTripNotifier.tripIdFrom('trip:abc'), isNull);
    });
  });
}
