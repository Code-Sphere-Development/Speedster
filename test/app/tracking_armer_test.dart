import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speedster/app/permissions.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/data/database.dart' show AppDatabase;
import 'package:speedster/data/trip_repository.dart';
import 'package:speedster/detection/trip_detector.dart';
import 'package:speedster/recording/trip_recorder.dart';
import 'package:speedster/sensors/location_service.dart';
import 'package:speedster/sensors/location_wake.dart';
import 'package:speedster/settings/settings_controller.dart';

void main() {
  late AppDatabase db;
  late FakePermissionGate gate;
  late RecordingLocationWake watcher;
  late TripRecorder recorder;

  Future<ProviderContainer> build({
    LocationAccess access = LocationAccess.always,
    bool consent = true,
    bool paused = false,
  }) async {
    SharedPreferences.setMockInitialValues({
      'consentAccepted': consent,
      'trackingPaused': paused,
    });
    final prefs = await SharedPreferences.getInstance();

    db = AppDatabase.forTesting(NativeDatabase.memory());
    gate = FakePermissionGate(access: access);
    watcher = RecordingLocationWake();
    recorder = TripRecorder(
      source: FakeSampleSource(const []),
      detector: TripDetector(const DetectorConfig()),
      repo: DriftTripRepository(db),
    );

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        permissionGateProvider.overrideWithValue(gate),
        locationWakeProvider.overrideWithValue(watcher),
        recorderProvider.overrideWithValue(recorder),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(db.close);

    return container;
  }

  test('mit "Immer" laeuft Aufzeichnung und Ortsueberwachung', () async {
    final container = await build();

    expect(await container.read(trackingArmerProvider).arm(),
        LocationAccess.always);
    expect(recorder.isRunning, isTrue);
    expect(watcher.coarseStarts, 1);
  });

  test('mit "Beim Verwenden" wird aufgezeichnet, aber nicht ueberwacht',
      () async {
    // Die Ueberwachung braeuchte "Immer", um die App wieder zu starten.
    // Ohne das kostete sie Batterie fuer nichts.
    final container = await build(access: LocationAccess.whileInUse);

    expect(await container.read(trackingArmerProvider).arm(),
        LocationAccess.whileInUse);
    expect(recorder.isRunning, isTrue);
    expect(watcher.coarseStarts, 0);
    expect(watcher.coarseStops, 1);
  });

  test('ohne Erlaubnis wird nichts angefasst', () async {
    final container = await build(access: LocationAccess.denied);

    await container.read(trackingArmerProvider).arm();

    expect(recorder.isRunning, isFalse);
    expect(watcher.coarseStarts, 0);
  });

  test('pausiert heisst pausiert, auch die Ueberwachung', () async {
    final container = await build(paused: true);

    await container.read(trackingArmerProvider).arm();

    expect(recorder.isRunning, isFalse);
    expect(watcher.coarseStarts, 0);
    expect(watcher.coarseStops, 1);
  });

  test('vor der Einwilligung wird nicht einmal gefragt', () async {
    // Ein Ortungsdialog vor der Erklaerung waere die Frage vor dem Grund.
    final container = await build(consent: false);

    expect(await container.read(trackingArmerProvider).arm(),
        LocationAccess.denied);
    expect(recorder.isRunning, isFalse);
    expect(gate.alwaysRequests, 0);
  });

  test('ein zweiter Aufruf legt keinen zweiten Leser an', () async {
    // Sonst laege bei jedem Wechsel nach vorn ein weiterer Leser auf
    // demselben Strom, und jede Position zaehlte doppelt.
    final container = await build();
    final armer = container.read(trackingArmerProvider);

    await armer.arm();
    await armer.arm();

    expect(recorder.isRunning, isTrue);
    expect(watcher.coarseStarts, 2, reason: 'start ist folgenlos wiederholbar');
  });
}
