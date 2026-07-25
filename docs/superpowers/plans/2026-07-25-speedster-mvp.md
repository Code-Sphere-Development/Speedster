# Speedster MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Phase-1 lokal-only Speedster app: automatic drive detection, per-trip speed/route/accel/elevation stats, on-device storage, and Flutter UI (iOS + Android).

**Architecture:** Layered, each layer one responsibility and independently testable. A sensor layer emits a normalized `Sample` stream; a pure `TripDetector` state machine turns samples into trip start/stop events; a `TripRecorder` persists `TrackPoint`s during a drive; a pure `StatsEngine` computes trip metrics from stored points; a `drift` SQLite repository stores `Trip`/`TrackPoint`; Riverpod wires state to screens. Business logic (detection, stats) is pure Dart with zero I/O so it is fully unit-tested with fake streams; sensors/DB sit behind interfaces.

**Tech Stack:** Flutter, Dart, Riverpod (state), drift + sqlite3 (persistence), geolocator (GPS), sensors_plus (accelerometer), flutter_map + latlong2 (OSM map), permission_handler, mocktail (tests).

## Global Constraints

- Framework: Flutter stable; Dart SDK `>=3.4.0 <4.0.0`.
- Internal units are SI: speed in m/s, distance/altitude in meters, time in seconds. Convert to km/h / mph ONLY in the UI layer.
- MVP is lokal-only: no network calls, no analytics, no data upload.
- Persistence repository is accessed only through the `TripRepository` interface (so Phase-2 cloud sync can add a remote implementation without touching callers).
- Pure-logic layers (`StatsEngine`, `TripDetector`) must not import `dart:io`, `geolocator`, `drift`, or Flutter widgets.
- All money/units display respects the user's unit setting (km/h default, mph optional).
- Commit after every task with a `feat:`/`test:`/`chore:` prefixed message.

---

### Task 1: Project scaffold & dependencies

**Files:**
- Create: `pubspec.yaml` (via `flutter create`, then edit deps)
- Create: `analysis_options.yaml`
- Create: `lib/main.dart` (placeholder)
- Modify: `.gitignore`

- [ ] **Step 1: Scaffold the Flutter app** into the current (non-empty) directory.

```bash
cd /Users/colilg/PhpstormProjects/Speedster
flutter create --org de.mediacologne --project-name speedster --platforms ios,android .
```

- [ ] **Step 2: Add dependencies.**

```bash
flutter pub add flutter_riverpod geolocator sensors_plus permission_handler \
  flutter_map latlong2 drift sqlite3_flutter_libs path_provider path intl
flutter pub add dev:drift_dev dev:build_runner dev:mocktail
```

- [ ] **Step 3: Set Dart SDK floor** in `pubspec.yaml`:

```yaml
environment:
  sdk: '>=3.4.0 <4.0.0'
```

- [ ] **Step 4: Enable lints.** Ensure `analysis_options.yaml` contains:

```yaml
include: package:flutter_lints/flutter.yaml
linter:
  rules:
    prefer_const_constructors: true
    require_trailing_commas: true
```

- [ ] **Step 5: Verify it builds.**

Run: `flutter analyze`
Expected: `No issues found!` (or only the default counter-app warnings — those files get replaced later).

- [ ] **Step 6: Commit.**

```bash
git add -A
git commit -m "chore: scaffold Flutter app with dependencies"
```

---

### Task 2: Domain models (`Sample`, `TrackPoint`, `Trip`)

**Files:**
- Create: `lib/domain/sample.dart`
- Create: `lib/domain/track_point.dart`
- Create: `lib/domain/trip.dart`
- Test: `test/domain/models_test.dart`

**Interfaces:**
- Produces:
  - `class Sample { final double lat, lng, speed, altitude, accuracy; final DateTime timestamp; final double? accelMagnitude; }` — speed m/s, immutable, const constructor.
  - `class TrackPoint { final int? id; final int tripId; final double lat, lng, speed, altitude, accuracy; final DateTime timestamp; }`
  - `class Trip { final int? id; final DateTime startTime; final DateTime? endTime; final double maxSpeed, avgSpeed, distance, elevationGain; final int durationSeconds; final double? zeroToHundredSeconds; final bool kept; }` with `copyWith(...)`.

- [ ] **Step 1: Write the failing test.**

