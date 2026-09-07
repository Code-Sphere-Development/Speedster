import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/cloud/api_client.dart';
import 'package:speedster/cloud/token_store.dart';

void main() {
  test('zeigt ohne dart-define auf die Produktionsumgebung', () {
    // localhost war als Vorgabe nur waehrend der Entwicklung sinnvoll und
    // ist auf einem Geraet nicht erreichbar.
    expect(kApiBaseUrl, 'https://speedster.code-sphere.de');
  });

  test('haengt /api an die Basis-URL', () {
    final client = ApiClient(tokenStore: InMemoryTokenStore());
    expect(client.dio.options.baseUrl, 'https://speedster.code-sphere.de/api');
  });
}
