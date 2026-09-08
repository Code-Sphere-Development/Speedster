import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/data/database.dart' show AppDatabase;
import 'package:speedster/data/trip_repository.dart';
import 'package:speedster/domain/track_point.dart';
import 'package:speedster/domain/trip.dart';
import 'package:speedster/heat/heat_folder.dart';
import 'package:speedster/heat/usual_speed.dart';

Trip keptTrip() => Trip(
      startTime: DateTime(2026),
      endTime: DateTime(2026, 1, 1, 1),
      maxSpeed: 0,
      avgSpeed: 0,
      distance: 0,
      elevationGain: 0,
      durationSeconds: 0,
      zeroToHundredSeconds: null,
      kept: true,
    );

/// Eine gerade Fahrt nach Norden mit gleichbleibender Geschwindigkeit.
List<TrackPoint> straight(int tripId, double speed, {int count = 60}) => [
      for (var i = 0; i < count; i++)
        TrackPoint(
          tripId: tripId,
          lat: 50.0 + (i * 12) / 111320.0,
          lng: 7.0,
          speed: speed,
          altitude: 100,
          accuracy: 5,
          timestamp: DateTime(2026).add(Duration(seconds: i)),
        ),
    ];

void main() {
  late AppDatabase db;
  late DriftTripRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftTripRepository(db);
  });
  tearDown(() => db.close());

  group('UsualSpeedReader', () {
    test('kennt einen Ort ohne Fahrten nicht', () async {
      expect(await UsualSpeedReader(db).at(50.0, 7.0), isNull);
    });

    test('mittelt die gemessenen Geschwindigkeiten einer Zelle', () async {
      final id = await repo.createTrip(keptTrip());
      await repo.addPoints(id, straight(id, 20.0));
      await HeatFolder(db).foldPending();

      final usual = await UsualSpeedReader(db).at(50.0, 7.0);

      expect(usual, isNotNull);
      expect(usual!.metersPerSecond, closeTo(20.0, 0.001));
      expect(usual.samples, greaterThan(0));
    });

    test('mittelt ueber mehrere Fahrten', () async {
      for (final speed in [10.0, 30.0]) {
        final id = await repo.createTrip(keptTrip());
        await repo.addPoints(id, straight(id, speed));
      }
      await HeatFolder(db).foldPending();

      final usual = await UsualSpeedReader(db).at(50.0, 7.0);

      expect(usual!.metersPerSecond, closeTo(20.0, 0.001));
    });

    test('laesst ungenaue Punkte aus', () async {
      final id = await repo.createTrip(keptTrip());
      await repo.addPoints(id, [
        ...straight(id, 20.0, count: 30),
        // Weit ueber der Schwelle: darf den Durchschnitt nicht verziehen.
        for (var i = 0; i < 30; i++)
          TrackPoint(
            tripId: id,
            lat: 50.0,
            lng: 7.0,
            speed: 90.0,
            altitude: 100,
            accuracy: 300,
            timestamp: DateTime(2026).add(Duration(seconds: 100 + i)),
          ),
      ]);
      await HeatFolder(db).foldPending();

      final usual = await UsualSpeedReader(db).at(50.0, 7.0);

      expect(usual!.metersPerSecond, closeTo(20.0, 0.001));
    });
  });

  group('SpeedComparison', () {
    const c = SpeedComparison();
    UsualSpeed usual(double mps, {int samples = 50}) =>
        UsualSpeed(metersPerSecond: mps, samples: samples);

    test('urteilt ohne Bezug nicht', () {
      expect(c.verdict(30, null), SpeedVerdict.noReference);
      expect(
        c.verdict(30, usual(20, samples: 3)),
        SpeedVerdict.noReference,
        reason: 'eine einzelne Fahrt ist keine Gewohnheit',
      );
    });

    test('erkennt deutlich schneller und deutlich langsamer', () {
      expect(c.verdict(30, usual(20)), SpeedVerdict.faster);
      expect(c.verdict(10, usual(20)), SpeedVerdict.slower);
    });

    test('haelt kleine Abweichungen fuer gewoehnlich', () {
      expect(c.verdict(21, usual(20)), SpeedVerdict.usual);
      expect(c.verdict(19, usual(20)), SpeedVerdict.usual);
    });

    test('bleibt im Schritttempo ruhig', () {
      // 3,3 statt 2,8 m/s sind zwanzig Prozent -- aber niemand faehrt
      // dort "deutlich zu schnell". Der absolute Abstand faengt das ab.
      expect(c.verdict(3.3, usual(2.8)), SpeedVerdict.usual);
    });

    test('spricht auf der Autobahn trotzdem an', () {
      // Rein absolut betrachtet waere hier nie etwas auffaellig.
      expect(c.verdict(41, usual(33)), SpeedVerdict.faster);
    });
  });
}
