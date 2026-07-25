import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/domain/trip.dart';
import 'package:speedster/settings/settings_controller.dart';
import 'package:speedster/settings/unit_system.dart';
import 'package:speedster/ui/formatters.dart';
import 'package:speedster/ui/trip_detail_screen.dart';

class TripListScreen extends ConsumerWidget {
  const TripListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(settingsControllerProvider).unit;
    final tripsAsync = ref.watch(keptTripsProvider);

    return Scaffold(
      body: tripsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (trips) {
          if (trips.isEmpty) {
            return const Center(
              child: Text('Noch keine Fahrten aufgezeichnet.'),
            );
          }
          return ListView.builder(
            itemCount: trips.length,
            itemBuilder: (context, i) => _TripCard(trip: trips[i], unit: unit),
          );
        },
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip, required this.unit});

  final Trip trip;
  final UnitSystem unit;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(Formatters.dateTime(trip.startTime)),
        subtitle: Text(
          'Max ${SpeedFormat.speed(trip.maxSpeed, unit)}  ·  '
          '${SpeedFormat.distance(trip.distance, unit)}  ·  '
          '${Formatters.duration(trip.durationSeconds)}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => TripDetailScreen(trip: trip),
          ),
        ),
      ),
    );
  }
}
