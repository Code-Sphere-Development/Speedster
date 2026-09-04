import 'package:dio/dio.dart';
import 'package:speedster/cloud/token_store.dart';
import 'package:speedster/heat/heat_map.dart';
import 'package:speedster/heat/heat_source.dart';

/// Liest die serverseitig aggregierte Heatmap. Nur hier greifen die
/// Zeitraum-Filter — lokal fehlen die Monatsbuckets.
class CloudHeatSource implements HeatSource {
  CloudHeatSource(this.dio);

  final Dio dio;

  @override
  Future<HeatMap> load(HeatQuery query) async {
    final bounds = query.bounds;
    final res = await dio.get<Map<String, dynamic>>(
      '/heatmap',
      queryParameters: {
        'range': query.range.wire,
        'level': query.level,
        if (bounds != null) ...{
          'min_lat': bounds.minLat,
          'min_lng': bounds.minLng,
          'max_lat': bounds.maxLat,
          'max_lng': bounds.maxLng,
        },
      },
    );

    final data = res.data ?? const <String, dynamic>{};
    final edges = <HeatEdgeView>[];
    for (final raw in (data['edges'] as List? ?? const [])) {
      final e = raw as Map<String, dynamic>;
      final a = e['a'] as List;
      final b = e['b'] as List;
      edges.add(
        HeatEdgeView(
          aLat: (a[0] as num).toDouble(),
          aLng: (a[1] as num).toDouble(),
          bLat: (b[0] as num).toDouble(),
          bLng: (b[1] as num).toDouble(),
          count: (e['c'] as num).toInt(),
        ),
      );
    }

    return HeatMap(
      edges: edges,
      maxCount: (data['max_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Waehlt die Quelle und faengt Cloud-Ausfaelle ab.
///
/// Die Heatmap ist der Start-Screen: sie darf nie in einen Fehlerzustand
/// kippen, nur weil das Netz weg ist.
class FallbackHeatSource implements HeatSource {
  FallbackHeatSource(this.cloud, this.local, this.tokenStore);

  final HeatSource cloud;
  final HeatSource local;
  final TokenStore tokenStore;

  @override
  Future<HeatMap> load(HeatQuery query) async {
    if (await tokenStore.read() == null) {
      return local.load(query);
    }
    try {
      return await cloud.load(query);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Token abgelaufen: loeschen wie beim Sync, damit die Quellenwahl
        // beim naechsten Aufruf von selbst auf lokal umschaltet.
        await tokenStore.clear();
      }
      return local.load(query);
    }
  }
}
