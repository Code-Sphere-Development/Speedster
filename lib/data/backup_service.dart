import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:speedster/data/database.dart';

/// Ergebnis eines Einlesens.
class BackupImport {
  const BackupImport({required this.imported, required this.skipped});

  final int imported;

  /// Fahrten, die es unter derselben `client_uuid` schon gab.
  final int skipped;
}

/// Sichert die Fahrten des Geraets in eine Datei und liest sie zurueck.
///
/// Gedacht fuer den Wechsel des Telefons ohne Cloud: ohne
/// Synchronisierung liegen die Fahrten ausschliesslich hier, und ein
/// neues Geraet faenge sonst bei null an.
///
/// JSON und nicht die Datenbankdatei selbst: die traegt ein Schema, das
/// sich mit der naechsten Version aendert, und laesst sich nicht ansehen.
/// Diese Datei kann jeder oeffnen, und das gehoert zu der Zusage, dass die
/// Daten dem Nutzer gehoeren.
class BackupService {
  BackupService(this.db, this.directory);

  final AppDatabase db;

  /// Wohin gesichert wird. Auf dem Geraet der Dokumentenordner der App --
  /// er ist ueber die Dateien-App erreichbar, sodass sich die Sicherung
  /// von dort wegkopieren laesst.
  final Directory directory;

  /// Fassung des Dateiformats. Steigt sie, kann ein spaeterer Stand alte
  /// Dateien noch lesen -- ohne diese Zahl bliebe nur Raten.
  static const formatVersion = 1;

  Future<File> export({DateTime? now}) async {
    final stamp = (now ?? DateTime.now()).toIso8601String().split('T').first;
    final file = File('${directory.path}/speedster-sicherung-$stamp.json');

    final trips = await db.select(db.trips).get();
    final points = await db.select(db.trackPoints).get();
    final byTrip = <int, List<TrackPoint>>{};
    for (final point in points) {
      byTrip.putIfAbsent(point.tripId, () => []).add(point);
    }

    final payload = {
      'version': formatVersion,
      'exported_at': (now ?? DateTime.now()).toIso8601String(),
      'trips': [
        for (final trip in trips)
          {
            'client_uuid': trip.clientUuid,
            'start_time': trip.startTime.toIso8601String(),
            'end_time': trip.endTime?.toIso8601String(),
            'max_speed': trip.maxSpeed,
            'avg_speed': trip.avgSpeed,
            'distance': trip.distance,
            'elevation_gain': trip.elevationGain,
            'duration_seconds': trip.durationSeconds,
            'zero_to_hundred_seconds': trip.zeroToHundredSeconds,
            'kept': trip.kept,
            'purpose': trip.purpose,
            'note': trip.note,
            'cloud_vehicle_id': trip.cloudVehicleId,
            'points': [
              for (final p in byTrip[trip.id] ?? const <TrackPoint>[])
                {
                  'lat': p.lat,
                  'lng': p.lng,
                  'speed': p.speed,
                  'altitude': p.altitude,
                  'accuracy': p.accuracy,
                  't': p.timestamp.toIso8601String(),
                },
            ],
          },
      ],
    };

    await file.writeAsString(jsonEncode(payload));

    return file;
  }

  /// Liest eine Sicherung ein.
  ///
  /// Fahrten, die es unter derselben `client_uuid` schon gibt, werden
  /// uebergangen -- zweimal einlesen fuehrt damit nicht zu doppelten
  /// Fahrten, und eine Sicherung laesst sich auch auf ein Geraet mit
  /// Bestand legen.
  ///
  /// `heatFoldedAt` bleibt leer: die Heatmap faltet die neuen Fahrten beim
  /// naechsten Oeffnen selbst nach.
  Future<BackupImport> importFrom(File file) async {
    final raw = jsonDecode(await file.readAsString());
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('Keine Speedster-Sicherung.');
    }

    final version = raw['version'];
    if (version is! int || version > formatVersion) {
      throw FormatException('Unbekannte Fassung der Sicherung: $version');
    }

    final existing = {
      for (final trip in await db.select(db.trips).get()) trip.clientUuid,
    };

    var imported = 0;
    var skipped = 0;

    for (final entry in raw['trips'] as List? ?? const []) {
      final trip = Map<String, dynamic>.from(entry as Map);
      final uuid = trip['client_uuid'] as String? ?? '';

      if (uuid.isEmpty || existing.contains(uuid)) {
        skipped++;
        continue;
      }

      await db.transaction(() async {
        final id = await db.into(db.trips).insert(
              TripsCompanion.insert(
                startTime: DateTime.parse(trip['start_time'] as String),
                endTime: Value(trip['end_time'] == null
                    ? null
                    : DateTime.parse(trip['end_time'] as String)),
                maxSpeed: Value((trip['max_speed'] as num?)?.toDouble() ?? 0),
                avgSpeed: Value((trip['avg_speed'] as num?)?.toDouble() ?? 0),
                distance: Value((trip['distance'] as num?)?.toDouble() ?? 0),
                elevationGain:
                    Value((trip['elevation_gain'] as num?)?.toDouble() ?? 0),
                durationSeconds:
                    Value((trip['duration_seconds'] as num?)?.toInt() ?? 0),
                zeroToHundredSeconds:
                    Value((trip['zero_to_hundred_seconds'] as num?)?.toDouble()),
                kept: Value(trip['kept'] as bool? ?? true),
                clientUuid: Value(uuid),
                purpose: Value(trip['purpose'] as String?),
                note: Value(trip['note'] as String?),
                cloudVehicleId: Value((trip['cloud_vehicle_id'] as num?)?.toInt()),
              ),
            );

        for (final entry in trip['points'] as List? ?? const []) {
          final point = Map<String, dynamic>.from(entry as Map);
          await db.into(db.trackPoints).insert(
                TrackPointsCompanion.insert(
                  tripId: id,
                  lat: (point['lat'] as num).toDouble(),
                  lng: (point['lng'] as num).toDouble(),
                  speed: (point['speed'] as num?)?.toDouble() ?? 0,
                  altitude: (point['altitude'] as num?)?.toDouble() ?? 0,
                  accuracy: (point['accuracy'] as num?)?.toDouble() ?? 0,
                  timestamp: DateTime.parse(point['t'] as String),
                ),
              );
        }
      });

      existing.add(uuid);
      imported++;
    }

    return BackupImport(imported: imported, skipped: skipped);
  }

  /// Sicherungen, die im Ordner liegen -- neueste zuerst.
  Future<List<File>> available() async {
    if (!directory.existsSync()) return const [];

    final files = directory
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList()
      ..sort((a, b) => b.path.compareTo(a.path));

    return files;
  }
}
