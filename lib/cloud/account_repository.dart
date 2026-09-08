import 'package:dio/dio.dart';

/// Das eigene Konto, so wie die Cloud es kennt.
class CloudAccount {
  const CloudAccount({
    required this.name,
    required this.username,
    required this.email,
  });

  factory CloudAccount.fromJson(Map<String, dynamic> json) => CloudAccount(
        name: json['name'] as String? ?? '',
        // Bestandskonten koennen noch keinen haben; die Spalte ist bis zur
        // Nachvergabe nullable, und die Vergabe laeuft ueber das Web.
        username: json['username'] as String?,
        email: json['email'] as String?,
      );

  final String name;
  final String? username;
  final String? email;
}

class AccountRepository {
  AccountRepository(this.dio);

  final Dio dio;

  Future<CloudAccount> me() async {
    final res = await dio.get<Map<String, dynamic>>('/me');

    return CloudAccount.fromJson(res.data ?? const {});
  }
}
