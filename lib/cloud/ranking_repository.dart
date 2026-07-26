import 'package:dio/dio.dart';

enum RankScope {
  world('world'),
  country('country');

  const RankScope(this.wire);
  final String wire;
}

enum RankMetric {
  maxSpeed('max_speed'),
  totalDistance('total_distance'),
  tripCount('trip_count'),
  bestZeroToHundred('best_zero_to_hundred');

  const RankMetric(this.wire);
  final String wire;
}

class RankingEntry {
  const RankingEntry({
    required this.rank,
    required this.displayName,
    required this.country,
    required this.value,
  });

  final int rank;
  final String displayName;
  final String? country;
  final double value;

  factory RankingEntry.fromJson(Map<String, dynamic> j) => RankingEntry(
        rank: (j['rank'] as num).toInt(),
        displayName: j['display_name'] as String? ?? '—',
        country: j['country'] as String?,
        value: (j['value'] as num).toDouble(),
      );
}

class RankingBoard {
  const RankingBoard({required this.entries, required this.me});

  final List<RankingEntry> entries;

  /// The caller's own placement, or null if opted out / no trips.
  final RankingEntry? me;
}

class RankingRepository {
  RankingRepository(this.dio);

  final Dio dio;

  Future<RankingBoard> fetch(RankScope scope, RankMetric metric) async {
    final res = await dio.get('/rankings', queryParameters: {
      'scope': scope.wire,
      'metric': metric.wire,
    });
    final data = res.data as Map<String, dynamic>;
    final entries = (data['entries'] as List)
        .map((e) => RankingEntry.fromJson(e as Map<String, dynamic>))
        .toList();

    RankingEntry? me;
    final meJson = data['me'];
    if (meJson is Map<String, dynamic>) {
      me = RankingEntry(
        rank: (meJson['rank'] as num).toInt(),
        displayName: 'Du',
        country: null,
        value: (meJson['value'] as num).toDouble(),
      );
    }

    return RankingBoard(entries: entries, me: me);
  }
}
