import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/cloud/ranking_repository.dart';
import 'package:speedster/settings/settings_controller.dart';
import 'package:speedster/settings/unit_system.dart';

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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Aktiviere Cloud-Sync in den Einstellungen, um Rankings zu sehen.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

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
          Container(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: ListTile(
              leading: Text('#${board.me!.rank}'),
              title: const Text('Dein Rang'),
              trailing: Text(formatValue(metric, board.me!.value, unit)),
            ),
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
