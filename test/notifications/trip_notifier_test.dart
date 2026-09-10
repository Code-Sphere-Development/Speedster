import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speedster/notifications/trip_notifier.dart';

class _MockPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

class _FakeInitSettings extends Fake implements InitializationSettings {}

class _FakeDetails extends Fake implements NotificationDetails {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeInitSettings());
    registerFallbackValue(_FakeDetails());
  });

  late _MockPlugin plugin;

  setUp(() {
    plugin = _MockPlugin();
    when(() => plugin.initialize(settings: any(named: 'settings')))
        .thenAnswer((_) async => true);
    when(
      () => plugin.show(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        notificationDetails: any(named: 'notificationDetails'),
      ),
    ).thenAnswer((_) async {});
    when(() => plugin.cancel(id: any(named: 'id'))).thenAnswer((_) async {});
  });

  test('meldet den Fahrtbeginn, wenn eingeschaltet', () async {
    final notifier = LocalTripNotifier(enabled: () => true, plugin: plugin);

    await notifier.tripStarted(inCar: false);

    verify(
      () => plugin.show(
        id: LocalTripNotifier.notificationId,
        title: any(named: 'title'),
        body: any(named: 'body'),
        notificationDetails: any(named: 'notificationDetails'),
      ),
    ).called(1);
  });

  test('schweigt, wenn der Nutzer sie abgeschaltet hat', () async {
    final notifier = LocalTripNotifier(enabled: () => false, plugin: plugin);

    await notifier.tripStarted(inCar: false);

    verifyNever(
      () => plugin.show(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        notificationDetails: any(named: 'notificationDetails'),
      ),
    );
  });

  test('nimmt die Meldung auch dann weg, wenn sie abgeschaltet wurde',
      () async {
    // Wer sie waehrend der Fahrt abschaltet, soll die stehende Meldung
    // trotzdem los werden -- sonst behauptet der Sperrbildschirm noch
    // Stunden nach dem Parken, es werde aufgezeichnet.
    final notifier = LocalTripNotifier(enabled: () => false, plugin: plugin);

    await notifier.tripEnded();

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
      ),
    ).thenThrow(Exception('kein Kanal'));

    final notifier = LocalTripNotifier(enabled: () => true, plugin: plugin);

    await expectLater(notifier.tripStarted(inCar: false), completes);
  });

  test('richtet sich nur einmal ein', () async {
    final notifier = LocalTripNotifier(enabled: () => true, plugin: plugin);

    await notifier.tripStarted(inCar: false);
    await notifier.tripEnded();
    await notifier.tripStarted(inCar: false);

    verify(() => plugin.initialize(settings: any(named: 'settings')))
        .called(1);
  });

  test('nur im Auto mit Ton', () async {
    // Ausserhalb tippt die Uhr ohnehin ans Handgelenk. Im Auto sieht man
    // weder auf die Uhr noch aufs Display -- dort ist ein kurzer Ton die
    // einzige Rueckmeldung, die ankommt.
    final notifier = LocalTripNotifier(enabled: () => true, plugin: plugin);

    await notifier.tripStarted(inCar: false);
    await notifier.tripStarted(inCar: true);

    final details = verify(
      () => plugin.show(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        notificationDetails: captureAny(named: 'notificationDetails'),
      ),
    ).captured.cast<NotificationDetails>();

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
}
