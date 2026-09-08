import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';
import 'package:speedster/settings/settings_controller.dart';

/// Passenger protection: after a trip ends, ask whether the user actually drove.
/// Kept trips stay; discarded trips are marked kept=false (excluded everywhere).
class DriverPrompt extends ConsumerWidget {
  const DriverPrompt({super.key, required this.tripId});

  final int tripId;

  Future<void> _resolve(WidgetRef ref, BuildContext context, bool kept) async {
    await ref.read(tripRepositoryProvider).setKept(tripId, kept);
    ref.invalidate(keptTripsProvider);
    if (context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    // Push a kept trip to the cloud if the user opted in.
    if (kept && ref.read(settingsControllerProvider).cloudEnabled) {
      await ref.read(cloudSyncServiceProvider).syncOnce();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l.driverTitle),
      content: Text(l.driverBody),
      actions: [
        TextButton(
          onPressed: () => _resolve(ref, context, false),
          child: Text(l.driverDiscard),
        ),
        FilledButton(
          onPressed: () => _resolve(ref, context, true),
          child: Text(l.driverKeep),
        ),
      ],
    );
  }
}
