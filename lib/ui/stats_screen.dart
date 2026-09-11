import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/app/spacing.dart';
import 'package:speedster/domain/recurring_routes.dart';
import 'package:speedster/domain/trip.dart';
import 'package:speedster/domain/trip_statistics.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';
import 'package:speedster/settings/settings_controller.dart';
import 'package:speedster/settings/unit_system.dart';
import 'package:speedster/ui/components/card_section.dart';
import 'package:speedster/ui/components/empty_state.dart';
import 'package:speedster/ui/components/metric_value.dart';
import 'package:speedster/ui/formatters.dart';
import 'package:speedster/ui/ranking_screen.dart';
import 'package:speedster/ui/trip_detail_screen.dart';

/// Zahlen zur eigenen Fahrerei -- und daneben die Bestenliste.
///
/// Beides in einem Reiter, weil die Leiste nur fuenf traegt und beides
/// dasselbe beantwortet: wie viel, wie schnell, im Vergleich wozu. Die
/// eigenen Zahlen kommen **ohne Konto** aus, die Bestenliste nicht.
class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  bool _leaderboard = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Insets.screen,
            Insets.l,
            Insets.screen,
            Insets.s,
          ),
          child: SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: false, label: Text(l.statsMine)),
              ButtonSegment(value: true, label: Text(l.statsLeaderboard)),
            ],
            selected: {_leaderboard},
            onSelectionChanged: (s) =>
                setState(() => _leaderboard = s.first),
          ),
        ),
        Expanded(
          child: _leaderboard ? const RankingScreen() : const _MyNumbers(),
        ),
      ],
    );
  }
}

class _MyNumbers extends ConsumerWidget {
  const _MyNumbers();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final unit = ref.watch(settingsControllerProvider).unit;
    final tripsAsync = ref.watch(keptTripsProvider);

    return tripsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline,
        message: l.commonError(e.toString()),
      ),
      data: (trips) {
        final stats = TripStatistics.of(trips, ref.watch(nowProvider)());
        if (stats.isEmpty) {
          return EmptyState(
            icon: Icons.insights_outlined,
            message: l.statsEmpty,
          );
        }

        final locale = Localizations.localeOf(context).toLanguageTag();

        return ListView(
          padding: const EdgeInsets.only(top: Insets.s, bottom: Insets.s),
          children: [
            CardSection(
              title: l.statsTotals,
              icon: Icons.functions,
              children: [
                _SpanRow(label: l.headerThisMonth, span: stats.month, unit: unit),
                _SpanRow(label: l.headerThisYear, span: stats.year, unit: unit),
                _SpanRow(label: l.statsAllTime, span: stats.total, unit: unit),
              ],
            ),
            CardSection(
              title: l.statsRecords,
              icon: Icons.emoji_events_outlined,
              children: [
                if (stats.longest case final r?)
                  _RecordRow(
                    label: l.statsLongest,
                    measure: SpeedFormat.distanceParts(r.value, unit),
                    trip: r.trip,
                  ),
                if (stats.fastest case final r?)
                  _RecordRow(
                    label: l.statsFastest,
                    measure: SpeedFormat.speedParts(r.value, unit),
                    trip: r.trip,
                  ),
                if (stats.quickestSprint case final r?)
                  _RecordRow(
                    label: l.rankingMetricZeroToHundred,
                    measure: Formatters.secondsParts(r.value),
                    trip: r.trip,
                  ),
                if (stats.busiestDay case final day?)
                  _RecordRow(
                    label: l.statsBusiestDay,
                    measure: SpeedFormat.distanceParts(day.distance, unit),
                    caption: DateFormat.yMMMEd(locale).format(day.day),
                  ),
              ],
            ),
            CardSection(
              title: l.statsWhen,
              icon: Icons.calendar_view_week,
              children: [
                _WeekdayChart(values: stats.byWeekday, unit: unit),
              ],
            ),
            if (RecurringRoutes.from(trips) case final routes
                when routes.isNotEmpty)
              CardSection(
                title: l.statsRoutes,
                icon: Icons.repeat,
                children: [
                  for (final route in routes.take(5))
                    _RecordRow(
                      label: l.tripRouteCount(route.count),
                      measure: (
                        value: Formatters.duration(route.typicalSeconds),
                        unit: '',
                      ),
                      caption: SpeedFormat.distance(
                        route.trips.first.distance,
                        unit,
                      ),
                      trip: route.trips.first,
                    ),
                ],
              ),
            if (stats.byPurpose.length > 1)
              CardSection(
                title: l.statsByPurpose,
                icon: Icons.label_outline,
                children: [
                  for (final entry in _sortedByShare(stats.byPurpose))
                    _RecordRow(
                      label: purposeLabel(l, entry.key),
                      measure:
                          SpeedFormat.distanceParts(entry.value, unit),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }

  /// Groesster Anteil zuerst -- die Reihenfolge einer Map haengt sonst
  /// daran, welcher Zweck zufaellig zuerst gefahren wurde.
  static List<MapEntry<String?, double>> _sortedByShare(
    Map<String?, double> byPurpose,
  ) =>
      byPurpose.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
}

/// Eine Zeitraumzeile: Strecke gross, Fahrten und Dauer klein darunter.
class _SpanRow extends StatelessWidget {
  const _SpanRow({required this.label, required this.span, required this.unit});

  final String label;
  final TripSpan span;
  final UnitSystem unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Insets.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                ),
                Text(
                  l.statsSpanDetail(
                    span.trips,
                    Formatters.duration(span.seconds),
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ],
            ),
          ),
          MetricValue.of(
            SpeedFormat.distanceParts(span.distance, unit),
            size: 20,
            alignment: CrossAxisAlignment.end,
          ),
        ],
      ),
    );
  }
}

