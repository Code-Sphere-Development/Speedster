import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/cloud/ranking_repository.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';
import 'package:speedster/settings/settings_controller.dart';
import 'package:speedster/ui/screen_header.dart';
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
  switch (metric) {
    case RankMetric.maxSpeed:
      return SpeedFormat.speed(value, unit);
    case RankMetric.totalDistance:
      return SpeedFormat.distance(value, unit);
    case RankMetric.tripCount:
      return '${value.toInt()}';
    case RankMetric.bestZeroToHundred:
      return '${value.toStringAsFixed(1)} s';
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
        ScreenHeader(
          title: l.tabRanking,
          subtitle: l.rankingSummary(
            scopeLabel(l, _scope),
            periodLabel(l, _period),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: SegmentedButton<RankScope>(
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
        // Das Zeitfenster steht ueber den Kennzahlen: es entscheidet, ob
        // die Liste ueberhaupt in Bewegung ist. Ohne Fenster steht eine
        // einmalige Spitze dort dauerhaft, und niemand schaut mehr hin.
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final p in RankPeriod.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(periodLabel(l, p)),
                    selected: _period == p,
                    onSelected: (_) => setState(() => _period = p),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final m in RankMetric.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(metricLabel(l, m)),
                    selected: _metric == m,
                    onSelected: (_) => setState(() => _metric = m),
                  ),
                ),
            ],
          ),
        ),
        // Nur bei den beiden Tempo-Wertungen: bei Distanz und Fahrtenzahl
        // gibt es nichts zu relativieren, und ein Hinweis, der ueberall
        // steht, wird zur Tapete, die niemand mehr liest.
        if (_metric == RankMetric.maxSpeed ||
            _metric == RankMetric.bestZeroToHundred)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              l.rankingSpeedNotice,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        Expanded(
          child: board.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(l.commonError(e.toString()))),
            data: (b) => b.entries.isEmpty && _scope == RankScope.vehicle
                // Dieselbe Lehre wie bei der Laenderwertung: ohne
                // Standardfahrzeug mit Modell kann diese Wertung nie
                // etwas liefern, und eine leere Liste saehe aus wie ein
                // Fehler.
                ? _NeedsVehicle(text: l.rankingNoVehicle)
                : _BoardList(board: b, metric: _metric, unit: unit),
          ),
        ),
      ],
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
    final muted = Theme.of(context).textTheme.bodySmall?.color;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 40, color: muted),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),

            if (showLogin) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                ),
                child: Text(AppLocalizations.of(context).authSignIn),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NeedsVehicle extends StatelessWidget {
  const _NeedsVehicle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(text, textAlign: TextAlign.center),
        ),
      );
}

class _BoardList extends StatelessWidget {
  const _BoardList({required this.board, required this.metric, required this.unit});

  final RankingBoard board;
  final RankMetric metric;
  final UnitSystem unit;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Column(
      children: [
        if (board.me != null)
          Builder(
            builder: (context) {
              final scheme = Theme.of(context).colorScheme;
              return DecoratedBox(
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
                child: ListTile(
                  textColor: scheme.onPrimaryContainer,
                  leading: Text(
                    '#${board.me!.rank}',
                    style: TextStyle(color: scheme.onPrimaryContainer),
                  ),
                  title: Text(l.rankingYourRank),
                  trailing: Text(
                    formatValue(metric, board.me!.value, unit),
                    style: TextStyle(color: scheme.onPrimaryContainer),
                  ),
                ),
              );
            },
          ),
        Expanded(
          child: board.entries.isEmpty
              ? Center(child: Text(l.rankingEmpty))
              : ListView.builder(
                  itemCount: board.entries.length,
                  itemBuilder: (context, i) {
                    final e = board.entries[i];
                    return ListTile(
                      leading: Text('#${e.rank}'),
                      title: Text(e.displayName),
                      subtitle: e.country != null ? Text(e.country!) : null,
                      trailing: Text(formatValue(metric, e.value, unit)),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Holt eine Wertung fuer Bereich, Kennzahl und Zeitfenster.
final rankingBoardProvider =
    FutureProvider.family<RankingBoard, (RankScope, RankMetric, RankPeriod)>(
        (ref, key) {
  return ref.watch(rankingRepositoryProvider).fetch(key.$1, key.$2, key.$3);
});
