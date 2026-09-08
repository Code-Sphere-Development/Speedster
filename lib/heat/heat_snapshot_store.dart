import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:speedster/data/database.dart';
import 'package:speedster/heat/heat_map.dart';

/// Legt die zuletzt erfolgreich geladene Cloud-Heatmap ab und gibt sie ohne
/// Netz wieder heraus.
///
/// Der Vorrat ersetzt bei aktiver Cloud das lokale Nachrechnen: es liegen
/// nur noch die zuletzt gefahrenen Strecken als Punkte auf dem Geraet, aus
/// denen sich die vollstaendige Heatmap nicht mehr erzeugen laesst.
///
/// Er kostet keine zusaetzlichen Abfragen -- gespeichert wird, was die
/// Heatmap ohnehin geladen hat.
class HeatSnapshotStore {
  HeatSnapshotStore(this.db);

  final AppDatabase db;

  /// Nur ungefilterte Abfragen sind als Vorrat brauchbar: eine auf einen
  /// Kartenausschnitt beschnittene Antwort waere wertlos, sobald der
  /// Nutzer die Karte verschiebt.
  bool storable(HeatQuery query) => query.bounds == null;

  Future<void> write(HeatQuery query, HeatMap map) async {
    if (!storable(query)) return;
    await db.into(db.heatSnapshots).insertOnConflictUpdate(
          HeatSnapshotsCompanion.insert(
            level: query.level,
            range: query.range.wire,
            payload: jsonEncode(_encode(map)),
            fetchedAt: DateTime.now(),
          ),
        );
  }

  /// Gibt den Vorrat zur Ebene und zum Zeitraum der Abfrage zurueck, auch
  /// wenn diese einen Kartenausschnitt nennt: gespeichert ist immer der
  /// gesamte Bereich, und zu viele Kanten schneidet die Zeichenebene beim
  /// Malen ohnehin weg.
  Future<HeatMap?> read(HeatQuery query) async {
    final row = await (db.select(db.heatSnapshots)
          ..where((s) =>
              s.level.equals(query.level) & s.range.equals(query.range.wire)))
        .getSingleOrNull();
    if (row == null) return null;
    return _decode(jsonDecode(row.payload) as Map<String, dynamic>);
  }

  Future<void> clear() => db.delete(db.heatSnapshots).go();

  /// Kanten als flache Zahlenlisten statt benannter Felder: bei mehreren
  /// zehntausend Kanten spart das ein Vielfaches an Zeichen gegenueber
  /// wiederholten Schluesselnamen.
  static Map<String, dynamic> _encode(HeatMap map) => {
        'm': map.maxCount,
        'e': [
          for (final e in map.edges) [e.aLat, e.aLng, e.bLat, e.bLng, e.count],
        ],
      };

  static HeatMap _decode(Map<String, dynamic> raw) {
    final edges = <HeatEdgeView>[];
    for (final item in (raw['e'] as List? ?? const [])) {
      final e = (item as List).cast<num>();
      edges.add(
        HeatEdgeView(
          aLat: e[0].toDouble(),
          aLng: e[1].toDouble(),
          bLat: e[2].toDouble(),
          bLng: e[3].toDouble(),
          count: e[4].toInt(),
        ),
      );
    }
    return HeatMap(edges: edges, maxCount: (raw['m'] as num?)?.toInt() ?? 0);
  }
}
