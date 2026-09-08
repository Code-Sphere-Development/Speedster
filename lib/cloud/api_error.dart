import 'package:dio/dio.dart';

/// Holt die Meldung des Servers aus einer fehlgeschlagenen Anfrage.
///
/// Der Server unterscheidet Faelle, die die App nicht kennt -- "gibt es
/// nicht", "laeuft bereits", "erst kuerzlich gewechselt" -- und er
/// antwortet in der Sprache der Anfrage. Eine hier erfundene Meldung
/// waere ungenauer und in der falschen Sprache.
///
/// Gibt `null` zurueck, wenn keine Meldung dabei war -- etwa weil gar
/// keine Antwort ankam. Was dann angezeigt wird, entscheidet der
/// Aufrufer: nur er weiss, welcher Ersatztext in seine Oberflaeche passt
/// und in welcher Sprache sie gerade laeuft.
///
/// An einer Stelle, weil mehrere Repositories dasselbe brauchen: eine
/// zweite Fassung wuerde beim naechsten Feld der Antwort auseinanderlaufen.
String? serverMessage(DioException error) {
  final data = error.response?.data;
  if (data is Map<String, dynamic>) {
    // Laravel legt Validierungsfehler unter "errors" ab, alles andere
    // unter "message".
    final errors = data['errors'];
    if (errors is Map<String, dynamic>) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) return '${first.first}';
    }
    final message = data['message'];
    if (message is String && message.isNotEmpty) return message;
  }

  return null;
}
