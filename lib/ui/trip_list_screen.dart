import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/app/spacing.dart';
import 'package:speedster/domain/trip.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';
import 'package:speedster/settings/settings_controller.dart';
import 'package:speedster/ui/components/card_section.dart';
import 'package:speedster/ui/components/empty_state.dart';
import 'package:speedster/ui/components/metric_value.dart';
import 'package:speedster/ui/components/route_thumbnail.dart';
import 'package:speedster/settings/unit_system.dart';
import 'package:speedster/ui/formatters.dart';
import 'package:speedster/ui/trip_detail_screen.dart';

/// Fahrten eines Kalendermonats.
class TripMonth {
  const TripMonth({required this.first, required this.trips});

  /// Irgendein Zeitpunkt in diesem Monat -- fuer die Ueberschrift.
  final DateTime first;
  final List<Trip> trips;

  double get distance =>
      trips.fold<double>(0, (sum, t) => sum + t.distance);

  /// Zerlegt eine absteigend sortierte Fahrtenliste in Monate.
  ///
  /// Die Gruppierung ersetzt die Reihe gleich aussehender Karten: sie
  /// gibt der Liste einen Rhythmus und traegt nebenbei eine Zahl, die
  /// vorher nirgends stand -- wie weit man in diesem Monat gekommen ist.
  static List<TripMonth> split(List<Trip> trips) {
    final months = <TripMonth>[];

    for (final trip in trips) {
      final last = months.isEmpty ? null : months.last;
      if (last != null &&
          last.first.year == trip.startTime.year &&
          last.first.month == trip.startTime.month) {
        last.trips.add(trip);
        continue;
      }
      months.add(TripMonth(first: trip.startTime, trips: [trip]));
    }

    return months;
  }
}

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
        if (trips.isEmpty) {
          return EmptyState(icon: Icons.route_outlined, message: l.tripsEmpty);
        }

        final locale = Localizations.localeOf(context).toLanguageTag();
        final months = TripMonth.split(trips);

        return ListView.builder(
          padding: const EdgeInsets.only(top: Insets.l, bottom: Insets.s),
          itemCount: months.length,
          itemBuilder: (context, i) {
            final month = months[i];

            return CardSection(
              title: DateFormat.yMMMM(locale).format(month.first),
              icon: Icons.calendar_today,
              trailing: Text(SpeedFormat.distance(month.distance, unit)),
              children: [
                for (final trip in month.trips)
                  _TripRow(trip: trip, unit: unit),
              ],
            );
          },
        );
      },
    );
  }
}

/// Eine Fahrt: Streckenbild links, die Kennzahlen rechts.
///
/// Vorher stand hier eine Punktkette in derselben Groesse wie das Datum
/// darueber. Damit sahen alle Fahrten gleich aus, und die interessante
/// Zahl musste man suchen.
class _TripRow extends StatelessWidget {
  const _TripRow({required this.trip, required this.unit});

  final Trip trip;
  final UnitSystem unit;

  /// Feste Breite fuer die Dauer, damit die Spalte ueber alle Zeilen auf
  /// derselben Kante endet.
  static const double _durationWidth = 74;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final locale = Localizations.localeOf(context).toLanguageTag();

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => TripDetailScreen(trip: trip)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Insets.s),
        child: Row(
          children: [
            RouteThumbnail(encoded: trip.routePreview, size: 52),
            const SizedBox(width: Insets.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          Formatters.dayAndTime(trip.startTime, locale),
                          style:
                              theme.textTheme.bodySmall?.copyWith(color: muted),
                        ),
                      ),
                      if (trip.purpose != null) ...[
                        _PurposeBadge(label: purposeLabel(l, trip.purpose)),
                        const SizedBox(width: Insets.s),
                      ],
                      // Die Liste mischt Fahrten, die noch auf dem Geraet
                      // liegen, unter die aus der Cloud. Bisher sah man
                      // ihnen das nicht an.
                      if (trip.syncedAt == null)
                        Tooltip(
                          message: l.settingsPending,
                          child: Icon(
                            Icons.cloud_upload_outlined,
                            size: 14,
                            color: muted,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: MetricValue.of(
                          SpeedFormat.distanceParts(trip.distance, unit),
                          size: 20,
                        ),
                      ),
                      Expanded(
                        child: MetricValue.of(
                          SpeedFormat.speedParts(trip.maxSpeed, unit),
                          size: 20,
                        ),
                      ),
                      SizedBox(
                        width: _durationWidth,
                        child: Text(
                          Formatters.duration(trip.durationSeconds),
                          textAlign: TextAlign.end,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: muted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Der Zweck einer Fahrt, sofern einer gesetzt ist.
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