```dart
// test/domain/models_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/domain/sample.dart';
import 'package:speedster/domain/trip.dart';

void main() {
  test('Sample holds SI values', () {
    final s = Sample(
      lat: 50.9, lng: 6.9, speed: 13.4, altitude: 55, accuracy: 4,
      timestamp: DateTime(2026), accelMagnitude: 9.9,
    );
    expect(s.speed, 13.4);
  });

  test('Trip.copyWith overrides only given fields', () {
    final t = Trip(
      startTime: DateTime(2026), endTime: null, maxSpeed: 0, avgSpeed: 0,
      distance: 0, elevationGain: 0, durationSeconds: 0,
      zeroToHundredSeconds: null, kept: true,
    );
    expect(t.copyWith(maxSpeed: 40).maxSpeed, 40);
    expect(t.copyWith(maxSpeed: 40).kept, true);
  });
}
```

- [ ] **Step 2: Run test to verify it fails.**

Run: `flutter test test/domain/models_test.dart`
Expected: FAIL — `Target of URI doesn't exist`.

- [ ] **Step 3: Implement the three model classes** with `const` constructors, `final` fields, and `Trip.copyWith`. Match the signatures in the Interfaces block exactly.

- [ ] **Step 4: Run test to verify it passes.**

Run: `flutter test test/domain/models_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit.**

```bash
git add lib/domain test/domain
git commit -m "feat: add domain models"
```

---

### Task 3: StatsEngine — distance & duration

**Files:**
- Create: `lib/stats/stats_engine.dart`
- Test: `test/stats/distance_test.dart`

**Interfaces:**
- Produces:
  - `class TripStats { final double maxSpeed, avgSpeed, distance, elevationGain; final int durationSeconds; final double? zeroToHundredSeconds; const TripStats(...); }`
  - `class StatsEngine { static TripStats compute(List<TrackPoint> points); static double haversineMeters(double lat1,double lng1,double lat2,double lng2); }`

- [ ] **Step 1: Write the failing test.**

```dart
// test/stats/distance_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/stats/stats_engine.dart';

void main() {
  test('haversine between two ~111m-apart points', () {
    // 0.001 deg latitude ~= 111.19 m
    final d = StatsEngine.haversineMeters(50.0, 6.0, 50.001, 6.0);
    expect(d, closeTo(111.2, 1.0));
  });
}
```

- [ ] **Step 2: Run test to verify it fails.**

Run: `flutter test test/stats/distance_test.dart`
Expected: FAIL — URI/method missing.

- [ ] **Step 3: Implement `haversineMeters`** (earth radius 6371000 m) and a stub `compute` returning zeros.

- [ ] **Step 4: Run test to verify it passes.**

Run: `flutter test test/stats/distance_test.dart`
Expected: PASS.

- [ ] **Step 5: Add duration + total-distance test.**

```dart
test('compute sums distance and duration', () {
  final t0 = DateTime(2026, 1, 1, 12, 0, 0);
  final pts = [
    TrackPoint(tripId: 1, lat: 50.0, lng: 6.0, speed: 0, altitude: 100, accuracy: 3, timestamp: t0),
    TrackPoint(tripId: 1, lat: 50.001, lng: 6.0, speed: 20, altitude: 100, accuracy: 3, timestamp: t0.add(const Duration(seconds: 10))),
  ];
  final s = StatsEngine.compute(pts);
  expect(s.distance, closeTo(111.2, 1.0));
  expect(s.durationSeconds, 10);
});
```

- [ ] **Step 6: Implement distance summation + duration** (last.timestamp − first.timestamp). Run: `flutter test test/stats/distance_test.dart` → PASS.

- [ ] **Step 7: Commit.**

```bash
git add lib/stats test/stats
git commit -m "feat: stats engine distance and duration"
```

---

### Task 4: StatsEngine — speed, elevation, 0–100

**Files:**
- Modify: `lib/stats/stats_engine.dart`
- Test: `test/stats/metrics_test.dart`

**Interfaces:**
- Consumes: `StatsEngine.compute` and `TripStats` from Task 3.
- Produces: `compute` now fills `maxSpeed`, `avgSpeed`, `elevationGain`, `zeroToHundredSeconds`.

- [ ] **Step 1: Write failing tests.**

```dart
// test/stats/metrics_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/domain/track_point.dart';
import 'package:speedster/stats/stats_engine.dart';

TrackPoint p(double speed, {double alt = 100, int t = 0}) => TrackPoint(
  tripId: 1, lat: 50, lng: 6, speed: speed, altitude: alt, accuracy: 3,
  timestamp: DateTime(2026, 1, 1, 12, 0, t),
);

