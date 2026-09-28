import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/data/database.dart';
import 'package:speedster/data/trip_repository.dart';
import 'package:speedster/detection/trip_detector.dart';
import 'package:speedster/domain/sample.dart';
import 'package:speedster/recording/trip_recorder.dart';
import 'package:speedster/sensors/location_service.dart';
import 'package:speedster/sensors/location_wake.dart';

/// Merkt sich, wann die Ortung an und aus war.
class _Source extends SampleSource {
  _Source(this.controller);

  final StreamController<Sample> controller;
  final List<bool> activeChanges = [];
  bool active = true;

  @override
  Stream<Sample> samples() => controller.stream;

  @override
  void setActive(bool value) {
    if (value == active) return;
    active = value;
    activeChanges.add(value);
  }
}

Sample at(double speed, int sec) => Sample(
      lat: 50,
      lng: 6,
      speed: speed,
      altitude: 100,
      accuracy: 3,
      timestamp: DateTime(2026, 1, 1, 12, 0, sec),
    );

void main() {
  late AppDatabase db;
  late DriftTripRepository repo;
  late StreamController<Sample> samples;
  late StreamController<LocationWakeReason> wakes;
  late _Source source;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftTripRepository(db);
    samples = StreamController<Sample>();
    wakes = StreamController<LocationWakeReason>.broadcast();
    source = _Source(samples);
  });

  tearDown(() async {
    await samples.close();
    await wakes.close();
    await db.close();
  });

  TripRecorder build({Duration window = const Duration(milliseconds: 50)}) =>
      TripRecorder(
        source: source,
        detector: TripDetector(const DetectorConfig()),
        repo: repo,
        locationWake: RecordingLocationWake(wakes: wakes.stream),
        awakeWindow: window,
      );

  test('ohne "Immer" bleibt die Ortung an', () async {
    // Ohne die Erlaubnis weckt weder Region noch grobe Ortsueberwachung.
    // Einschlafen hiesse hier: nie wieder aufwachen.
    final rec = build();
    unawaited(rec.start());
    rec.allowSleep(false);

    await Future<void>.delayed(const Duration(milliseconds: 150));

    expect(source.active, isTrue);
    expect(source.activeChanges, isEmpty);
    await rec.stop();
  });

  test('mit "Immer" schlaeft sie nach dem Wachfenster ein', () async {
    final rec = build();
    unawaited(rec.start());
    rec.allowSleep(true);

    await Future<void>.delayed(const Duration(milliseconds: 150));

    expect(source.active, isFalse);
    await rec.stop();
  });

  test('ein Weckruf schaltet sie wieder ein', () async {
    // Der Fall, an dem es sonst kippt: die App laeuft noch, hat aber die
    // Ortung abgeschaltet. Ohne diesen Weg bemerkt sie das Losfahren nie.
    final rec = build();
    unawaited(rec.start());
    rec.allowSleep(true);

    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(source.active, isFalse, reason: 'erst schlafen');

    wakes.add(LocationWakeReason.departure);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(source.active, isTrue);
    await rec.stop();
  });

  test('waehrend der Fahrt schlaeft sie nicht ein', () async {
    // Das Wachfenster ist kuerzer als die Fahrt -- es darf trotzdem nicht
    // mitten im Fahren abschalten.
    final rec = build(window: const Duration(milliseconds: 30));
    unawaited(rec.start());
    rec.allowSleep(true);

    samples..add(at(10, 0))..add(at(10, 6));
    await Future<void>.delayed(const Duration(milliseconds: 120));

    expect(source.active, isTrue);
    expect(await repo.openTrips(), hasLength(1), reason: 'Fahrt laeuft');
    await rec.stop();
  });

  test('am Fahrtende sofort, nicht erst nach dem Wachfenster', () async {
    // Hier wird am meisten gespart: nach einer Fahrt steht das Auto
    // stundenlang. Der Kreis um den Parkplatz weckt wieder.
    final rec = build(window: const Duration(seconds: 30));
    unawaited(rec.start());
    rec.allowSleep(true);

    samples
      ..add(at(10, 0))
      ..add(at(10, 6))
      ..add(at(20, 10))
      ..add(at(0, 20))
      ..add(at(0, 85));
    await Future<void>.delayed(const Duration(milliseconds: 120));

    expect(await repo.keptTrips(), hasLength(1));
    expect(source.active, isFalse, reason: 'geparkt, also aus');
    await rec.stop();
  });
}
