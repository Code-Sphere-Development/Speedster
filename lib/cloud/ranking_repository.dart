import 'package:dio/dio.dart';

enum RankScope {
  world('world'),
  country('country'),
  // Nur bestaetigte Freunde und man selbst. Der Bereich ignoriert
  // ranking_opt_in: eine angenommene Anfrage ist die staerkere
  // Einwilligung (siehe docs/specs/2026-09-08-freunde-design.md).
  friends('friends'),
  // Vergleicht nur, wer dasselbe Modell faehrt. Braucht ein
  // Standardfahrzeug mit Katalogmodell -- ohne das bleibt die Wertung
  // leer, und die Oberflaeche verweist auf die Garage.
  vehicle('vehicle');

  const RankScope(this.wire);
  final String wire;
}

/// Zeitfenster der Wertung.
///
/// Ohne Fenster zaehlt die Bestenliste ueber die gesamte Zeit: wer einmal
/// schnell war, steht dort dauerhaft, und niemand kann ihn mehr einholen.
enum RankPeriod {
  week('week'),
  month('month'),
  all('all');

  const RankPeriod(this.wire);
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

  Future<RankingBoard> fetch(
    RankScope scope,
    RankMetric metric, [
    RankPeriod period = RankPeriod.all,
  ]) async {
    final res = await dio.get('/rankings', queryParameters: {
      'scope': scope.wire,
      'metric': metric.wire,
      'period': period.wire,
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
