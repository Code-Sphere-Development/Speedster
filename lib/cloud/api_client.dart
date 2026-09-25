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
      ..headers['Accept'] = 'application/json'
      // Ohne Zeitlimit wartet dio unbegrenzt: nimmt der Server die
      // Verbindung an und antwortet nicht, kehrt der Aufruf nie zurueck.
      // Das hat die Aufzeichnung zum Stillstand gebracht -- das Fahrtende
      // hing an einer Abfrage der Garage (siehe TripRecorder).
      //
      // Grosszuegig bemessen: im Auto ist das Netz oft schlecht, und ein
      // Abbruch nach drei Sekunden verwuerfe einen Upload, der sonst
      // durchgegangen waere. Es geht um die Obergrenze, nicht um Tempo.
      ..connectTimeout = const Duration(seconds: 15)
      ..receiveTimeout = const Duration(seconds: 30)
      ..sendTimeout = const Duration(seconds: 30);
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
