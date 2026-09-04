import 'package:speedster/data/database.dart';
import 'package:speedster/heat/heat_folder.dart';
import 'package:speedster/heat/heat_map.dart';
import 'package:speedster/heat/heat_source.dart';

/// Leseseite lokal. Faltet vor dem Lesen offene Fahrten nach, damit auch
/// nach einer Migration oder einer Ruecknahme nichts fehlt.
class LocalHeatSource implements HeatSource {
  LocalHeatSource(this.db, this.folder);

  final AppDatabase db;
  final HeatFolder folder;

  @override
  Future<HeatMap> load(HeatQuery query) async {
    await folder.foldPending();

    final centroids = <int, Map<int, ({double lat, double lng})>>{};
    for (final c in await (db.select(db.heatCells)
          ..where((c) => c.level.equals(query.level)))
        .get()) {
      if (c.n == 0) continue;
      centroids.putIfAbsent(c.cellRow, () => {})[c.cellCol] =
          (lat: c.latSum / c.n, lng: c.lngSum / c.n);
    }

    final rows = await (db.select(db.heatEdges)
          ..where((e) => e.level.equals(query.level)))
        .get();

    var maxCount = 0;
    final edges = <HeatEdgeView>[];
    for (final e in rows) {
      if (e.count > maxCount) maxCount = e.count;

      final a = centroids[e.aRow]?[e.aCol];
      final b = centroids[e.bRow]?[e.bCol];
      if (a == null || b == null) continue;
      if (!_inBounds(query.bounds, a.lat, a.lng) &&
          !_inBounds(query.bounds, b.lat, b.lng)) {
        continue;
      }

      edges.add(
        HeatEdgeView(
          aLat: a.lat,
          aLng: a.lng,
          bLat: b.lat,
          bLng: b.lng,
          count: e.count,
        ),
      );
    }

    return HeatMap(edges: edges, maxCount: maxCount);
  }

  bool _inBounds(HeatBounds? b, double lat, double lng) {
    if (b == null) return true;
    return lat >= b.minLat &&
        lat <= b.maxLat &&
        lng >= b.minLng &&
        lng <= b.maxLng;
  }
}
