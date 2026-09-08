import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/domain/track_point.dart';
import 'package:speedster/domain/trip.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';
import 'package:speedster/settings/settings_controller.dart';
import 'package:speedster/settings/unit_system.dart';
import 'package:speedster/ui/formatters.dart';
import 'package:speedster/ui/map_tiles.dart';

/// Schluessel der Punkte-Abfrage: die stabile `client_uuid` und, sofern
/// die Fahrt lokal vorliegt, ihre Zeilen-Id. Ein Record, weil Riverpod-
/// Families Wertgleichheit brauchen -- [Trip] hat keine.
typedef TripPointsKey = ({String clientUuid, int? localId});

/// Punkte einer Fahrt, aus dem lokalen Vorrat oder aus der Cloud.
final tripPointsProvider =
    FutureProvider.family<List<TrackPoint>, TripPointsKey>((ref, key) {
  return ref.watch(tripSourceProvider).pointsFor(
        clientUuid: key.clientUuid,
        localId: key.localId,
      );
});

class TripDetailScreen extends ConsumerWidget {
  const TripDetailScreen({super.key, required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(settingsControllerProvider).unit;
    final l = AppLocalizations.of(context);
    final pointsAsync = ref.watch(
      tripPointsProvider(
        (clientUuid: trip.clientUuid, localId: trip.id),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(Formatters.dateTime(trip.startTime))),
      body: ListView(
        children: [
          SizedBox(
            height: 260,
            child: pointsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                Center(child: Text(l.tripMapUnavailable(e.toString()))),
              data: (points) => _TripMap(points: points),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatTile(l.metricMax, SpeedFormat.speed(trip.maxSpeed, unit)),
                _StatTile(l.metricAverage, SpeedFormat.speed(trip.avgSpeed, unit)),
                _StatTile(
                    l.metricDistance, SpeedFormat.distance(trip.distance, unit)),
                _StatTile(
                    l.metricDuration, Formatters.duration(trip.durationSeconds)),
                _StatTile(l.metricZeroToHundred,
                    Formatters.seconds(trip.zeroToHundredSeconds)),
                _StatTile(
                    l.metricElevation, Formatters.meters(trip.elevationGain)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TripMap extends StatelessWidget {
  const _TripMap({required this.points});

  final List<TrackPoint> points;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    if (points.isEmpty) {
      // Bei aktiver Cloud liegen nur die zuletzt gefahrenen Strecken als
      // Punkte auf dem Geraet (siehe TripCacheService); fuer aeltere
      // Fahrten kommt die Strecke aus dem Netz.
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            l.tripNoRoute,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final coords = points.map((p) => LatLng(p.lat, p.lng)).toList();
    return FlutterMap(
      options: MapOptions(
        initialCenter: coords.first,
        initialZoom: 14,
      ),
      children: [
                  const OsmTileLayer(),
                  const OsmAttribution(),
        PolylineLayer(
          polylines: [
            Polyline(points: coords, strokeWidth: 4, color: Colors.blue),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }
}
