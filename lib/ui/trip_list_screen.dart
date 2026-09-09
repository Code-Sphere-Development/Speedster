import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/domain/trip.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';
import 'package:speedster/settings/settings_controller.dart';
import 'package:speedster/ui/screen_header.dart';
import 'package:speedster/settings/unit_system.dart';
import 'package:speedster/ui/formatters.dart';
import 'package:speedster/ui/trip_detail_screen.dart';

class TripListScreen extends ConsumerWidget {
  const TripListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(settingsControllerProvider).unit;
    final tripsAsync = ref.watch(keptTripsProvider);
    final l = AppLocalizations.of(context);

    return tripsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l.commonError(e.toString()))),
      data: (trips) {
        // Die Ueberschrift steht im Inhalt und scrollt mit; deshalb ist
        // sie das erste Element der Liste und kein Rahmen darum.
        final total = trips.fold<double>(0, (sum, t) => sum + t.distance);
        final header = ScreenHeader(
          title: l.tabTrips,
          subtitle: trips.isEmpty
              ? null
              : l.tripsSummary(trips.length, SpeedFormat.distance(total, unit)),
        );

        if (trips.isEmpty) {
          return ListView(
            children: [
              header,
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(l.tripsEmpty),
              ),
            ],
          );
        }

        return ListView.builder(
          itemCount: trips.length + 1,
          itemBuilder: (context, i) => i == 0
              ? header
              : _TripCard(trip: trips[i - 1], unit: unit),
        );
      },
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
