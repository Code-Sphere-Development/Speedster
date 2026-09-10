import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/data/database.dart' show AppDatabase;
import 'package:speedster/data/trip_repository.dart';
import 'package:speedster/detection/trip_detector.dart';
import 'package:speedster/heat/usual_speed.dart';
import 'package:speedster/live/live_activity.dart';
import 'package:speedster/notifications/trip_notifier.dart';
import 'package:speedster/domain/sample.dart';
import 'package:speedster/recording/trip_recorder.dart';
import 'package:speedster/sensors/location_service.dart';

Sample s(double speed, int sec) => Sample(
      lat: 50,
      lng: 6,
      speed: speed,
      altitude: 100,
      accuracy: 3,
      timestamp: DateTime(2026, 1, 1, 12, 0, sec),
    );

/// Haelt fest, wie oft und wohin die Ortungsstaerke geschaltet wurde.
class _RecordingSource extends SampleSource {
  _RecordingSource(this._samples);

  final List<Sample> _samples;
  final precisionChanges = <bool>[];

  @override
  Stream<Sample> samples() => Stream.fromIterable(_samples);

  @override
  void setPrecise(bool precise) => precisionChanges.add(precise);
}

/// Zaehlt, wie oft der Strom abonniert wurde.
class _CountingSource extends SampleSource {
  _CountingSource(this._samples);

  final List<Sample> _samples;
  int subscriptions = 0;

  @override
  Stream<Sample> samples() {
    subscriptions++;

    return Stream.fromIterable(_samples);
  }
}