void main() {
  test('max and avg speed', () {
    final s = StatsEngine.compute([p(0, t: 0), p(10, t: 1), p(30, t: 2)]);
    expect(s.maxSpeed, 30);
    expect(s.avgSpeed, closeTo((0 + 10 + 30) / 3, 0.01));
  });

  test('elevation gain counts only ascents', () {
    final s = StatsEngine.compute([p(5, alt: 100, t: 0), p(5, alt: 120, t: 1), p(5, alt: 110, t: 2), p(5, alt: 130, t: 3)]);
    expect(s.elevationGain, 40); // +20 then +20; the -10 ignored
  });

  test('zeroToHundred: seconds from first >0 to first >=27.78 m/s (100km/h)', () {
    final s = StatsEngine.compute([p(0, t: 0), p(5, t: 1), p(20, t: 3), p(28, t: 5)]);
    expect(s.zeroToHundredSeconds, closeTo(4, 0.001)); // t=1 (first moving) .. t=5
  });

  test('zeroToHundred null when 100 never reached', () {
    final s = StatsEngine.compute([p(0, t: 0), p(10, t: 1)]);
    expect(s.zeroToHundredSeconds, isNull);
  });
}
```

- [ ] **Step 2: Run to verify failure.**

Run: `flutter test test/stats/metrics_test.dart`
Expected: FAIL (values are zero/null from Task 3 stub).

- [ ] **Step 3: Implement** in `compute`:
  - `maxSpeed = max of speeds`.
  - `avgSpeed = mean of speeds` (simple point mean is fine for MVP).
  - `elevationGain = sum of positive altitude deltas between consecutive points`.
  - `zeroToHundredSeconds`: find first point with speed > 0 (`tStart`), first subsequent point with speed >= 27.78 (`tHit`); result = `tHit − tStart` in seconds; null if none.

- [ ] **Step 4: Run to verify pass.**

Run: `flutter test test/stats/metrics_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit.**

```bash
git add lib/stats test/stats
git commit -m "feat: stats engine speed, elevation, 0-100"
```

---

### Task 5: TripDetector state machine

**Files:**
- Create: `lib/detection/trip_detector.dart`
- Test: `test/detection/trip_detector_test.dart`

**Interfaces:**
- Consumes: `Sample` from Task 2.
- Produces:
  - `enum TripEvent { started, stopped }`
  - `class DetectorConfig { final double startSpeed; final double stopSpeed; final Duration startWindow; final Duration stopWindow; final double minAccuracy; const DetectorConfig({this.startSpeed = 2.8, this.stopSpeed = 0.8, this.startWindow = const Duration(seconds: 5), this.stopWindow = const Duration(seconds: 45), this.minAccuracy = 30}); }`
  - `class TripDetector { TripDetector(this.config); final DetectorConfig config; TripEvent? update(Sample s); bool get isDriving; }`
  - `update` returns `TripEvent.started` at the moment a drive is confirmed, `TripEvent.stopped` when the stop window elapses, else `null`. Samples with `accuracy > minAccuracy` are ignored (return null, no state change).

- [ ] **Step 1: Write failing tests.**

```dart
// test/detection/trip_detector_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/domain/sample.dart';
import 'package:speedster/detection/trip_detector.dart';

Sample mv(double speed, int sec, {double acc = 5}) => Sample(
  lat: 50, lng: 6, speed: speed, altitude: 100, accuracy: acc,
  timestamp: DateTime(2026, 1, 1, 12, 0, sec),
);

void main() {
  test('emits started after sustained motion over startWindow', () {
    final d = TripDetector(const DetectorConfig());
    expect(d.update(mv(10, 0)), isNull);   // moving begins
    expect(d.update(mv(10, 3)), isNull);   // still within window
    expect(d.update(mv(10, 6)), TripEvent.started); // window elapsed
    expect(d.isDriving, isTrue);
  });

  test('brief stop under stopWindow does not end trip', () {
    final d = TripDetector(const DetectorConfig());
    d..update(mv(10, 0))..update(mv(10, 6)); // driving
    expect(d.update(mv(0, 10)), isNull);   // red light
    expect(d.update(mv(10, 20)), isNull);  // moving again
    expect(d.isDriving, isTrue);
  });

  test('emits stopped after stopWindow of stillness', () {
    final d = TripDetector(const DetectorConfig());
    d..update(mv(10, 0))..update(mv(10, 6));
    expect(d.update(mv(0, 10)), isNull);
    expect(d.update(mv(0, 60)), TripEvent.stopped); // >45s still
    expect(d.isDriving, isFalse);
  });

  test('ignores low-accuracy samples', () {
    final d = TripDetector(const DetectorConfig());
    expect(d.update(mv(10, 0, acc: 100)), isNull);
    expect(d.update(mv(10, 6, acc: 100)), isNull);
    expect(d.isDriving, isFalse);
  });
}
```

