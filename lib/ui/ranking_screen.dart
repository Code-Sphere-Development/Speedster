import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/app/spacing.dart';
import 'package:speedster/cloud/ranking_repository.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';
import 'package:speedster/settings/settings_controller.dart';
import 'package:speedster/ui/components/empty_state.dart';
import 'package:speedster/ui/components/metric_value.dart';
import 'package:speedster/ui/components/card_section.dart';
import 'package:speedster/settings/unit_system.dart';
import 'package:speedster/ui/auth_screen.dart';

/// Beschriftung einer Kennzahl.
///
/// Eine Funktion statt einer Konstanten: eine Konstante liesse sich nicht
/// uebersetzen, weil sie ohne Kontext ausgewertet wird.
String scopeLabel(AppLocalizations l, RankScope scope) => switch (scope) {
      RankScope.world => l.rankingScopeWorld,
      RankScope.country => l.rankingScopeCountry,
      RankScope.friends => l.rankingScopeFriends,
      RankScope.vehicle => l.rankingScopeVehicle,
    };

String periodLabel(AppLocalizations l, RankPeriod period) => switch (period) {
      RankPeriod.week => l.rankingPeriodWeek,
      RankPeriod.month => l.rankingPeriodMonth,
      RankPeriod.all => l.rankingPeriodAll,
    };

String metricLabel(AppLocalizations l, RankMetric metric) => switch (metric) {
      RankMetric.maxSpeed => l.rankingMetricMaxSpeed,
      RankMetric.totalDistance => l.rankingMetricDistance,
      RankMetric.tripCount => l.rankingMetricTrips,
      RankMetric.bestZeroToHundred => l.rankingMetricZeroToHundred,
    };

String formatValue(RankMetric metric, double value, UnitSystem unit) {
  final m = valueParts(metric, value, unit);
  return m.unit.isEmpty ? m.value : '${m.value} ${m.unit}';
}

/// Wert und Einheit getrennt, damit die Zahl gross und die Einheit klein
/// gesetzt werden kann.
///
/// Die Fahrtenzahl hat keine Einheit: "12 Fahrten" stuende in einer
/// Rangliste, in der jede Zeile dasselbe Wort traegt, viermal umsonst.
Measure valueParts(RankMetric metric, double value, UnitSystem unit) {
  switch (metric) {
    case RankMetric.maxSpeed:
      return SpeedFormat.speedParts(value, unit);
    case RankMetric.totalDistance:
      return SpeedFormat.distanceParts(value, unit);
    case RankMetric.tripCount:
      return (value: '${value.toInt()}', unit: '');
    case RankMetric.bestZeroToHundred:
      return (value: value.toStringAsFixed(1), unit: 's');
  }
}

