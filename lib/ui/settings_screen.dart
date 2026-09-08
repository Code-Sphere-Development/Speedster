import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:speedster/app/links.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/settings/settings_controller.dart';
import 'package:speedster/settings/unit_system.dart';
import 'package:speedster/ui/auth_screen.dart';
import 'package:speedster/ui/friends_screen.dart';
import 'package:url_launcher/url_launcher.dart';

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
    // Reihenfolge zaehlt: erst hochladen, dann den Vorrat aufbauen. Der
    // Cache-Lauf raeumt nur bestaetigt hochgeladene Fahrten weg -- lief er
    // zuerst, blieben die eben erst lokal aufgezeichneten Fahrten liegen
    // und wuerden erst beim naechsten Start weggeraeumt.
    await ref.read(cloudSyncServiceProvider).syncOnce();
    await ref.read(tripCacheServiceProvider).refresh();
    ref.invalidate(keptTripsProvider);
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
          const _CloudAccountSection(),
          const Divider(),
          const _AboutSection(),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Fahre stets verantwortungsvoll. Es gilt die StVO. '
              'Die Nutzung erfolgt auf eigene Gefahr. Ohne aktivierte '
              'Cloud-Synchronisierung bleiben alle Daten auf deinem Gerät.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Benutzername und Freunde -- nur sichtbar, wenn die Cloud in Gebrauch
/// ist. Ohne Konto gibt es weder das eine noch das andere.
class _CloudAccountSection extends ConsumerWidget {
  const _CloudAccountSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(cloudAccountProvider).asData?.value;
    if (account == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(),
        ListTile(
          leading: const Icon(Icons.alternate_email),
          title: const Text('Benutzername'),
          subtitle: Text(
            // Bestandskonten haben noch keinen; vergeben wird er im Web.
            account.username ?? 'Noch keiner vergeben — im Web nachholen',
          ),
        ),
        ListTile(
          leading: const Icon(Icons.people_outline),
          title: const Text('Freunde'),
          subtitle: const Text('Kennzahlen mit Bekannten vergleichen'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => FriendsScreen(username: account.username),
            ),
          ),
        ),
      ],
    );
  }
}

/// Rechtliches, Hilfe und Unterstuetzung.
class _AboutSection extends StatelessWidget {
  const _AboutSection();

  Future<void> _open(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Der Link liess sich nicht oeffnen.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: const Icon(Icons.help_outline),
          title: const Text('Hilfe'),
          subtitle: const Text('Dokumentation und Fehlermeldungen auf GitHub'),
          onTap: () => _open(context, AppLinks.help),
        ),
        ListTile(
          leading: const Icon(Icons.star_outline),
          title: const Text('Bewerte die App'),
          onTap: () => _open(context, AppLinks.review),
        ),
        ListTile(
          leading: const Icon(Icons.rate_review_outlined),
          title: const Text('Feedback'),
          subtitle: const Text('Im App Store'),
          onTap: () => _open(context, AppLinks.appStore),
        ),
        ListTile(
          leading: const Icon(Icons.volunteer_activism_outlined),
          title: const Text('Trinkgeld'),
          subtitle: const Text('Die Entwicklung unterstützen'),
          onTap: () => _open(context, AppLinks.tip),
        ),
        const _VersionTile(),
      ],
    );
  }
}

/// Version und Build-Nummer.
///
/// Aus dem Paket gelesen statt aus einer Konstanten: eine von Hand
/// gepflegte Zahl weicht frueher oder spaeter von der tatsaechlich
/// installierten ab -- und dann ist sie in einem Fehlerbericht schlimmer
/// als keine Angabe.
class _VersionTile extends StatelessWidget {
  const _VersionTile();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;

        return ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Version'),
          subtitle: Text(
            info == null ? '—' : '${info.version} (${info.buildNumber})',
          ),
        );
      },
    );
  }
}