- [ ] **Step 2: Run to verify failure.**

Run: `flutter test test/detection/trip_detector_test.dart`
Expected: FAIL — URI missing.

- [ ] **Step 3: Implement the state machine.** Track `_movingSince` and `_stillSince` from sample timestamps. Not driving: when speed ≥ startSpeed, set/keep `_movingSince`; when `now − _movingSince ≥ startWindow` → set driving, clear timers, return `started`. Driving: when speed ≤ stopSpeed, set/keep `_stillSince`; when speed rises above stopSpeed, clear `_stillSince`; when `now − _stillSince ≥ stopWindow` → clear driving, return `stopped`. Drop samples with `accuracy > minAccuracy` before any logic.

- [ ] **Step 4: Run to verify pass.**

Run: `flutter test test/detection/trip_detector_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit.**

```bash
git add lib/detection test/detection
git commit -m "feat: trip detection state machine"
```

---

### Task 6: Persistence — drift database & TripRepository

**Files:**
- Create: `lib/data/database.dart` (drift tables + generated `database.g.dart`)
- Create: `lib/data/trip_repository.dart` (interface + drift impl)
- Test: `test/data/trip_repository_test.dart`

**Interfaces:**
- Consumes: `Trip`, `TrackPoint` from Task 2.
- Produces:
  - `abstract class TripRepository { Future<int> createTrip(Trip t); Future<void> addPoints(int tripId, List<TrackPoint> pts); Future<void> finalizeTrip(int tripId, TripStats stats, DateTime endTime); Future<void> setKept(int tripId, bool kept); Future<List<Trip>> keptTrips(); Future<List<TrackPoint>> pointsFor(int tripId); Future<void> deleteAll(); }`
  - `class DriftTripRepository implements TripRepository` taking an `AppDatabase`.
  - `AppDatabase` with `Trips` and `TrackPoints` tables mirroring the domain fields; `AppDatabase.forTesting(NativeDatabase.memory())` constructor.

- [ ] **Step 1: Define drift tables** `Trips` and `TrackPoints` in `database.dart` and run codegen.

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 2: Write the failing repository test.**

```dart
// test/data/trip_repository_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/data/database.dart';
import 'package:speedster/data/trip_repository.dart';
import 'package:speedster/domain/track_point.dart';
import 'package:speedster/domain/trip.dart';
import 'package:speedster/stats/stats_engine.dart';

void main() {
  late AppDatabase db;
  late DriftTripRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftTripRepository(db);
  });
  tearDown(() => db.close());

  test('create, add points, finalize, read back', () async {
    final id = await repo.createTrip(Trip(
      startTime: DateTime(2026), endTime: null, maxSpeed: 0, avgSpeed: 0,
      distance: 0, elevationGain: 0, durationSeconds: 0,
      zeroToHundredSeconds: null, kept: true,
    ));
    await repo.addPoints(id, [
      TrackPoint(tripId: id, lat: 50, lng: 6, speed: 10, altitude: 100, accuracy: 3, timestamp: DateTime(2026)),
    ]);
    await repo.finalizeTrip(id, const TripStats(maxSpeed: 10, avgSpeed: 10, distance: 5, elevationGain: 0, durationSeconds: 3, zeroToHundredSeconds: null), DateTime(2026, 1, 1, 12));
    final trips = await repo.keptTrips();
    expect(trips.single.maxSpeed, 10);
    expect((await repo.pointsFor(id)).length, 1);
  });

  test('setKept(false) hides trip from keptTrips', () async {
    final id = await repo.createTrip(Trip(
      startTime: DateTime(2026), endTime: null, maxSpeed: 0, avgSpeed: 0,
      distance: 0, elevationGain: 0, durationSeconds: 0,
      zeroToHundredSeconds: null, kept: true,
    ));
    await repo.setKept(id, false);
    expect(await repo.keptTrips(), isEmpty);
  });
}
```

- [ ] **Step 3: Run to verify failure.**

Run: `flutter test test/data/trip_repository_test.dart`
Expected: FAIL — types/methods missing.

- [ ] **Step 4: Implement `TripRepository` interface and `DriftTripRepository`.** Map domain ↔ drift rows. `keptTrips()` filters `kept = true` ordered by `startTime` desc.

- [ ] **Step 5: Run to verify pass.**

Run: `flutter test test/data/trip_repository_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit.**

```bash
git add lib/data test/data
git commit -m "feat: drift persistence and trip repository"
```

