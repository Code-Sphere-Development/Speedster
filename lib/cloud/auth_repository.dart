import 'package:dio/dio.dart';
import 'package:speedster/cloud/token_store.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
  @override
  String toString() => 'AuthException: $message';
}

/// Talks to the Laravel auth endpoints and persists the returned token.
class AuthRepository {
  AuthRepository({required this.dio, required this.tokenStore});

  final Dio dio;
  final TokenStore tokenStore;

  Future<void> register(String name, String email, String password) =>
      _authenticate('/auth/register', {
        'name': name,
        'email': email,
        'password': password,
      });

  Future<void> login(String email, String password) =>
      _authenticate('/auth/login', {'email': email, 'password': password});

  Future<void> loginSocial(String provider, String idToken) =>
      _authenticate('/auth/social', {'provider': provider, 'id_token': idToken});

  Future<void> logout() async {
    try {
      await dio.post('/auth/logout');
    } on DioException {
      // Best effort; clear locally regardless.
    }
    await tokenStore.clear();
  }

  Future<void> _authenticate(String path, Map<String, dynamic> body) async {
    try {
      final res = await dio.post(path, data: body);
      final token = res.data['token'] as String?;
      if (token == null) {
        throw AuthException('Keine Token-Antwort vom Server.');
      }
      await tokenStore.write(token);
    } on DioException catch (e) {
      throw AuthException(_messageFrom(e));
    }
  }

  String _messageFrom(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return 'Anmeldung fehlgeschlagen.';
  }
}
