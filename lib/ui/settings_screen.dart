import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/settings/settings_controller.dart';
import 'package:speedster/settings/unit_system.dart';
import 'package:speedster/ui/auth_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmDeleteAll(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alle Daten löschen?'),
        content: const Text(
          'Alle aufgezeichneten Fahrten werden unwiderruflich gelöscht.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(tripRepositoryProvider).deleteAll();
      ref.invalidate(keptTripsProvider);
    }
  }

  Future<void> _toggleCloud(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    final controller = ref.read(settingsControllerProvider.notifier);
    if (!enabled) {
      await controller.setCloudEnabled(false);
      return;
    }

    final token = await ref.read(tokenStoreProvider).read();
    if (token == null) {
      if (!context.mounted) return;
      final loggedIn = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
      if (loggedIn != true) return; // user cancelled → stay disabled
    }
    await controller.setCloudEnabled(true);
    await ref.read(cloudSyncServiceProvider).syncOnce();
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Account löschen?'),
        content: const Text(
          'Dein Cloud-Konto und alle hochgeladenen Fahrten werden gelöscht.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(apiClientProvider).dio.delete('/account');
    } catch (_) {
      // Ignore network errors; still clear locally.
    }
    await ref.read(tokenStoreProvider).clear();
    await ref.read(settingsControllerProvider.notifier).setCloudEnabled(false);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      body: ListView(
        children: [
          SwitchListTile(
            key: const Key('unitSwitch'),
            title: const Text('Einheit: Meilen (mph)'),
            subtitle: const Text('Aus = km/h'),
            value: settings.unit == UnitSystem.mph,
            onChanged: (v) =>
                controller.setUnit(v ? UnitSystem.mph : UnitSystem.kmh),
          ),
          SwitchListTile(
            key: const Key('pauseSwitch'),
            title: const Text('Tracking pausieren'),
            subtitle: const Text('Keine automatische Fahrterkennung'),
            value: settings.trackingPaused,
            onChanged: controller.setTrackingPaused,
          ),
          const Divider(),
          SwitchListTile(
            key: const Key('cloudSwitch'),
            title: const Text('Cloud-Sync aktivieren'),
            subtitle: const Text(
              'Fahrten in die Cloud sichern (Backup + Rankings). '
              'Aus = alles bleibt nur auf dem Gerät.',
            ),
            value: settings.cloudEnabled,
            onChanged: (v) => _toggleCloud(context, ref, v),
          ),
          if (settings.cloudEnabled)
            ListTile(
              leading: const Icon(Icons.person_remove),
              title: const Text('Cloud-Account löschen'),
              onTap: () => _deleteAccount(context, ref),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text('Alle Daten löschen'),
            onTap: () => _confirmDeleteAll(context, ref),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Fahre stets verantwortungsvoll. Es gilt die StVO. '
              'Die Nutzung erfolgt auf eigene Gefahr. Alle Daten bleiben lokal '
              'auf deinem Gerät.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
