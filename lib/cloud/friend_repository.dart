import 'package:dio/dio.dart';
import 'package:speedster/cloud/api_error.dart';

/// Ein Freund oder eine offene Anfrage.
class Friend {
  const Friend({
    required this.id,
    required this.status,
    required this.username,
    required this.displayName,
  });

  factory Friend.fromJson(Map<String, dynamic> json) => Friend(
        id: (json['id'] as num).toInt(),
        status: json['status'] as String? ?? 'pending',
        username: json['username'] as String? ?? '',
        displayName: json['display_name'] as String? ?? '',
      );

  final int id;
  final String status;
  final String username;
  final String displayName;
}

/// Die drei Listen, die die Oberflaeche verschieden behandelt.
class FriendOverview {
  const FriendOverview({
    required this.friends,
    required this.incoming,
    required this.outgoing,
  });

  static const empty = FriendOverview(
    friends: [],
    incoming: [],
    outgoing: [],
  );

  final List<Friend> friends;
  final List<Friend> incoming;
  final List<Friend> outgoing;
}

class FriendException implements Exception {
  FriendException(this.message);

  final String message;

  @override
  String toString() => 'FriendException: $message';
}

/// Zugriff auf die Freundschaften in der Cloud.
///
/// Fuehrt bewusst keine Kennzahlen: die kommen ueber das Ranking mit
/// `scope=friends`, damit es fuer den Vergleich eine Quelle gibt statt
/// zweier, die auseinanderlaufen koennen.
class FriendRepository {
  FriendRepository(this.dio);

  final Dio dio;

  Future<FriendOverview> load() async {
    final res = await dio.get<Map<String, dynamic>>('/friends');
    final data = res.data ?? const {};

    List<Friend> list(String key) => [
          for (final raw in (data[key] as List? ?? const []))
            Friend.fromJson(raw as Map<String, dynamic>),
        ];

    return FriendOverview(
      friends: list('friends'),
      incoming: list('incoming'),
      outgoing: list('outgoing'),
    );
  }

  Future<void> request(String username) async {
    try {
      await dio.post('/friends', data: {'username': username});
    } on DioException catch (e) {
      throw FriendException(
        serverMessage(e) ?? 'Die Anfrage konnte nicht gesendet werden.',
      );
    }
  }

  Future<void> accept(int id) => dio.post('/friends/$id/accept');

  /// Deckt Ablehnen, Zurueckziehen und Beenden ab -- drei Vorgaenge, ein
  /// Ergebnis: die Zeile verschwindet.
  Future<void> remove(int id) => dio.delete('/friends/$id');
}
