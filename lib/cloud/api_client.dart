import 'package:dio/dio.dart';
import 'package:speedster/cloud/token_store.dart';

/// Basis-URL, zur Bauzeit ueberschreibbar:
/// --dart-define=API_BASE_URL=https://...
const kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://speedster.code-sphere.de',
);

/// Configures a Dio instance that attaches the bearer token from [TokenStore].
class ApiClient {
  ApiClient({required TokenStore tokenStore, Dio? dio})
      : _tokenStore = tokenStore, // ignore: prefer_initializing_formals
        dio = dio ?? Dio() {
    this.dio.options
      ..baseUrl = '$kApiBaseUrl/api'
      ..headers['Accept'] = 'application/json';
    this.dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              final token = await _tokenStore.read();
              if (token != null) {
                options.headers['Authorization'] = 'Bearer $token';
              }
              handler.next(options);
            },
          ),
        );
  }

  final Dio dio;
  final TokenStore _tokenStore;
}