/// Ein Rekord. Tippbar, wenn eine Fahrt dahintersteht.
class _RecordRow extends StatelessWidget {
  const _RecordRow({
    required this.label,
    required this.measure,
    this.trip,
    this.caption,
  });

  final String label;
  final Measure measure;
  final Trip? trip;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final locale = Localizations.localeOf(context).toLanguageTag();

    final subtitle = caption ??
        (trip == null ? null : Formatters.dayAndTime(trip!.startTime, locale));

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: Insets.s),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
              ],
            ),
          ),
          MetricValue(
            value: measure.value,
            unit: measure.unit.isEmpty ? null : measure.unit,
            size: 20,
            alignment: CrossAxisAlignment.end,
          ),
        ],
      ),
    );

    final target = trip;
    if (target == null) return row;

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => TripDetailScreen(trip: target)),
      ),
      child: row,
    );
  }
}

/// Strecke je Wochentag als Balken.
///
/// Der Balken macht sichtbar, was eine Spalte aus sieben Zahlen
/// verschweigt: ob man unter der Woche pendelt oder am Wochenende faehrt.
class _WeekdayChart extends StatelessWidget {
  const _WeekdayChart({required this.values, required this.unit});

  final List<double> values;
  final UnitSystem unit;

  static const double _height = 88;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final locale = Localizations.localeOf(context).toLanguageTag();

    final max = values.fold<double>(0, (m, v) => v > m ? v : m);
    // Der 6. Juli 2026 war ein Montag -- der Anker fuer die Kuerzel, damit
    // sie aus der Sprache kommen und nicht aus einer Liste im Code.
    final monday = DateTime(2026, 7, 6);
    final labels = DateFormat.E(locale);

    return Padding(
      padding: const EdgeInsets.only(top: Insets.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final (i, value) in values.indexed)
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: _height,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        // Nie ganz null: ein Tag ohne Fahrt soll als
                        // Strich sichtbar bleiben, sonst sieht die Luecke
                        // aus wie ein Zeichenfehler.
                        heightFactor: max <= 0 ? 0.02 : (value / max).clamp(0.02, 1.0),
                        widthFactor: 0.5,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: value <= 0
                                ? theme.colorScheme.outlineVariant
                                : theme.colorScheme.primary
                                    .withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Insets.xs),
                  Text(
                    labels.format(monday.add(Duration(days: i))),
                    style: theme.textTheme.labelSmall?.copyWith(color: muted),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