---

### Task 7: Sensor layer (GPS + accelerometer → Sample stream)

**Files:**
- Create: `lib/sensors/location_service.dart`
- Test: `test/sensors/location_service_test.dart`

**Interfaces:**
- Produces:
  - `abstract class SampleSource { Stream<Sample> samples(); }`
  - `class GeolocatorSampleSource implements SampleSource` — maps `geolocator` `Position` to `Sample` (speed from `position.speed`, altitude, accuracy), merging latest accelerometer magnitude from `sensors_plus`.
  - `class FakeSampleSource implements SampleSource` — replays a provided `List<Sample>`; used in tests and later widget tests.

- [ ] **Step 1: Write failing test for the fake source** (the real geolocator source is exercised in on-device QA, not unit tests).

```dart
// test/sensors/location_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/domain/sample.dart';
import 'package:speedster/sensors/location_service.dart';

void main() {
  test('FakeSampleSource replays samples in order', () async {
    final samples = [
      Sample(lat: 50, lng: 6, speed: 0, altitude: 100, accuracy: 3, timestamp: DateTime(2026, 1, 1, 12, 0, 0)),
      Sample(lat: 50, lng: 6, speed: 10, altitude: 100, accuracy: 3, timestamp: DateTime(2026, 1, 1, 12, 0, 1)),
    ];
    final src = FakeSampleSource(samples);
    expect(await src.samples().toList(), samples);
  });
}
```

- [ ] **Step 2: Run to verify failure.**

Run: `flutter test test/sensors/location_service_test.dart`
Expected: FAIL — URI missing.

- [ ] **Step 3: Implement `SampleSource`, `FakeSampleSource`, and `GeolocatorSampleSource`.** For the geolocator source, configure `LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 0)` and keep a subscription to `userAccelerometerEvents` storing the latest magnitude `sqrt(x²+y²+z²)`.

- [ ] **Step 4: Run to verify pass.**

Run: `flutter test test/sensors/location_service_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit.**

```bash
git add lib/sensors test/sensors
git commit -m "feat: sensor sample source"
```

---

### Task 8: TripRecorder — orchestrates detection, recording, finalization

**Files:**
- Create: `lib/recording/trip_recorder.dart`
- Test: `test/recording/trip_recorder_test.dart`

**Interfaces:**
- Consumes: `SampleSource` (Task 7), `TripDetector` (Task 5), `TripRepository` (Task 6), `StatsEngine` (Task 3/4).
- Produces:
  - `class TripRecorder { TripRecorder({required SampleSource source, required TripDetector detector, required TripRepository repo}); Stream<RecorderState> get state; Future<void> start(); Future<void> stop(); }`
  - `class RecorderState { final bool isDriving; final int? activeTripId; final Sample? last; }`
  - On `TripEvent.started`: create a Trip row, begin buffering points. On each sample while driving: append `TrackPoint`, flush to repo every N (e.g. 10) points. On `TripEvent.stopped`: flush remaining, compute `StatsEngine.compute(points)`, `finalizeTrip`, emit an `awaitingConfirmation` trip id.

- [ ] **Step 1: Write the failing integration-style test with fakes.**

```dart
// test/recording/trip_recorder_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/data/database.dart';
import 'package:speedster/data/trip_repository.dart';
import 'package:speedster/detection/trip_detector.dart';
import 'package:speedster/domain/sample.dart';
import 'package:speedster/recording/trip_recorder.dart';
import 'package:speedster/sensors/location_service.dart';

Sample s(double speed, int sec) => Sample(lat: 50, lng: 6, speed: speed, altitude: 100, accuracy: 3, timestamp: DateTime(2026, 1, 1, 12, 0, sec));

void main() {
  test('records a full trip from motion to stop', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repo = DriftTripRepository(db);
    final source = FakeSampleSource([
      s(10, 0), s(10, 6),           // start
      s(20, 10), s(28, 14),         // driving
      s(0, 20), s(0, 70),           // stop after stopWindow
    ]);
    final rec = TripRecorder(source: source, detector: TripDetector(const DetectorConfig()), repo: repo);
    await rec.start();
    await rec.stop();
    final trips = await repo.keptTrips();
    expect(trips, hasLength(1));
    expect(trips.single.maxSpeed, 28);
    await db.close();
  });
}
```

- [ ] **Step 2: Run to verify failure.**

Run: `flutter test test/recording/trip_recorder_test.dart`
Expected: FAIL — URI missing.

- [ ] **Step 3: Implement `TripRecorder`.** Subscribe to `source.samples()`, feed each to `detector.update`, act on events per the Interfaces block. Keep an in-memory `List<TrackPoint>` for the active trip to pass to `StatsEngine`.

- [ ] **Step 4: Run to verify pass.**

Run: `flutter test test/recording/trip_recorder_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit.**

