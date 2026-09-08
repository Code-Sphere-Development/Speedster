import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';
import 'package:speedster/settings/settings_controller.dart';
import 'package:speedster/settings/unit_system.dart';
import 'package:speedster/ui/formatters.dart';

/// Shows current speed during a drive; idle prompt otherwise.
class LiveScreen extends ConsumerWidget {
  const LiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(settingsControllerProvider).unit;
    final l = AppLocalizations.of(context);
    final stateAsync = ref.watch(recorderStateProvider);

    final state = stateAsync.asData?.value;
    final driving = state?.isDriving ?? false;
    final speedMps = state?.last?.speed ?? 0;
    final distanceM = state?.distanceMeters ?? 0;
    final elapsed = state?.elapsedSeconds ?? 0;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (driving) ...[
              Text(
                SpeedFormat.speed(speedMps, unit),
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(l.liveRecording),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LiveMetric(
                    icon: Icons.straighten,
                    value: SpeedFormat.distance(distanceM, unit),
                    label: l.liveDistance,
                  ),
                  const SizedBox(width: 40),
                  _LiveMetric(
                    icon: Icons.timer_outlined,
                    value: Formatters.duration(elapsed),
                    label: l.liveDuration,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Statisch und unaufdringlich. Bewusst keine Warnung, die
              // bei hohem Tempo aufpoppt: die zoege den Blick genau in dem
              // Moment aufs Display, in dem er dort nicht hingehoert.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  l.liveSpeedNotice,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ] else ...[
              const Icon(Icons.speed, size: 96),
              const SizedBox(height: 16),
              Text(
                l.liveReady,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(l.liveUnit(unit == UnitSystem.kmh ? 'km/h' : 'mph')),
            ],
          ],
        ),
      ),
    );
  }
}

class _LiveMetric extends StatelessWidget {
  const _LiveMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 28),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        Text(
          label,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