class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen({super.key});

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen> {
  RankScope _scope = RankScope.world;
  RankPeriod _period = RankPeriod.all;
  RankMetric _metric = RankMetric.maxSpeed;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // Ein Zustand, nicht zwei: "Cloud aus" und "nicht angemeldet" waren
    // frueher getrennt -- ein Schalter in den Einstellungen und ein Token
    // im Schluesselbund. Sie liefen auseinander, sobald eines von beiden
    // verschwand, und die App zeigte dann Cloud-Daten an, ohne je etwas
    // hochzuladen. Jetzt entscheidet der Token allein.
    //
    // Bewusst erst die Pruefung abwarten, statt waehrenddessen schon die
    // Rangliste zu laden: fuer ein abgemeldetes Konto waere das eine
    // Abfrage, die zwangslaeufig in einen 401 laeuft.
    return ref.watch(cloudActiveProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          // Faellt die Pruefung selbst aus, ist die Anmeldung der einzige
          // Weg, der dem Nutzer offensteht.
          error: (_, _) => _CloudRequired(
            message: l.rankingStatusUnknown,
            showLogin: true,
          ),
          data: (signedIn) => signedIn
              ? _board(context)
              : _CloudRequired(
                  message: l.rankingSignInNeeded,
                  showLogin: true,
                ),
        );
  }

  Widget _board(BuildContext context) {
    final l = AppLocalizations.of(context);
    final unit = ref.watch(settingsControllerProvider.select((s) => s.unit));
    final board = ref.watch(rankingBoardProvider((_scope, _metric, _period)));

    return Column(
      children: [
        // Keine Seitenueberschrift mehr: die traegt der Kopfbereich der
        // App. Was Bereich und Zeitfenster sind, steht an den
        // Bedienelementen selbst.
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Insets.screen,
            Insets.l,
            Insets.screen,
            Insets.m,
          ),
          child: SegmentedButton<RankScope>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                  value: RankScope.world, label: Text(l.rankingScopeWorld)),
              ButtonSegment(
                  value: RankScope.country, label: Text(l.rankingScopeCountry)),
              ButtonSegment(
                  value: RankScope.friends, label: Text(l.rankingScopeFriends)),
              ButtonSegment(
                  value: RankScope.vehicle, label: Text(l.rankingScopeVehicle)),
            ],
            selected: {_scope},
            onSelectionChanged: (s) => setState(() => _scope = s.first),
          ),
        ),
        // Kennzahl und Zeitfenster teilen sich eine Zeile. Vorher standen
        // sie untereinander, und mit dem Bereich darueber lagen elf
        // Bedienelemente vor der ersten Zahl -- rund ein Fuenftel des
        // Bildschirms, bevor die Liste anfing.
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Insets.screen,
            0,
            Insets.screen,
            Insets.s,
          ),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final m in RankMetric.values)
                        Padding(
                          padding: const EdgeInsets.only(right: Insets.s),
                          child: ChoiceChip(
                            label: Text(metricLabel(l, m)),
                            selected: _metric == m,
                            onSelected: (_) => setState(() => _metric = m),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: Insets.s),
              _PeriodButton(
                period: _period,
                onChanged: (p) => setState(() => _period = p),
              ),
            ],
          ),
        ),
        // Nur bei den beiden Tempo-Wertungen: bei Distanz und Fahrtenzahl
        // gibt es nichts zu relativieren, und ein Hinweis, der ueberall
        // steht, wird zur Tapete, die niemand mehr liest.
        if (_metric == RankMetric.maxSpeed ||
            _metric == RankMetric.bestZeroToHundred)
          _SpeedNotice(text: l.rankingSpeedNotice),
        Expanded(
          child: board.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(l.commonError(e.toString()))),
            data: (b) => b.entries.isEmpty && _scope == RankScope.vehicle
                // Dieselbe Lehre wie bei der Laenderwertung: ohne
                // Standardfahrzeug mit Modell kann diese Wertung nie
                // etwas liefern, und eine leere Liste saehe aus wie ein
                // Fehler.
                ? EmptyState(
                    icon: Icons.directions_car_outlined,
                    message: l.rankingNoVehicle,
                  )
                : _BoardList(
                    board: b,
                    metric: _metric,
                    unit: unit,
                    scope: _scope,
                    period: _period,
                  ),
          ),
        ),
      ],
    );
  }
}

/// Das Zeitfenster als Klappmenue statt als dritte Chip-Reihe.
///
/// Es wird selten umgestellt und braucht deshalb keine dauerhaft
/// ausgebreitete Auswahl -- der aktuelle Wert steht drauf, das genuegt.
class _PeriodButton extends StatelessWidget {
  const _PeriodButton({required this.period, required this.onChanged});

  final RankPeriod period;
  final ValueChanged<RankPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return PopupMenuButton<RankPeriod>(
      initialValue: period,
      onSelected: onChanged,
      tooltip: periodLabel(l, period),
      position: PopupMenuPosition.under,
      itemBuilder: (context) => [
        for (final p in RankPeriod.values)
          PopupMenuItem(value: p, child: Text(periodLabel(l, p))),
      ],
      child: Container(
        padding: const EdgeInsets.fromLTRB(Insets.m, Insets.s, Insets.s, Insets.s),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              periodLabel(l, period),
              style: theme.textTheme.labelLarge,
            ),
            Icon(
              Icons.arrow_drop_down,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Die Mahnung zur StVO, als Zeile statt als Absatz.
class _SpeedNotice extends StatelessWidget {
  const _SpeedNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Insets.screen,
        0,
        Insets.screen,
        Insets.s,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: muted),
          const SizedBox(width: Insets.s),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hinweis statt Fehler, wenn die Voraussetzung fuer das Ranking fehlt.
class _CloudRequired extends StatelessWidget {
  const _CloudRequired({required this.message, this.showLogin = false});

  final String message;
  final bool showLogin;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off,
      message: message,
      action: showLogin
          ? FilledButton(
              onPressed: () => Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
              ),
              child: Text(AppLocalizations.of(context).authSignIn),
            )
          : null,
    );
  }
}

class _BoardList extends StatelessWidget {
  const _BoardList({
    required this.board,
    required this.metric,
    required this.unit,
    required this.scope,
    required this.period,
  });

