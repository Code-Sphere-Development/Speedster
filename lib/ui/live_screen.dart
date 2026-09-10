import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/app/spacing.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';
import 'package:speedster/settings/settings_controller.dart';
import 'package:speedster/settings/unit_system.dart';
import 'package:speedster/ui/components/metric_value.dart';
import 'package:speedster/ui/formatters.dart';

/// Shows current speed during a drive; idle prompt otherwise.
class LiveScreen extends ConsumerWidget {
  const LiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(settingsControllerProvider).unit;
    final l = AppLocalizations.of(context);
    final stateAsync = ref.watch(recorderStateProvider);

    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

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
              // Ueber MetricValue und nicht als handgesetzte TextStyle:
              // eine solche verliert die Tabellenziffern des Textthemas,
              // und genau deshalb sprang die Zahl hier bisher bei jedem
              // Zifferwechsel in der Breite.
              MetricValue.of(
                SpeedFormat.speedParts(speedMps, unit),
                size: 72,
                alignment: CrossAxisAlignment.center,
              ),
              const SizedBox(height: Insets.m),
              Text(
                l.liveRecording,
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
              const SizedBox(height: Insets.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MetricValue.of(
                    SpeedFormat.distanceParts(distanceM, unit),
                    icon: Icons.straighten,
                    label: l.liveDistance,
                    size: 22,
                    alignment: CrossAxisAlignment.center,
                  ),
                  const SizedBox(width: Insets.xxl),
                  MetricValue(
                    value: Formatters.duration(elapsed),
                    icon: Icons.timer_outlined,
                    label: l.liveDuration,
                    size: 22,
                    alignment: CrossAxisAlignment.center,
                  ),
                ],
              ),
              const SizedBox(height: Insets.xxl),
              // Statisch und unaufdringlich. Bewusst keine Warnung, die
              // bei hohem Tempo aufpoppt: die zoege den Blick genau in dem
              // Moment aufs Display, in dem er dort nicht hingehoert.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Insets.xxl),
                child: Text(
                  l.liveSpeedNotice,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ),
            ] else ...[
              Icon(Icons.speed, size: 96, color: muted),
              const SizedBox(height: Insets.l),
              Text(
                l.liveReady,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: Insets.s),
              Text(
                l.liveUnit(unit == UnitSystem.kmh ? 'km/h' : 'mph'),
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
