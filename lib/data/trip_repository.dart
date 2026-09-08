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

  /// Lokal bekannte `client_uuid`s auf ihre lokale Zeilen-Id.
  ///
  /// Zwei Aufgaben: der Cache ueberspringt damit Fahrten, die schon hier
  /// liegen (und laesst sich deshalb nach einem Netzabbruch beliebig oft
  /// wiederholen), und die Cloud-Fahrtenliste findet darueber heraus,
  /// welche ihrer Eintraege lokal vorliegen -- fuer die braucht die
  /// Detailansicht dann kein Netz.
  Future<Map<String, int>> clientUuidIndex();

  /// Verwirft lokale Fahrten jenseits der [keep] neuesten.
  ///
  /// Nur Fahrten mit gesetztem `syncedAt` werden verworfen: was der Server
  /// noch nicht bestaetigt hat, existiert nur hier und darf nicht
  /// weggeraeumt werden. Gibt die Zahl der verworfenen Fahrten zurueck.
  ///
  /// Die Heatmap-Aggregate bleiben unangetastet -- sie haengen nicht am
  /// Fremdschluessel und sollen den Cache ueberdauern.
  Future<int> evictSyncedBeyond(int keep);
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
    if (!kept) {
      await _invalidateHeat();
    }
  }

  /// Verwirft die Heatmap-Aggregate und markiert alle Fahrten als ungefaltet.
  ///
  /// Der Neuaufbau passiert beim naechsten Laden der Heatmap, nicht hier:
  /// der Nutzer soll im Beifahrer-Dialog nicht auf eine Aggregation warten.
  /// Eine Fahrt exakt herauszurechnen waere fehleranfaelliger als ein
  /// Neuaufbau, und Ruecknahmen sind selten.
  Future<void> _invalidateHeat() async {
    await db.delete(db.heatEdges).go();
    await db.delete(db.heatCells).go();
    await db.update(db.trips).write(
          const TripsCompanion(heatFoldedAt: Value(null)),
        );
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
    // Sonst ueberlebt die Heatmap ein "alle Daten loeschen": die Aggregate
    // liegen in eigenen Tabellen und haengen nicht am Trip-Fremdschluessel.
    await db.delete(db.heatEdges).go();
    await db.delete(db.heatCells).go();
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

  @override
  Future<Map<String, int>> clientUuidIndex() async {
    final rows = await (db.selectOnly(db.trips)
          ..addColumns([db.trips.clientUuid, db.trips.id]))
        .get();
    final index = <String, int>{};
    for (final row in rows) {
      final uuid = row.read(db.trips.clientUuid);
      final id = row.read(db.trips.id);
      if (uuid != null && uuid.isNotEmpty && id != null) {
        index[uuid] = id;
      }
    }
    return index;
  }

  @override
  Future<int> evictSyncedBeyond(int keep) async {
    final newest = await (db.select(db.trips)
          ..orderBy([(t) => OrderingTerm.desc(t.startTime)])
          ..limit(keep))
        .get();
    final protectedIds = newest.map((t) => t.id).toList();

    final victims = await (db.select(db.trips)
          ..where((t) => t.syncedAt.isNotNull() & t.id.isNotIn(protectedIds)))
        .get();
    if (victims.isEmpty) return 0;

    final ids = victims.map((t) => t.id).toList();
    // Punkte ausdruecklich loeschen: der Fremdschluessel traegt zwar
    // onDelete: cascade, aber SQLite setzt das nur bei eingeschaltetem
    // `PRAGMA foreign_keys` durch, und die App schaltet es nicht ein.
    // Ohne diese Zeile blieben verwaiste Punkte liegen -- also genau der
    // Speicher, den der Cache einsparen soll.
    await (db.delete(db.trackPoints)..where((p) => p.tripId.isIn(ids))).go();
    await (db.delete(db.trips)..where((t) => t.id.isIn(ids))).go();
    return victims.length;
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
