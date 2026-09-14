import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedster/app/permissions.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/app/spacing.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';

/// Bittet um "Immer" -- und weist den Weg, wenn iOS nicht mehr fragt.
///
/// Der Systemdialog dafuer erscheint **hoechstens einmal je
/// Installation**. permission_handler merkt sich das sogar selbst: steht
/// die Marke `permission_requested` in den NSUserDefaults, kehrt die
/// Anfrage stillschweigend zurueck, ohne irgendetwas zu zeigen.
///
/// Ohne die Nachkontrolle unten taete der Knopf dann nichts und sagte
/// nichts -- und der Nutzer bliebe bei "Beim Verwenden", ohne zu wissen,
/// warum. Genau so sind einmal Fahrten eines ganzen Tages verlorengegangen.
Future<void> promptForAlwaysAccess(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  final gate = ref.read(permissionGateProvider);

  final after = await gate.requestAlways();
  ref.invalidate(locationAccessProvider);

  if (after.survivesTermination || !context.mounted) return;

  // Die Anfrage hat nichts bewirkt. Ab hier hilft nur noch die
  // Systemeinstellung.
  final open = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.locationAlwaysManualTitle),
      content: Text(l.locationAlwaysManualBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l.commonLater),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l.locationAlwaysOpenSettings),
        ),
      ],
    ),
  );

  if (open ?? false) await gate.openSettings();
}

/// Hinweis, solange die Berechtigung nicht zum Aufzeichnen reicht.
///
/// Steht ueber der Fahrtenliste, weil der Fehlerfall stiller
/// Datenverlust ist: die App zeichnet scheinbar auf, verliert die Fahrt
/// aber, sobald iOS sie beendet. Ohne sichtbaren Hinweis faellt das erst
/// auf, wenn die Fahrten fehlen -- und dann ist es zu spaet.
class LocationAccessBanner extends ConsumerWidget {
  const LocationAccessBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(locationAccessProvider).asData?.value;
    if (access == null || access.survivesTermination) {
      return const SizedBox.shrink();
    }

    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        Insets.l,
        Insets.l,
        Insets.l,
        0,
      ),
      padding: const EdgeInsets.all(Insets.m),
      decoration: BoxDecoration(
        color: scheme.error.withValues(alpha: 0.12),
        border: Border.all(color: scheme.error.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(Radii.small),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 20, color: scheme.error),
          const SizedBox(width: Insets.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  access == LocationAccess.denied
                      ? l.locationBannerDenied
                      : l.locationBannerWhileInUse,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: Insets.xs),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: scheme.error,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () async {
                    // Ohne jede Freigabe fuehrt die Anfrage ins Leere --
                    // dann gleich in die Systemeinstellungen.
                    if (access == LocationAccess.denied) {
                      await ref.read(permissionGateProvider).openSettings();
                      return;
                    }
                    await promptForAlwaysAccess(context, ref);
                  },
                  child: Text(l.locationBannerAction),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
