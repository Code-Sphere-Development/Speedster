import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/cloud/token_store.dart';
import 'package:speedster/heat/cloud_heat_source.dart';
import 'package:speedster/heat/heat_map.dart';
import 'package:speedster/heat/heat_source.dart';

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.body);

  final String body;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(RequestOptions options, _, _) async {
    lastRequest = options;
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _FailingSource implements HeatSource {
  _FailingSource([this.status]);

  final int? status;

  @override
  Future<HeatMap> load(HeatQuery query) async {
    final options = RequestOptions(path: '/heatmap');
    throw DioException(
      requestOptions: options,
      response: status == null
          ? null
          : Response<dynamic>(requestOptions: options, statusCode: status),
    );
  }
}

class _LocalStub implements HeatSource {
  bool called = false;

  @override
  Future<HeatMap> load(HeatQuery query) async {
    called = true;
    return const HeatMap(edges: [], maxCount: 7);
  }
}

void main() {
  test('parst die Antwort des Endpunkts', () async {
    final adapter = _StubAdapter(
      '{"range":"all","level":0,"max_count":9,'
      '"edges":[{"a":[50.0,6.0],"b":[50.001,6.001],"c":4}]}',
    );
    final dio = Dio()..httpClientAdapter = adapter;

    final map = await CloudHeatSource(dio).load(const HeatQuery(level: 0));

    expect(map.maxCount, 9);
    expect(map.edges.single.count, 4);
    expect(map.edges.single.aLat, 50.0);
    expect(map.edges.single.bLng, 6.001);
  });

  test('schickt Range, Level und Viewport mit', () async {
    final adapter = _StubAdapter('{"max_count":0,"edges":[]}');
    final dio = Dio()..httpClientAdapter = adapter;

    await CloudHeatSource(dio).load(
      const HeatQuery(
        level: 2,
        range: HeatRange.months3,
        bounds: HeatBounds(49.0, 5.0, 51.0, 7.0),
      ),
    );

    final params = adapter.lastRequest!.queryParameters;
    expect(params['range'], '3m');
    expect(params['level'], 2);
    expect(params['min_lat'], 49.0);
    expect(params['max_lng'], 7.0);
  });

  test('ohne Token wird direkt lokal geladen', () async {
    final local = _LocalStub();
    final source =
        FallbackHeatSource(_FailingSource(), local, InMemoryTokenStore());

    final map = await source.load(const HeatQuery(level: 0));
    expect(local.called, isTrue);
    expect(map.maxCount, 7);
  });

  test('faellt bei Cloud-Fehler auf lokal zurueck', () async {
    final store = InMemoryTokenStore();
    await store.write('token');
    final local = _LocalStub();

    final map = await FallbackHeatSource(_FailingSource(), local, store)
        .load(const HeatQuery(level: 0));

    expect(local.called, isTrue);
    expect(map.maxCount, 7);
    expect(await store.read(), 'token', reason: 'nur 401 loescht den Token');
  });

  test('401 loescht den Token und faellt lokal zurueck', () async {
    final store = InMemoryTokenStore();
    await store.write('abgelaufen');
    final local = _LocalStub();

    final map = await FallbackHeatSource(_FailingSource(401), local, store)
        .load(const HeatQuery(level: 0));

    expect(await store.read(), isNull, reason: 'Token muss geloescht sein');
    expect(map.maxCount, 7);
  });
}
