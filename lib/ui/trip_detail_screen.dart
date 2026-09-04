import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:speedster/ui/map_tiles.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/domain/track_point.dart';
import 'package:speedster/domain/trip.dart';
import 'package:speedster/settings/settings_controller.dart';
import 'package:speedster/settings/unit_system.dart';
import 'package:speedster/ui/formatters.dart';

/// Points for a given trip id.
final tripPointsProvider =
    FutureProvider.family<List<TrackPoint>, int>((ref, tripId) {
  return ref.watch(tripRepositoryProvider).pointsFor(tripId);
});

class TripDetailScreen extends ConsumerWidget {
  const TripDetailScreen({super.key, required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(settingsControllerProvider).unit;
    final pointsAsync = ref.watch(tripPointsProvider(trip.id ?? -1));

    return Scaffold(
      appBar: AppBar(title: Text(Formatters.dateTime(trip.startTime))),
      body: ListView(
        children: [
          SizedBox(
            height: 260,
            child: pointsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Karte nicht verfügbar: $e')),
              data: (points) => _TripMap(points: points),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatTile('Max', SpeedFormat.speed(trip.maxSpeed, unit)),
                _StatTile('Ø', SpeedFormat.speed(trip.avgSpeed, unit)),
                _StatTile('Distanz', SpeedFormat.distance(trip.distance, unit)),
                _StatTile('Dauer', Formatters.duration(trip.durationSeconds)),
                _StatTile('0–100', Formatters.seconds(trip.zeroToHundredSeconds)),
                _StatTile('Höhenmeter', Formatters.meters(trip.elevationGain)),
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
    if (points.isEmpty) {
      return const Center(child: Text('Keine Routendaten'));
    }
    final coords = points.map((p) => LatLng(p.lat, p.lng)).toList();
    return FlutterMap(
      options: MapOptions(
        initialCenter: coords.first,
        initialZoom: 14,
      ),
      children: [
                  const OsmTileLayer(),
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