```bash
git add lib/recording test/recording
git commit -m "feat: trip recorder orchestration"
```

---

### Task 9: Settings & units (model + formatter)

**Files:**
- Create: `lib/settings/unit_system.dart`
- Create: `lib/settings/settings_controller.dart` (Riverpod, persisted via `shared_preferences`)
- Test: `test/settings/unit_system_test.dart`

**Interfaces:**
- Produces:
  - `enum UnitSystem { kmh, mph }`
  - `class SpeedFormat { static String speed(double mps, UnitSystem u); static String distance(double meters, UnitSystem u); }` — km/h: `mps*3.6`; mph: `mps*2.23694`; distance km vs miles.

- [ ] **Step 1: Add `shared_preferences`.** `flutter pub add shared_preferences`.

- [ ] **Step 2: Write failing test.**

```dart
// test/settings/unit_system_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/settings/unit_system.dart';

void main() {
  test('formats speed in km/h', () {
    expect(SpeedFormat.speed(10, UnitSystem.kmh), '36 km/h');
  });
  test('formats speed in mph', () {
    expect(SpeedFormat.speed(10, UnitSystem.mph), '22 mph');
  });
}
```

- [ ] **Step 3: Run to verify failure.** `flutter test test/settings/unit_system_test.dart` → FAIL.

- [ ] **Step 4: Implement `UnitSystem` + `SpeedFormat`** (round to integer for speed display). Implement `settingsControllerProvider` persisting the chosen unit and detector thresholds.

- [ ] **Step 5: Run to verify pass.** → PASS.

- [ ] **Step 6: Commit.**

```bash
git add lib/settings test/settings pubspec.yaml
git commit -m "feat: settings and unit formatting"
```

---

### Task 10: App state wiring (Riverpod providers) & permissions

**Files:**
- Create: `lib/app/providers.dart`
- Create: `lib/app/permissions.dart`
- Test: `test/app/permissions_test.dart`

**Interfaces:**
- Consumes: all prior services.
- Produces:
  - Providers: `databaseProvider`, `tripRepositoryProvider`, `recorderProvider`, `keptTripsProvider` (FutureProvider), `recorderStateProvider` (StreamProvider).
  - `class LocationPermissions { Future<bool> ensure(); }` wrapping `permission_handler` (request whileInUse + always/background). Abstracted behind an interface `PermissionGate` so it can be faked.

- [ ] **Step 1: Write failing test for a fake permission gate flow.**

```dart
// test/app/permissions_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/app/permissions.dart';

void main() {
  test('recorder does not start when permission denied', () async {
    final gate = FakePermissionGate(granted: false);
    expect(await gate.ensure(), isFalse);
  });
}
```

- [ ] **Step 2: Run to verify failure.** → FAIL.

- [ ] **Step 3: Implement `PermissionGate`, `LocationPermissions`, `FakePermissionGate`, and the providers.**

- [ ] **Step 4: Run to verify pass.** → PASS.

- [ ] **Step 5: Configure native permission strings.**
  - iOS `ios/Runner/Info.plist`: `NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysAndWhenInUseUsageDescription`, `UIBackgroundModes` → `location`.
  - Android `android/app/src/main/AndroidManifest.xml`: `ACCESS_FINE_LOCATION`, `ACCESS_BACKGROUND_LOCATION`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION`.

- [ ] **Step 6: Commit.**

```bash
git add lib/app test/app ios android
git commit -m "feat: providers and location permissions"
```

---

### Task 11: Onboarding / Consent screen

**Files:**
- Create: `lib/ui/consent_screen.dart`
- Test: `test/ui/consent_screen_test.dart`

**Interfaces:**
- Consumes: `settingsControllerProvider`.
- Produces: `ConsentScreen` widget; sets a persisted `consentAccepted` flag; `main` routes to it when not yet accepted.

- [ ] **Step 1: Write failing widget test** asserting the disclaimer text renders and the "Akzeptieren" button is present.

```dart
// test/ui/consent_screen_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedster/ui/consent_screen.dart';

