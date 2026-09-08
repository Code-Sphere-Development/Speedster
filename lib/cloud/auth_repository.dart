import 'dart:ui' show PlatformDispatcher;

import 'package:dio/dio.dart';
import 'package:speedster/cloud/token_store.dart';

/// Die Region des Geraets, etwa "DE".
///
/// Sie fuellt das Land fuer die Laenderwertung. Der Server nimmt sie nur
/// an, solange dort noch keines steht -- eine Wahl auf der Kontoseite
/// soll nicht bei jeder Anmeldung ueberschrieben werden.
///
/// Bewusst die Geraeteregion und nicht die GPS-Position: die Region gibt
/// es ohne Berechtigung, ohne Dienst und ohne dass Koordinaten das Geraet
/// verlassen. Fuer eine Rangliste ist sie genau genug.
///
/// Ein Geraet ohne gesetzte Region liefert null; dann bleibt das Feld
/// leer, statt geraten zu werden.
String? deviceCountry() {
  final code = PlatformDispatcher.instance.locale.countryCode;

  return code == null || code.length != 2 ? null : code.toUpperCase();
}

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

  /// Benannte Parameter, weil hier vier gleichartige Strings stehen und
  /// eine vertauschte Reihenfolge sonst still ein Konto mit falschem
  /// Benutzernamen anlegen würde.
  Future<void> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) =>
      _authenticate('/auth/register', {
        'name': name,
        'username': username,
        'email': email,
        'password': password,
        'country': ?deviceCountry(),
      });

  Future<void> login(String email, String password) =>
      _authenticate('/auth/login', {
        'email': email,
        'password': password,
        // Auch beim Anmelden: der Server traegt das Land nur nach, wenn
        // noch keines hinterlegt ist. So bekommen auch Bestandskonten
        // eine Laenderwertung, ohne dass jemand etwas eintragen muss.
        'country': ?deviceCountry(),
      });

  /// [username] wird nur beim erstmaligen Anmelden gebraucht: der Server
  /// sucht zuerst über `provider` + `provider_id` und verlangt den
  /// Benutzernamen ausschließlich, wenn er das Konto anlegen muss. Für ein
  /// bestehendes Konto darf er fehlen — mitgeschickt würde er dort gegen
  /// den eigenen, bereits gespeicherten Namen auf `unique` prüfen.
  Future<void> loginSocial(
    String provider,
    String idToken, {
    String? username,
  }) =>
      _authenticate('/auth/social', {
        'provider': provider,
        'id_token': idToken,
        'username': ?username,
        'country': ?deviceCountry(),
      });

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