  final RankingBoard board;
  final RankMetric metric;
  final UnitSystem unit;
  final RankScope scope;
  final RankPeriod period;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Column(
      children: [
        if (board.me != null)
          Builder(
            builder: (context) {
              final scheme = Theme.of(context).colorScheme;
              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  Insets.l,
                  Insets.s,
                  Insets.l,
                  0,
                ),
                child: ClipRRect(
                borderRadius: BorderRadius.circular(Radii.card),
                child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  // Akzentkante links, wie in der Web-Bestenliste: die
                  // Toenung allein ist absichtlich schwach, die Kante
                  // macht die Hervorhebung auch beim Ueberfliegen
                  // eindeutig.
                  border: Border(
                    left: BorderSide(color: scheme.primary, width: 4),
                  ),
                ),
                child: Builder(
                  builder: (context) {
                    final me = valueParts(metric, board.me!.value, unit);

                    return ListTile(
                      textColor: scheme.onPrimaryContainer,
                      leading: SizedBox(
                        width: 32,
                        child: Text(
                          '${board.me!.rank}',
                          textAlign: TextAlign.end,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: scheme.onPrimaryContainer),
                        ),
                      ),
                      title: Text(l.rankingYourRank),
                      // Wie in den uebrigen Zeilen gesetzt -- vorher stand
                      // hier als einziger Wert der Liste ein kleiner
                      // Fliesstext. Flaeche und Schrift bleiben aus
                      // demselben Paar: genau daran war diese Zeile einmal
                      // unlesbar.
                      trailing: MetricValue(
                        value: me.value,
                        unit: me.unit.isEmpty ? null : me.unit,
                        size: 20,
                        color: scheme.onPrimaryContainer,
                        unitColor: scheme.onPrimaryContainer,
                        alignment: CrossAxisAlignment.end,
                      ),
                    );
                  },
                ),
                ),
                ),
              );
            },
          ),
        Expanded(
          child: board.entries.isEmpty
              ? EmptyState(
                  icon: Icons.emoji_events_outlined,
                  message: l.rankingEmpty,
                )
              // Eine Karte um die ganze Wertung statt einer Zeile je
              // Eintrag: die Liste ist eine Gruppe, und die Trennlinien
              // darin genuegen, um die Eintraege auseinanderzuhalten.
              : ListView(
                  padding: const EdgeInsets.only(top: Insets.s),
                  children: [
                    CardSection(
                      title: scopeLabel(l, scope),
                      icon: Icons.emoji_events_outlined,
                      trailing: Text(periodLabel(l, period)),
                      children: [
                        for (final entry in board.entries)
                          _BoardRow(entry: entry, metric: metric, unit: unit),
                      ],
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Eine Zeile der Bestenliste.
///
/// Ohne Verhaeltnisbalken: ein solcher stand hier zwischenzeitlich, war
/// aber bei nah beieinanderliegenden Werten fast immer voll, sass optisch
/// zwischen den Zeilen statt an einer und brachte sechs rote Linien auf
/// einen Bildschirm. Die Zahlen stehen ohnehin sortiert und mit
/// Tabellenziffern untereinander -- das Verhaeltnis liest man daran ab.
class _BoardRow extends StatelessWidget {
  const _BoardRow({
    required this.entry,
    required this.metric,
    required this.unit,
  });

  final RankingEntry entry;
  final RankMetric metric;
  final UnitSystem unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final measure = valueParts(metric, entry.value, unit);

    // Die ersten drei bekommen Gewicht statt einer Farbe: eine Medaille
    // oder ein Farbwechsel waere ein weiteres Signal in einer App, die an
    // Signalen schon zu viele hatte.
    final leading = entry.rank <= 3;

    return ListTile(
      leading: SizedBox(
        width: 32,
        child: Text(
          '${entry.rank}',
          textAlign: TextAlign.end,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: leading ? FontWeight.w700 : FontWeight.w400,
            color: leading
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      title: Text(entry.displayName),
      subtitle: entry.country != null ? Text(entry.country!) : null,
      trailing: MetricValue(
        value: measure.value,
        unit: measure.unit.isEmpty ? null : measure.unit,
        size: 20,
        alignment: CrossAxisAlignment.end,
      ),
    );
  }
}

/// Holt eine Wertung fuer Bereich, Kennzahl und Zeitfenster.
final rankingBoardProvider =
    FutureProvider.family<RankingBoard, (RankScope, RankMetric, RankPeriod)>(
        (ref, key) {
  return ref.watch(rankingRepositoryProvider).fetch(key.$1, key.$2, key.$3);
});
