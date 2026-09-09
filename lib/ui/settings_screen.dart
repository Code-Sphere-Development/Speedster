import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:speedster/app/links.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';
import 'package:speedster/settings/settings_controller.dart';
import 'package:speedster/settings/unit_system.dart';
import 'package:speedster/ui/auth_screen.dart';
import 'package:speedster/ui/backup_screen.dart';
import 'package:speedster/ui/friends_screen.dart';
import 'package:speedster/ui/tour_screen.dart';
import 'package:speedster/ui/username_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmDeleteAll(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.settingsDeleteAllTitle),
        content: Text(l.settingsDeleteAllBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.commonDelete),
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
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.settingsDeleteAccountTitle),
        content: Text(l.settingsDeleteAccountBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.commonDelete),
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
    final l = AppLocalizations.of(context);
    final controller = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      body: ListView(
        children: [
          SwitchListTile(
            key: const Key('unitSwitch'),
            title: Text(l.settingsUnitTitle),
            subtitle: Text(l.settingsUnitSubtitle),
            value: settings.unit == UnitSystem.mph,
            onChanged: (v) =>
                controller.setUnit(v ? UnitSystem.mph : UnitSystem.kmh),
          ),
          SwitchListTile(
            key: const Key('pauseSwitch'),
            title: Text(l.settingsPauseTitle),
            subtitle: Text(l.settingsPauseSubtitle),
            value: settings.trackingPaused,
            onChanged: controller.setTrackingPaused,
          ),
          const Divider(),
          SwitchListTile(
            key: const Key('cloudSwitch'),
            title: Text(l.settingsCloudTitle),
            subtitle: Text(l.settingsCloudSubtitle),
            value: settings.cloudEnabled,
            onChanged: (v) => _toggleCloud(context, ref, v),
          ),
          if (settings.cloudEnabled)
            ListTile(
              leading: const Icon(Icons.person_remove),
              title: Text(l.settingsDeleteAccount),
              onTap: () => _deleteAccount(context, ref),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: Text(l.settingsDeleteAll),
            onTap: () => _confirmDeleteAll(context, ref),
          ),
          const _CloudAccountSection(),
          const Divider(),
          const _AboutSection(),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l.settingsDisclaimer,
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
    final l = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(),
        ListTile(
          leading: const Icon(Icons.alternate_email),
          title: Text(l.settingsUsername),
          subtitle: Text(
            // Bestandskonten haben noch keinen; vergeben wird er im Web.
            account.username ?? l.settingsUsernameMissing,
          ),
          // Ohne Namen fuehrt der Weg ueber das Web -- die App aendert
          // nur einen bestehenden.
          trailing: account.username == null
              ? null
              : const Icon(Icons.edit_outlined),
          onTap: account.username == null
              ? null
              : () => showDialog<void>(
                    context: context,
                    builder: (_) => UsernameDialog(account: account),
                  ),
        ),
        ListTile(
          leading: const Icon(Icons.explore_outlined),
          title: Text(l.settingsTour),
          subtitle: Text(l.settingsTourSubtitle),
          trailing: const Icon(Icons.chevron_right),
          // Erneut aufrufbar: ein Rundgang, den man genau einmal sieht und
          // nie wieder, ist beim zweiten Fragezeichen wertlos.
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => const TourScreen()),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.save_outlined),
          title: Text(l.settingsBackup),
          subtitle: Text(l.settingsBackupSubtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => const BackupScreen()),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.people_outline),
          title: Text(l.settingsFriends),
          subtitle: Text(l.settingsFriendsSubtitle),
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
    // Vor dem Warten holen: danach ist der Kontext moeglicherweise nicht
    // mehr eingehaengt.
    final failure = AppLocalizations.of(context).settingsLinkFailed;
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened) {
      messenger.showSnackBar(SnackBar(content: Text(failure)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: const Icon(Icons.help_outline),
          title: Text(l.settingsHelp),
          subtitle: Text(l.settingsHelpSubtitle),
          onTap: () => _open(context, AppLinks.help),
        ),
        ListTile(
          leading: const Icon(Icons.star_outline),
          title: Text(l.settingsRate),
          onTap: () => _open(context, AppLinks.review),
        ),
        ListTile(
          leading: const Icon(Icons.rate_review_outlined),
          title: Text(l.settingsFeedback),
          subtitle: Text(l.settingsFeedbackSubtitle),
          onTap: () => _open(context, AppLinks.appStore),
        ),
        ListTile(
          leading: const Icon(Icons.mail_outline),
          title: Text(l.settingsContact),
          subtitle: Text(l.settingsContactSubtitle),
          onTap: () => _open(context, AppLinks.contact),
        ),
        ListTile(
          leading: const Icon(Icons.volunteer_activism_outlined),
          title: Text(l.settingsTip),
          subtitle: Text(l.settingsTipSubtitle),
          onTap: () => _open(context, AppLinks.tip),
        ),
        const Divider(),
        // Rechtstexte liegen in der Cloud, nicht in der App: ein Text
        // statt zweier, und Aenderungen brauchen kein App-Update.
        ListTile(
          leading: const Icon(Icons.gavel_outlined),
          title: Text(l.settingsImprint),
          onTap: () => _open(context, AppLinks.imprint),
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: Text(l.settingsPrivacy),
          onTap: () => _open(context, AppLinks.privacy),
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
          title: Text(AppLocalizations.of(context).settingsVersion),
          subtitle: Text(
            info == null ? '—' : '${info.version} (${info.buildNumber})',
          ),
        );
      },
    );
  }
}
