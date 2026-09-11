import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/app/spacing.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';
import 'package:speedster/settings/settings_controller.dart';
import 'package:speedster/settings/unit_system.dart';
import 'package:speedster/ui/components/metric_value.dart';
import 'package:speedster/ui/components/speed_gauge.dart';
import 'package:speedster/ui/formatters.dart';

/// Der Tacho waehrend der Fahrt.
///
/// Zeigt den Zustand aus [liveStateProvider] und nicht direkt den des
/// Rekorders: bei eingeschalteter Vorschau kommt er von einer erfundenen
/// Fahrt, damit sich diese Ansicht ohne Losfahren ansehen laesst.
class LiveScreen extends ConsumerWidget {
  const LiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(settingsControllerProvider).unit;
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    final state = ref.watch(liveStateProvider).asData?.value;
    final driving = state?.isDriving ?? false;
    final speedMps = state?.last?.speed ?? 0;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: Insets.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Der Tacho steht auch im Stand -- auf null. Ein leerer
            // Bildschirm mit einem Symbol sagte weniger als eine Skala,
            // die zeigt, worauf sie wartet.
            SpeedGauge(speedMps: speedMps, unit: unit),
            const SizedBox(height: Insets.l),
            Text(
              driving ? l.liveRecording : l.liveReady,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
            if (driving) ...[
              const SizedBox(height: Insets.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MetricValue.of(
                    SpeedFormat.distanceParts(state?.distanceMeters ?? 0, unit),
                    icon: Icons.straighten,
                    label: l.liveDistance,
                    size: 22,
                    alignment: CrossAxisAlignment.center,
                  ),
                  const SizedBox(width: Insets.xxl),
                  MetricValue(
                    value: Formatters.duration(state?.elapsedSeconds ?? 0),
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