void main() {
  testWidgets('shows disclaimer and accept button', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ConsentScreen()));
    expect(find.textContaining('eigene Gefahr'), findsOneWidget);
    expect(find.text('Akzeptieren'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run to verify failure.** → FAIL.

- [ ] **Step 3: Implement `ConsentScreen`** wrapped in `MaterialApp` internally for the test, with disclaimer copy (StVO, eigene Gefahr, Autobahn-Hinweis) and an Akzeptieren button.

- [ ] **Step 4: Run to verify pass.** → PASS.

- [ ] **Step 5: Commit.**

```bash
git add lib/ui/consent_screen.dart test/ui/consent_screen_test.dart
git commit -m "feat: consent screen"
```

---

### Task 12: Live driving screen

**Files:**
- Create: `lib/ui/live_screen.dart`
- Test: `test/ui/live_screen_test.dart`

**Interfaces:**
- Consumes: `recorderStateProvider`, `settingsControllerProvider`.
- Produces: `LiveScreen` showing big current speed, elapsed duration, live distance, and a stop control.

- [ ] **Step 1: Write failing widget test** that overrides `recorderStateProvider` with a fake driving state and asserts the formatted speed shows.

```dart
// test/ui/live_screen_test.dart — overrides recorderStateProvider with a RecorderState(isDriving:true,last: Sample(speed:10,...))
// expect(find.textContaining('36 km/h'), findsOneWidget);
```

- [ ] **Step 2: Run to verify failure.** → FAIL.

- [ ] **Step 3: Implement `LiveScreen`** consuming the provider; format speed via `SpeedFormat`.

- [ ] **Step 4: Run to verify pass.** → PASS.

- [ ] **Step 5: Commit.**

```bash
git add lib/ui/live_screen.dart test/ui/live_screen_test.dart
git commit -m "feat: live driving screen"
```

---

### Task 13: Trip list screen

**Files:**
- Create: `lib/ui/trip_list_screen.dart`
- Test: `test/ui/trip_list_screen_test.dart`

**Interfaces:**
- Consumes: `keptTripsProvider`, `settingsControllerProvider`.
- Produces: `TripListScreen` rendering a card per trip (date, max speed, distance, duration); tap → `TripDetailScreen`.

- [ ] **Step 1: Write failing widget test** overriding `keptTripsProvider` with two fake trips; assert two cards render with formatted max speed.

- [ ] **Step 2: Run to verify failure.** → FAIL.

- [ ] **Step 3: Implement `TripListScreen`.**

- [ ] **Step 4: Run to verify pass.** → PASS.

- [ ] **Step 5: Commit.**

```bash
git add lib/ui/trip_list_screen.dart test/ui/trip_list_screen_test.dart
git commit -m "feat: trip list screen"
```

---

### Task 14: Trip detail screen with map & stat tiles

**Files:**
- Create: `lib/ui/trip_detail_screen.dart`
- Test: `test/ui/trip_detail_screen_test.dart`

**Interfaces:**
- Consumes: `tripRepositoryProvider` (for `pointsFor`), `settingsControllerProvider`.
- Produces: `TripDetailScreen(trip)` — `flutter_map` with an OSM `TileLayer` and a `PolylineLayer` of the trip's points, plus stat tiles (max/avg speed, distance, duration, 0–100, elevation).

- [ ] **Step 1: Write failing widget test** overriding the repo to return a fixed point list; assert stat tile texts render (map tiles are not asserted — network). Use a fake repo returning points.

- [ ] **Step 2: Run to verify failure.** → FAIL.

- [ ] **Step 3: Implement `TripDetailScreen`.** OSM tiles URL `https://tile.openstreetmap.org/{z}/{x}/{y}.png` with required attribution widget.

- [ ] **Step 4: Run to verify pass.** → PASS.

- [ ] **Step 5: Commit.**

```bash
git add lib/ui/trip_detail_screen.dart test/ui/trip_detail_screen_test.dart
git commit -m "feat: trip detail screen with map"
```

---

### Task 15: Driver-confirmation prompt (passenger protection)

**Files:**
- Create: `lib/ui/driver_prompt.dart`
- Modify: `lib/ui/trip_list_screen.dart` (surface pending confirmation)
- Test: `test/ui/driver_prompt_test.dart`

**Interfaces:**
- Consumes: `tripRepositoryProvider` (`setKept`), recorder's `awaitingConfirmation` trip id.
- Produces: `DriverPrompt` dialog with "Selbst gefahren? Behalten / Verwerfen"; Behalten → `setKept(id, true)`, Verwerfen → `setKept(id, false)`.

- [ ] **Step 1: Write failing widget test** pumping `DriverPrompt`; tap "Verwerfen"; assert the fake repo recorded `setKept(id, false)`.

- [ ] **Step 2: Run to verify failure.** → FAIL.

- [ ] **Step 3: Implement `DriverPrompt`** and wire it to appear after a trip stops.

- [ ] **Step 4: Run to verify pass.** → PASS.

- [ ] **Step 5: Commit.**

```bash
git add lib/ui/driver_prompt.dart lib/ui/trip_list_screen.dart test/ui/driver_prompt_test.dart
git commit -m "feat: driver confirmation prompt"
```

---

### Task 16: Settings screen (units, thresholds, pause, delete all)

**Files:**
- Create: `lib/ui/settings_screen.dart`
- Test: `test/ui/settings_screen_test.dart`

**Interfaces:**
- Consumes: `settingsControllerProvider`, `tripRepositoryProvider` (`deleteAll`).
- Produces: `SettingsScreen` — unit toggle (km/h ↔ mph), tracking pause switch, "Alle Daten löschen" with a confirm, disclaimer re-display.

- [ ] **Step 1: Write failing widget test** toggling units and asserting the controller state updates.

- [ ] **Step 2: Run to verify failure.** → FAIL.

- [ ] **Step 3: Implement `SettingsScreen`.**

- [ ] **Step 4: Run to verify pass.** → PASS.

- [ ] **Step 5: Commit.**

```bash
git add lib/ui/settings_screen.dart test/ui/settings_screen_test.dart
git commit -m "feat: settings screen"
```

---

### Task 17: App shell, routing, and main integration

**Files:**
- Modify: `lib/main.dart`
- Create: `lib/app/app.dart` (root widget, bottom nav: Live / Fahrten / Einstellungen)
- Test: `test/app/app_smoke_test.dart`

**Interfaces:**
- Consumes: all screens + providers.
- Produces: `SpeedsterApp` root; routes to `ConsentScreen` if consent not accepted, else the tabbed shell; starts the recorder (when permission granted and tracking not paused).

- [ ] **Step 1: Write failing smoke test** pumping `SpeedsterApp` with consent pre-accepted and fake providers; assert the bottom nav renders three tabs.

- [ ] **Step 2: Run to verify failure.** → FAIL.

- [ ] **Step 3: Implement `SpeedsterApp` and rewrite `main.dart`** to `runApp(ProviderScope(child: SpeedsterApp()))`.

- [ ] **Step 4: Run to verify pass + full suite.**

Run: `flutter test`
Expected: all PASS.

- [ ] **Step 5: Static analysis.**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 6: Commit.**

```bash
git add lib/main.dart lib/app/app.dart test/app/app_smoke_test.dart
git commit -m "feat: app shell and integration"
```

---

### Task 18: On-device QA pass (manual, documented)

**Files:**
- Create: `docs/qa/mvp-device-checklist.md`

- [ ] **Step 1: Build & run on a real iPhone and Android device** (`flutter run --release`). Simulators lack real GPS.
- [ ] **Step 2: Walk/drive through:** permission grant flow, auto-start after sustained motion, live speed matches speedometer roughly, brief stop (red light) does not split trip, stop after parking ends trip, driver prompt appears, trip detail shows the route polyline and correct stats, delete-all clears data.
- [ ] **Step 3: Record results** in the checklist file; file follow-up issues for any threshold tuning needed (`DetectorConfig` defaults).
- [ ] **Step 4: Commit.**

```bash
git add docs/qa/mvp-device-checklist.md
git commit -m "docs: MVP device QA checklist"
```

---

## Self-Review

**Spec coverage:**
- Auto-detection → Task 5, wired in 8, tuned in 18. ✓
- Passenger protection prompt → Task 15. ✓
- Stats (max/avg speed, distance, duration, 0–100, elevation) → Tasks 3–4. ✓
- Route on map → Task 14. ✓
- Live/List/Detail/Settings/Consent screens → Tasks 11–17. ✓
- Local persistence → Task 6. ✓
- Units km/h↔mph → Task 9. ✓
- Disclaimer/GDPR (local only, delete all) → Tasks 11, 16. ✓
- Background location / permissions → Task 10. ✓
- Repository abstraction for future cloud → Task 6 interface. ✓

**Placeholder scan:** UI tasks (12–16) describe test intent in prose rather than full Dart in a couple of steps; the interfaces and assertions are specified concretely. Logic-heavy tasks (2–10) carry full code. Acceptable for a plan; implementer has exact providers/overrides to write against.

**Type consistency:** `Sample`, `TrackPoint`, `Trip`, `TripStats`, `DetectorConfig`, `TripEvent`, `RecorderState`, `TripRepository` method names are used identically across tasks. ✓