void main() {
  test('records a full trip from motion to stop', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repo = DriftTripRepository(db);
    final source = FakeSampleSource([
      s(10, 0), s(10, 6), // start
      s(20, 10), s(28, 14), // driving
      s(0, 20), s(0, 85), // stop after stopWindow (60 s)
    ]);
    final rec = TripRecorder(
      source: source,
      detector: TripDetector(const DetectorConfig()),
      repo: repo,
    );
    await rec.start();
    await rec.stop();
    final trips = await repo.keptTrips();
    expect(trips, hasLength(1));
    expect(trips.single.maxSpeed, 28);
    await db.close();
  });

  test('emits live distance and elapsed time while driving', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repo = DriftTripRepository(db);
    Sample sm(double speed, int sec, double lat) => Sample(
          lat: lat,
          lng: 6,
          speed: speed,
          altitude: 100,
          accuracy: 3,
          timestamp: DateTime(2026, 1, 1, 12, 0, sec),
        );
    final source = FakeSampleSource([
      sm(10, 0, 50.000), sm(10, 6, 50.001), // start
      sm(20, 10, 50.002), // driving, moved ~111 m
      sm(0, 85, 50.002), // stop
    ]);
    final rec = TripRecorder(
      source: source,
      detector: TripDetector(const DetectorConfig()),
      repo: repo,
    );

    final states = <RecorderState>[];
    final sub = rec.state.listen(states.add);
    await rec.start();

    final driving = states.firstWhere(
      (s) => s.isDriving && s.endedTripId == null && s.elapsedSeconds > 0,
    );
    expect(driving.distanceMeters, greaterThan(100));
    expect(driving.elapsedSeconds, 4); // t=10 minus start t=6

    await sub.cancel();
    await rec.stop();
    await db.close();
  });

  test('haelt die Fahrt am Laufen, solange das Auto verbunden ist', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repo = DriftTripRepository(db);
    final source = FakeSampleSource([
      s(10, 0), s(10, 6), // Fahrtbeginn
      s(20, 10),
      s(0, 20), s(0, 300), // fuenf Minuten Stau
    ]);
    final rec = TripRecorder(
      source: source,
      detector: TripDetector(const DetectorConfig()),
      repo: repo,
      carConnected: Stream.value(true),
    );

    await rec.start();

    // Ohne die Verbindung endete die Fahrt nach 60 s Stillstand, und der
    // Rest zaehlte als zweite Fahrt.
    //
    // Ueber openTrips und nicht ueber keptTrips: die laufende Fahrt ist
    // noch nicht abgeschlossen, und keptTrips haelt genau solche Zeilen
    // zurueck -- sie truegen sonst die Nullen, mit denen sie angelegt
    // wurden, mitten in die Fahrtenliste.
    final open = await repo.openTrips();
    expect(open, hasLength(1));
    expect(open.single.endTime, isNull, reason: 'noch nicht abgeschlossen');
    expect(await repo.keptTrips(), isEmpty);

    await rec.stop();
    await db.close();
  });

  test('kommt ohne Verbindungsstrom aus', () async {
    // Ein Geraet ohne CarPlay und ohne Android Auto meldet nichts; die
    // Erkennung muss sich dann verhalten wie zuvor.
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repo = DriftTripRepository(db);
    final rec = TripRecorder(
      source: FakeSampleSource([s(10, 0), s(10, 6), s(0, 20), s(0, 85)]),
      detector: TripDetector(const DetectorConfig()),
      repo: repo,
    );

    await rec.start();

    expect((await repo.keptTrips()).single.endTime, isNotNull);
    await rec.stop();
    await db.close();
  });

  group('Mitteilung zum Fahrtbeginn', () {
    test('meldet den Beginn und nimmt die Meldung am Ende weg', () async {
      // Die Gegenprobe, dass die Aufzeichnung angesprungen ist -- ohne
      // sie sieht man das erst hinterher an der Fahrtenliste, und wenn
      // sie nicht angesprungen ist, gar nicht.
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final repo = DriftTripRepository(db);
      final notifier = RecordingTripNotifier();
      final rec = TripRecorder(
        source: FakeSampleSource([
          s(10, 0), s(10, 6), // Fahrtbeginn
          s(20, 10),
          s(0, 20), s(0, 85), // Fahrtende
        ]),
        detector: TripDetector(const DetectorConfig()),
        repo: repo,
        notifier: notifier,
      );

      await rec.start();

      expect(notifier.started, 1);
      expect(notifier.ended, 1);
      expect(notifier.startedInCar, [false]);
      await rec.stop();
      await db.close();
    });

    test('meldet mit Ton, wenn das Auto verbunden ist', () async {
      // Die Gegenprobe im Auto: dort schaut man weder auf die Uhr noch
      // aufs Display.
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final repo = DriftTripRepository(db);
      final notifier = RecordingTripNotifier();
      final rec = TripRecorder(
        source: FakeSampleSource([
          s(10, 0), s(10, 6), // Fahrtbeginn
          s(20, 10),
        ]),
        detector: TripDetector(const DetectorConfig()),
        repo: repo,
        carConnected: Stream.value(true),
        notifier: notifier,
      );

      await rec.start();

      expect(notifier.startedInCar, [true]);
      await rec.stop();
      await db.close();
    });

    test('zeichnet auch ohne Melder auf', () async {
      // Die Meldung ist Beiwerk und darf nie der Grund sein, dass eine
      // Fahrt nicht zustande kommt.
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final repo = DriftTripRepository(db);
      final rec = TripRecorder(
        source: FakeSampleSource([
          s(10, 0), s(10, 6),
          s(20, 10),
          s(0, 20), s(0, 85),
        ]),
        detector: TripDetector(const DetectorConfig()),
        repo: repo,
      );

      await rec.start();

      expect(await repo.keptTrips(), hasLength(1));
      await rec.stop();
      await db.close();
    });
  });

  group('Sperrbildschirm', () {
    test('startet, aktualisiert und beendet die Anzeige mit der Fahrt',
        () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final repo = DriftTripRepository(db);
      final activity = RecordingLiveActivity();
      final rec = TripRecorder(
        source: FakeSampleSource([
          s(10, 0), s(10, 6), // Fahrtbeginn
          s(20, 10), s(28, 14),
          s(0, 20), s(0, 85), // Fahrtende
        ]),
        detector: TripDetector(const DetectorConfig()),
        repo: repo,
        liveActivity: activity,
      );

      await rec.start();

      expect(activity.started, hasLength(1));
      expect(activity.updated, isNotEmpty);
      expect(activity.ended, 1);
      await rec.stop();
      await db.close();
    });

    test('drosselt die Aktualisierungen auf eine je Sekunde', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final activity = RecordingLiveActivity();
      // Vier Messungen in derselben Sekunde: GPS liefert je nach Geraet
      // mehrfach pro Sekunde, ActivityKit drosselt zu haeufige
      // Aktualisierungen ohnehin.
      final samples = [
        s(10, 0), s(10, 6),
        for (var i = 0; i < 4; i++) s(20, 7),
        s(20, 8),
      ];
      final rec = TripRecorder(
        source: FakeSampleSource(samples),
        detector: TripDetector(const DetectorConfig()),
        repo: DriftTripRepository(db),
        liveActivity: activity,
      );

      await rec.start();

      expect(activity.updated, hasLength(2), reason: 'Sekunde 7 und 8');
      await rec.stop();
      await db.close();
    });

    test('urteilt ohne eigene Messungen am Ort nicht', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final activity = RecordingLiveActivity();
      final rec = TripRecorder(
        source: FakeSampleSource([s(10, 0), s(10, 6), s(20, 10)]),
        detector: TripDetector(const DetectorConfig()),
        repo: DriftTripRepository(db),
        liveActivity: activity,
        usualSpeed: UsualSpeedReader(db),
      );

      await rec.start();

      // Lieber keine Aussage als eine erfundene.
      expect(activity.started.single.verdict, SpeedVerdict.noReference);
      await rec.stop();
      await db.close();
    });

    test('zeichnet ohne Anzeige unveraendert auf', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final repo = DriftTripRepository(db);
      final rec = TripRecorder(
        source: FakeSampleSource([s(10, 0), s(10, 6), s(0, 20), s(0, 85)]),
        detector: TripDetector(const DetectorConfig()),
        repo: repo,
      );

      await rec.start();

      expect((await repo.keptTrips()).single.endTime, isNotNull);
      await rec.stop();
      await db.close();
    });
  });

  test('schaltet die Ortung erst zur Fahrt fein und danach zurueck', () async {
    // Ohne das Zuruecknehmen liefe die feine Ortung bis zum naechsten
    // Neustart der App weiter -- also auch die ganze Nacht.
    final source = _RecordingSource([
      s(10, 0), s(10, 6), // Fahrtbeginn
      s(0, 20), s(0, 85), // Stopp nach dem stopWindow
    ]);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final rec = TripRecorder(
      source: source,
      detector: TripDetector(const DetectorConfig()),
      repo: DriftTripRepository(db),
    );

    await rec.start();

    expect(source.precisionChanges, [true, false]);
  });

  test('legt bei einem zweiten Start keinen zweiten Leser an', () async {
    // Sonst verarbeitete jede Position doppelt, und die Distanz
    // verdoppelte sich.
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final source = _CountingSource([s(10, 0), s(10, 6), s(0, 20), s(0, 85)]);
    final rec = TripRecorder(
      source: source,
      detector: TripDetector(const DetectorConfig()),
      repo: DriftTripRepository(db),
    );

    await Future.wait([rec.start(), rec.start()]);

    expect(source.subscriptions, 1);
  });

  test('gilt nach dem Ende des Stroms wieder als gestoppt', () async {
    // Faellt der Strom mit einem Fehler aus, muss ein erneuter Start
    // wirken -- sonst bliebe die Aufzeichnung stillschweigend tot.
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final rec = TripRecorder(
      source: FakeSampleSource([s(0, 0)]),
      detector: TripDetector(const DetectorConfig()),
      repo: DriftTripRepository(db),
    );

    expect(rec.isRunning, isFalse);
    await rec.start();
    expect(rec.isRunning, isFalse);
  });
}
