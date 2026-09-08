import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/cloud/ranking_repository.dart';
import 'package:speedster/settings/settings_controller.dart';
import 'package:speedster/settings/unit_system.dart';
import 'package:speedster/ui/auth_screen.dart';

const _metricLabels = {
  RankMetric.maxSpeed: 'Max Speed',
  RankMetric.totalDistance: 'Distanz',
  RankMetric.tripCount: 'Fahrten',
  RankMetric.bestZeroToHundred: 'Beste 0–100',
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
  RankMetric _metric = RankMetric.maxSpeed;

  @override
  Widget build(BuildContext context) {
    final cloudOn = ref.watch(
      settingsControllerProvider.select((s) => s.cloudEnabled),
    );
    if (!cloudOn) {
      return const _CloudRequired(
        message: 'Das Ranking vergleicht dich mit anderen Fahrern und lebt '
            'deshalb von der Speedster Cloud. Ohne Cloud-Sync gibt es '
            'niemanden, mit dem sich vergleichen liesse.',
        hint: 'Cloud-Sync findest du in den Einstellungen.',
      );
    }

    // Der eingeschaltete Schalter allein genuegt nicht: laeuft das Token
    // ab, loeschen Sync und Heatmap es (siehe FallbackHeatSource), und die
    // Abfrage liefe in einen 401. Ein Fehlertext waere dafuer die falsche
    // Antwort -- fehlt nur die Anmeldung, soll sie angeboten werden.
    //
    // Bewusst erst die Pruefung abwarten, statt waehrenddessen schon die
    // Rangliste zu laden: fuer ein abgemeldetes Konto waere das eine
    // Abfrage, die zwangslaeufig in einen 401 laeuft.
    return ref.watch(cloudActiveProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          // Faellt die Pruefung selbst aus, ist die Anmeldung der einzige
          // Weg, der dem Nutzer offensteht.
          error: (_, _) => const _CloudRequired(
            message: 'Der Anmeldestatus liess sich nicht pruefen.',
            showLogin: true,
          ),
          data: (signedIn) => signedIn
              ? _board(context)
              : const _CloudRequired(
                  message: 'Fuer das Ranking musst du in der Speedster Cloud '
                      'angemeldet sein.',
                  showLogin: true,
                ),
        );
  }

  Widget _board(BuildContext context) {
    final unit = ref.watch(settingsControllerProvider.select((s) => s.unit));
    final board = ref.watch(rankingBoardProvider((_scope, _metric)));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SegmentedButton<RankScope>(
            segments: const [
              ButtonSegment(value: RankScope.world, label: Text('Welt')),
              ButtonSegment(value: RankScope.country, label: Text('Land')),
              ButtonSegment(value: RankScope.friends, label: Text('Freunde')),
            ],
            selected: {_scope},
            onSelectionChanged: (s) => setState(() => _scope = s.first),
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
                    label: Text(_metricLabels[m]!),
                    selected: _metric == m,
                    onSelected: (_) => setState(() => _metric = m),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: board.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Fehler: $e')),
            data: (b) => _BoardList(board: b, metric: _metric, unit: unit),
          ),
        ),
      ],
    );
  }
}

/// Hinweis statt Fehler, wenn die Voraussetzung fuer das Ranking fehlt.
class _CloudRequired extends StatelessWidget {
  const _CloudRequired({
    required this.message,
    this.hint,
    this.showLogin = false,
  });

  final String message;
  final String? hint;
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
            if (hint != null) ...[
              const SizedBox(height: 8),
              Text(
                hint!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (showLogin) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                ),
                child: const Text('Anmelden'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BoardList extends StatelessWidget {
  const _BoardList({required this.board, required this.metric, required this.unit});

  final RankingBoard board;
  final RankMetric metric;
  final UnitSystem unit;

  @override
  Widget build(BuildContext context) {
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
                  title: const Text('Dein Rang'),
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
              ? const Center(child: Text('Noch keine Einträge.'))
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

/// Fetches a board for a (scope, metric) pair.
final rankingBoardProvider =
    FutureProvider.family<RankingBoard, (RankScope, RankMetric)>((ref, key) {
  return ref.watch(rankingRepositoryProvider).fetch(key.$1, key.$2);
});
