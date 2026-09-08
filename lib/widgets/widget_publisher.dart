import 'dart:convert';

import 'package:speedster/cloud/ranking_repository.dart';
import 'package:speedster/data/trip_repository.dart';
import 'package:speedster/domain/trip.dart';
import 'package:speedster/heat/heat_map.dart';
import 'package:speedster/heat/heat_source.dart';
import 'package:speedster/widgets/heat_thumbnail.dart';
import 'package:speedster/widgets/widget_store.dart';

/// Traegt die Werte fuer die Widgets zusammen und legt sie ab.
///
/// Widgets zeichnen sich nicht laufend neu -- das System entscheidet
/// darueber, typischerweise wenige Male pro Stunde. Geschrieben wird
/// deshalb dann, wenn sich etwas geaendert hat: beim Start der App und am
/// Ende einer Fahrt. Alles Weitere waere Arbeit, die niemand sieht.
class WidgetPublisher {
  WidgetPublisher({
    required this.store,
    required this.trips,
    required this.heat,
    this.ranking,
  });

  final WidgetStore store;
  final TripRepository trips;
  final HeatSource heat;

  /// Nur bei aktiver Cloud vorhanden. Ohne sie bleibt das Rang-Widget bei
  /// seinem Hinweis, statt eine Null anzuzeigen.
  final RankingRepository? ranking;

  Future<void> publish() async {
    final values = <String, Object?>{
      WidgetKeys.updatedAt: DateTime.now().toIso8601String(),
      ..._tripValues(await trips.keptTrips()),
    };

    final image = await _thumbnail();
    if (image != null) values[WidgetKeys.heatmapImage] = image;

    values.addAll(await _rankValues());

    await store.put(values);
  }

  Map<String, Object?> _tripValues(List<Trip> kept) {
    if (kept.isEmpty) return const {};

    // keptTrips() liefert absteigend nach Startzeit -- die erste ist die
    // letzte gefahrene.
    final last = kept.first;
    var distance = 0.0;
    var maxSpeed = 0.0;
    double? bestZeroToHundred;
    for (final t in kept) {
      distance += t.distance;
      if (t.maxSpeed > maxSpeed) maxSpeed = t.maxSpeed;
      final zero = t.zeroToHundredSeconds;
      if (zero != null && (bestZeroToHundred == null || zero < bestZeroToHundred)) {
        bestZeroToHundred = zero;
      }
    }

    return {
      WidgetKeys.tripCount: kept.length,
      WidgetKeys.totalDistance: distance,
      WidgetKeys.maxSpeed: maxSpeed,
      WidgetKeys.bestZeroToHundred: bestZeroToHundred,
      WidgetKeys.lastTripAt: last.startTime.toIso8601String(),
      WidgetKeys.lastTripDistance: last.distance,
      WidgetKeys.lastTripMaxSpeed: last.maxSpeed,
    };
  }

  Future<String?> _thumbnail() async {
    try {
      // Mittlere Rasterebene: fein genug, dass Strassen erkennbar bleiben,
      // grob genug, dass ein ganzes Fahrgebiet auf die kleine Flaeche passt.
      final map = await heat.load(const HeatQuery(level: 1));
      final png = await HeatThumbnail.render(map);

      return png == null ? null : base64Encode(png);
    } catch (_) {
      // Ohne Netz oder ohne Daten bleibt das Widget beim letzten Bild.
      return null;
    }
  }

  Future<Map<String, Object?>> _rankValues() async {
    final repository = ranking;
    if (repository == null) return const {};

    try {
      final board = await repository.fetch(RankScope.world, RankMetric.maxSpeed);
      final me = board.me;
      if (me == null) return const {};

      return {
        WidgetKeys.rank: me.rank,
        WidgetKeys.rankScope: 'Weltweit · Höchstgeschw.',
        WidgetKeys.rankValue: '${(me.value * 3.6).round()} km/h',
      };
    } catch (_) {
      // Nicht angemeldet oder kein Netz: der bisherige Rang bleibt stehen.
      return const {};
    }
  }
}
