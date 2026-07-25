import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/settings/settings_controller.dart';
import 'package:speedster/settings/unit_system.dart';

/// Shows current speed during a drive; idle prompt otherwise.
class LiveScreen extends ConsumerWidget {
  const LiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(settingsControllerProvider).unit;
    final stateAsync = ref.watch(recorderStateProvider);

    final state = stateAsync.asData?.value;
    final driving = state?.isDriving ?? false;
    final speedMps = state?.last?.speed ?? 0;

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
              const Text('Fahrt wird aufgezeichnet'),
            ] else ...[
              const Icon(Icons.speed, size: 96),
              const SizedBox(height: 16),
              const Text(
                'Bereit.\nDeine Fahrt wird automatisch erkannt.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text('Einheit: ${unit == UnitSystem.kmh ? 'km/h' : 'mph'}'),
            ],
          ],
        ),
      ),
    );
  }
}
