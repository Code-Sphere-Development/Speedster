import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speedster/cloud/vehicle_repository.dart';
import 'package:speedster/notifications/local_notifications.dart';
import 'package:speedster/notifications/maintenance_reminder.dart';

class _MockPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

class _FakeInitSettings extends Fake implements InitializationSettings {}

class _FakeDetails extends Fake implements NotificationDetails {}

Vehicle vehicleWith(List<MaintenanceItem> maintenance) => Vehicle(
      id: 1,
      name: 'Der Golf',
      isDefault: true,
      maintenance: maintenance,
    );

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeInitSettings());
    registerFallbackValue(_FakeDetails());
  });

  late _MockPlugin plugin;
  late SharedPreferences prefs;
  late MaintenanceReminder reminder;

  Future<void> build({bool enabled = true}) async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

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

    reminder = MaintenanceReminder(
      notifications: LocalNotifications(plugin: plugin),
      prefs: prefs,
      enabled: () => enabled,
    );
  }

  setUp(build);

  test('meldet einen Termin, der naeher rueckt', () async {
    final count = await reminder.check([
      vehicleWith(const [MaintenanceItem(id: 5, title: 'HU', daysLeft: 7)]),
    ]);

    expect(count, 1);
    verify(
      () => plugin.show(
        id: MaintenanceReminder.notificationId,
        title: any(named: 'title'),
        body: 'HU',
        notificationDetails: any(named: 'notificationDetails'),
      ),
    ).called(1);
  });

  test('schweigt, solange es noch hin ist', () async {
    final count = await reminder.check([
      vehicleWith(const [MaintenanceItem(id: 5, title: 'HU', daysLeft: 90)]),
    ]);

    expect(count, 0);
    verifyNever(
      () => plugin.show(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        notificationDetails: any(named: 'notificationDetails'),
      ),
    );
  });

  test('meldet auch nach Restkilometern', () async {
    final count = await reminder.check([
      vehicleWith(const [
        MaintenanceItem(id: 6, title: 'Ölwechsel', kilometersLeft: 200),
      ]),
    ]);

    expect(count, 1);
  });

  test('Ueberfaelliges wird gemeldet', () async {
    final count = await reminder.check([
      vehicleWith(const [MaintenanceItem(id: 7, title: 'HU', daysLeft: -3)]),
    ]);

    expect(count, 1);
  });

  test('meldet dasselbe nicht zweimal', () async {
    // Sonst kaeme die Meldung nach jeder Fahrt erneut -- und waere nach
    // zwei Tagen etwas, das man wegwischt, ohne hinzusehen.
    const item = MaintenanceItem(
      id: 5,
      title: 'HU',
      daysLeft: 7,
      dueOn: null,
      dueKm: 30000,
    );

    expect(await reminder.check([vehicleWith(const [item])]), 1);
    expect(await reminder.check([vehicleWith(const [item])]), 0);
  });

  test('nach dem Verschieben des Termins wieder', () async {
    // Der Schluessel merkt sich, *wofuer* gemeldet wurde: wer die Wartung
    // erledigt und neu ansetzt, soll wieder erinnert werden.
    expect(
      await reminder.check([
        vehicleWith(const [
          MaintenanceItem(id: 5, title: 'HU', daysLeft: 7, dueKm: 30000),
        ]),
      ]),
      1,
    );

    expect(
      await reminder.check([
        vehicleWith(const [
          MaintenanceItem(id: 5, title: 'HU', daysLeft: 7, dueKm: 45000),
        ]),
      ]),
      1,
    );
  });

  test('ohne Restangabe gibt es nichts zu melden', () async {
    // Eine Wartung ohne Termin und ohne Zielstand ist eine Notiz.
    final count = await reminder.check([
      vehicleWith(const [MaintenanceItem(id: 8, title: 'Notiz')]),
    ]);

    expect(count, 0);
  });

  test('abgeschaltet meldet nichts', () async {
    await build(enabled: false);

    final count = await reminder.check([
      vehicleWith(const [MaintenanceItem(id: 5, title: 'HU', daysLeft: 1)]),
    ]);

    expect(count, 0);
  });
}
