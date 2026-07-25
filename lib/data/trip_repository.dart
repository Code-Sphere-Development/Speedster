import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:speedster/data/database.dart';
import 'package:speedster/domain/track_point.dart' as domain;
import 'package:speedster/domain/trip.dart' as domain;
import 'package:speedster/stats/stats_engine.dart';

/// Storage boundary for trips. A Phase-2 cloud sync adds a remote
/// implementation without touching callers.
abstract class TripRepository {
  Future<int> createTrip(domain.Trip t);
  Future<void> addPoints(int tripId, List<domain.TrackPoint> pts);
  Future<void> finalizeTrip(int tripId, TripStats stats, DateTime endTime);
  Future<void> setKept(int tripId, bool kept);
  Future<List<domain.Trip>> keptTrips();
  Future<List<domain.TrackPoint>> pointsFor(int tripId);
  Future<void> deleteAll();
  Future<List<domain.Trip>> unsyncedTrips();
  Future<void> markSynced(String clientUuid);
}

class DriftTripRepository implements TripRepository {
  DriftTripRepository(this.db);

  final AppDatabase db;

  @override
  Future<int> createTrip(domain.Trip t) {
    final clientUuid = t.clientUuid.isEmpty ? const Uuid().v4() : t.clientUuid;
    return db.into(db.trips).insert(
          TripsCompanion.insert(
            startTime: t.startTime,
            endTime: Value(t.endTime),
            maxSpeed: Value(t.maxSpeed),
            avgSpeed: Value(t.avgSpeed),
            distance: Value(t.distance),
            elevationGain: Value(t.elevationGain),
            durationSeconds: Value(t.durationSeconds),
            zeroToHundredSeconds: Value(t.zeroToHundredSeconds),
            kept: Value(t.kept),
            clientUuid: Value(clientUuid),
            syncedAt: Value(t.syncedAt),
          ),
        );
  }

  @override
  Future<void> addPoints(int tripId, List<domain.TrackPoint> pts) async {
    await db.batch((b) {
      b.insertAll(
        db.trackPoints,
        pts.map(
          (p) => TrackPointsCompanion.insert(
            tripId: tripId,
            lat: p.lat,
            lng: p.lng,
            speed: p.speed,
            altitude: p.altitude,
            accuracy: p.accuracy,
            timestamp: p.timestamp,
          ),
        ),
      );
    });
  }

  @override
  Future<void> finalizeTrip(
    int tripId,
    TripStats stats,
    DateTime endTime,
  ) async {
    await (db.update(db.trips)..where((t) => t.id.equals(tripId))).write(
      TripsCompanion(
        endTime: Value(endTime),
        maxSpeed: Value(stats.maxSpeed),
        avgSpeed: Value(stats.avgSpeed),
        distance: Value(stats.distance),
        elevationGain: Value(stats.elevationGain),
        durationSeconds: Value(stats.durationSeconds),
        zeroToHundredSeconds: Value(stats.zeroToHundredSeconds),
      ),
    );
  }

  @override
  Future<void> setKept(int tripId, bool kept) async {
    await (db.update(db.trips)..where((t) => t.id.equals(tripId)))
        .write(TripsCompanion(kept: Value(kept)));
  }

  @override
  Future<List<domain.Trip>> keptTrips() async {
    final rows = await (db.select(db.trips)
          ..where((t) => t.kept.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.startTime)]))
        .get();
    return rows.map(_toDomainTrip).toList();
  }

  @override
  Future<List<domain.TrackPoint>> pointsFor(int tripId) async {
    final rows = await (db.select(db.trackPoints)
          ..where((p) => p.tripId.equals(tripId))
          ..orderBy([(p) => OrderingTerm.asc(p.timestamp)]))
        .get();
    return rows
        .map(
          (r) => domain.TrackPoint(
            id: r.id,
            tripId: r.tripId,
            lat: r.lat,
            lng: r.lng,
            speed: r.speed,
            altitude: r.altitude,
            accuracy: r.accuracy,
            timestamp: r.timestamp,
          ),
        )
        .toList();
  }

  @override
  Future<void> deleteAll() async {
    await db.delete(db.trackPoints).go();
    await db.delete(db.trips).go();
  }

  @override
  Future<List<domain.Trip>> unsyncedTrips() async {
    final rows = await (db.select(db.trips)
          ..where((t) => t.kept.equals(true) & t.syncedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
        .get();
    return rows.map(_toDomainTrip).toList();
  }

  @override
  Future<void> markSynced(String clientUuid) async {
    await (db.update(db.trips)..where((t) => t.clientUuid.equals(clientUuid)))
        .write(TripsCompanion(syncedAt: Value(DateTime.now())));
  }

  domain.Trip _toDomainTrip(Trip r) => domain.Trip(
        id: r.id,
        startTime: r.startTime,
        endTime: r.endTime,
        maxSpeed: r.maxSpeed,
        avgSpeed: r.avgSpeed,
        distance: r.distance,
        elevationGain: r.elevationGain,
        durationSeconds: r.durationSeconds,
        zeroToHundredSeconds: r.zeroToHundredSeconds,
        kept: r.kept,
        clientUuid: r.clientUuid,
        syncedAt: r.syncedAt,
      );
}
