import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/app/spacing.dart';
import 'package:speedster/domain/trip.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';
import 'package:speedster/settings/settings_controller.dart';
import 'package:speedster/ui/components/empty_state.dart';
import 'package:speedster/ui/components/metric_value.dart';
import 'package:speedster/ui/components/route_thumbnail.dart';
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
      error: (e, _) => EmptyState(
        icon: Icons.error_outline,
        message: l.commonError(e.toString()),
      ),
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
              EmptyState(
                icon: Icons.route_outlined,
                message: l.tripsEmpty,
              ),
            ],
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: Insets.l),
          itemCount: trips.length + 1,
          itemBuilder: (context, i) =>
              i == 0 ? header : _TripCard(trip: trips[i - 1], unit: unit),
        );
      },
    );
  }
}

/// Eine Fahrt: Streckenbild links, die beiden Kennzahlen rechts.
///
/// Vorher stand hier eine Punktkette -- "Max 160 km/h · 42,3 km · 40m
/// 10s" -- in derselben Groesse wie das Datum darueber. Damit sahen alle
/// Fahrten gleich aus, und die interessante Zahl musste man suchen.
class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip, required this.unit});

  final Trip trip;
  final UnitSystem unit;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => TripDetailScreen(trip: trip),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Insets.l),
          child: Row(
            children: [
              RouteThumbnail(encoded: trip.routePreview),
              const SizedBox(width: Insets.l),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            Formatters.dayAndTime(trip.startTime, locale),
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: muted),
                          ),
                        ),
                        // Die Liste mischt Fahrten, die noch auf dem
                        // Geraet liegen, unter die aus der Cloud. Bisher
                        // sah man ihnen das nicht an.
                        if (trip.syncedAt == null)
                          Tooltip(
                            message: l.settingsPending,
                            child: Icon(
                              Icons.cloud_upload_outlined,
                              size: 16,
                              color: muted,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: Insets.s),
                    // Beide Kennzahlen bekommen dieselbe Breite: sonst
                    // beginnt das Tempo je nach Laenge der Distanz an einer
                    // anderen Stelle, und die Spalte franst ueber die Liste
                    // hinweg aus.
                    Row(
                      children: [
                        Expanded(
                          child: MetricValue.of(
                            SpeedFormat.distanceParts(trip.distance, unit),
                            size: 22,
                          ),
                        ),
                        Expanded(
                          child: MetricValue.of(
                            SpeedFormat.speedParts(trip.maxSpeed, unit),
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Insets.xs),
                    Row(
                      children: [
                        Text(
                          Formatters.duration(trip.durationSeconds),
                          style:
                              theme.textTheme.bodySmall?.copyWith(color: muted),
                        ),
                        if (trip.purpose != null) ...[
                          const SizedBox(width: Insets.s),
                          _PurposeBadge(label: purposeLabel(l, trip.purpose)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Der Zweck einer Fahrt, sofern einer gesetzt ist.
///
/// Er war bislang nur in der Detailansicht zu sehen -- und damit nirgends,
/// wo man ihn zum Vergleichen gebraucht haette.
class _PurposeBadge extends StatelessWidget {
  const _PurposeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Insets.s, vertical: 1),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSecondaryContainer,
            ),
      ),
    );
  }
}
