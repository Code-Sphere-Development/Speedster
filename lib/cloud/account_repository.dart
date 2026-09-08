import 'package:dio/dio.dart';
import 'package:speedster/cloud/api_error.dart';

/// Das eigene Konto, so wie die Cloud es kennt.
class CloudAccount {
  const CloudAccount({
    required this.name,
    required this.username,
    required this.email,
    this.usernameChangeableAt,
  });

  factory CloudAccount.fromJson(Map<String, dynamic> json) => CloudAccount(
        name: json['name'] as String? ?? '',
        // Bestandskonten koennen noch keinen haben; die Spalte ist bis zur
        // Nachvergabe nullable, und die Vergabe laeuft ueber das Web.
        username: json['username'] as String?,
        email: json['email'] as String?,
        // Wann der naechste Wechsel des Benutzernamens moeglich ist.
        // `null` heisst "jetzt" -- ohne diese Angabe muesste die App den
        // Nutzer erst gegen eine Fehlermeldung laufen lassen.
        usernameChangeableAt: DateTime.tryParse(
          json['username_changeable_at'] as String? ?? '',
        ),
      );

  final String name;
  final String? username;
  final String? email;
  final DateTime? usernameChangeableAt;

  /// Ob der Benutzername gerade gewechselt werden darf.
  bool get canChangeUsername =>
      usernameChangeableAt == null ||
      usernameChangeableAt!.isBefore(DateTime.now());
}

/// Fehler mit der Meldung des Servers, sofern er eine geschickt hat.
///
/// `message` ist absichtlich nullbar: ohne Antwort gibt es nichts
/// Genaueres zu sagen, und der Ersatztext gehoert in die Oberflaeche, die
/// ihre Sprache kennt.
class AccountException implements Exception {
  const AccountException(this.message);

  final String? message;

  @override
  String toString() => message ?? 'AccountException';
}

class AccountRepository {
  AccountRepository(this.dio);

  final Dio dio;

  Future<CloudAccount> me() async {
    final res = await dio.get<Map<String, dynamic>>('/me');

    return CloudAccount.fromJson(res.data ?? const {});
  }

  /// Wechselt den Benutzernamen.
  ///
  /// Der Server entscheidet: ueber die Eindeutigkeit, die lokal
  /// grundsaetzlich nicht pruefbar ist, und ueber die Sperrfrist zwischen
  /// zwei Wechseln. Er antwortet mit dem Konto, wie es danach aussieht.
  Future<CloudAccount> changeUsername(String username) async {
    try {
      final res = await dio.patch<Map<String, dynamic>>(
        '/account/username',
        data: {'username': username},
      );

      return CloudAccount.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw AccountException(serverMessage(e));
    }
  }
}
