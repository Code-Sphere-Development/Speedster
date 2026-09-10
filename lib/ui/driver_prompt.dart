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
    final repo = ref.read(tripRepositoryProvider);
    // Vor dem Umsetzen holen: danach findet keptTrips() die Fahrt nicht
    // mehr, und fuer die Cloud braucht es ihre UUID.
    final clientUuid = kept ? null : await repo.clientUuidFor(tripId);

    await repo.setKept(tripId, kept);
    ref.invalidate(keptTripsProvider);
    if (context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    if (!ref.read(settingsControllerProvider).cloudEnabled) return;
    final sync = ref.read(cloudSyncServiceProvider);

    if (kept) {
      // Meist schon am Fahrtende geschehen; ein zweiter Lauf schadet
      // nicht und holt nach, was damals ohne Netz liegenblieb.
      await sync.syncOnce();

      return;
    }

    // Nicht selbst gefahren: am Fahrtende wurde bereits hochgeladen, also
    // muss die Fahrt dort wieder weg.
    if (clientUuid != null && clientUuid.isNotEmpty) {
      try {
        await sync.deleteRemote(clientUuid);
      } on Exception {
        // Ohne Netz bleibt sie oben. Lokal ist sie verworfen, und der
        // Nutzer kann sie im Web loeschen -- besser als ein Fehler, den
        // er nicht aufloesen kann.
      }
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
