import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:speedster/app/links.dart';
import 'package:speedster/app/permissions.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/app/spacing.dart';
import 'package:speedster/cloud/cloud_sync_service.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';
import 'package:speedster/settings/settings_controller.dart';
import 'package:speedster/settings/unit_system.dart';
import 'package:speedster/ui/auth_screen.dart';
import 'package:speedster/ui/backup_screen.dart';
import 'package:speedster/ui/friends_screen.dart';
import 'package:speedster/ui/components/card_section.dart';
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
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
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

  /// Schaltet die Meldung zum Fahrtbeginn ein oder aus.
  ///
  /// Die Erlaubnis wird erst beim Einschalten abgefragt und nicht beim
  /// ersten Start: ungefragt gefragt zu werden laedt zum Ablehnen ein,
  /// und danach fuehrt der Weg nur noch ueber die Systemeinstellungen.
  ///
  /// Wird sie verweigert, bleibt der Schalter aus. Ihn umzulegen und dann
  /// nichts zu melden waere die schlechtere Antwort -- die Funktion ist
  /// eine Gegenprobe, und eine, die stumm ausfaellt, ist keine.
  Future<void> _toggleNotify(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    final controller = ref.read(settingsControllerProvider.notifier);

    if (!enabled) {
      await controller.setNotifyOnTripStart(false);
      return;
    }

    // Vor dem Warten holen: danach ist der Kontext moeglicherweise nicht
    // mehr eingehaengt.
    final messenger = ScaffoldMessenger.of(context);
    final denied = AppLocalizations.of(context).settingsNotifyDenied;

    if (await ref.read(tripNotifierProvider).requestPermission()) {
      await controller.setNotifyOnTripStart(true);
      return;
    }

    messenger.showSnackBar(SnackBar(content: Text(denied)));
  }

  /// Wie [_toggleNotify], nur fuer die Wartungserinnerung.
  ///
  /// Dieselbe Erlaubnis, dieselbe Abfrage: iOS kennt nur eine je App.
  /// Steht sie schon, kommt kein Dialog mehr.
  Future<void> _toggleMaintenance(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    final controller = ref.read(settingsControllerProvider.notifier);

    if (!enabled) {
      await controller.setNotifyMaintenance(false);
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final denied = AppLocalizations.of(context).settingsNotifyDenied;

    if (await ref.read(tripNotifierProvider).requestPermission()) {
      await controller.setNotifyMaintenance(true);
      return;
    }

    messenger.showSnackBar(SnackBar(content: Text(denied)));
  }

  Future<void> _toggleCloud(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    if (!enabled) {
      // Ausschalten heisst abmelden. Frueher blieb der Token liegen: die
      // App zeigte weiter Cloud-Daten, lud aber nichts mehr hoch -- zwei
      // Wahrheiten fuer dieselbe Frage, und nach einer Neuinstallation
      // (der Schluesselbund ueberlebt sie, die Einstellungen nicht) stand
      // die App genau in diesem Zwischenzustand.
      await ref.read(tokenStoreProvider).clear();
      ref
        ..invalidate(cloudActiveProvider)
        ..invalidate(keptTripsProvider)
        ..invalidate(pendingUploadsProvider);

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
    ref.invalidate(cloudActiveProvider);
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
    // Der geloeschte Token ist zugleich das Aus fuer die Cloud: einen
    // zweiten Schalter dafuer gibt es nicht mehr.
    await ref.read(tokenStoreProvider).clear();
    ref
      ..invalidate(cloudActiveProvider)
      ..invalidate(keptTripsProvider)
      ..invalidate(pendingUploadsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final l = AppLocalizations.of(context);
    final controller = ref.read(settingsControllerProvider.notifier);
    final cloudOn = ref.watch(cloudActiveProvider).asData?.value ?? false;

    return Scaffold(
      body: ListView(
        // Keine Seitenueberschrift mehr: die traegt der Kopfbereich der
        // App.
        padding: const EdgeInsets.only(top: Insets.l, bottom: Insets.s),
        children: [
          CardSection(
            title: l.settingsSectionRecording,
            icon: Icons.fiber_manual_record_outlined,
            children: [
          const _LocationAccessTile(),
          SwitchListTile(
            key: const Key('unitSwitch'),
            secondary: const Icon(Icons.straighten),
            title: Text(l.settingsUnitTitle),
            subtitle: Text(l.settingsUnitSubtitle),
            value: settings.unit == UnitSystem.mph,
            onChanged: (v) =>
                controller.setUnit(v ? UnitSystem.mph : UnitSystem.kmh),
          ),
          SwitchListTile(
            key: const Key('pauseSwitch'),
            secondary: const Icon(Icons.pause_circle_outline),
            title: Text(l.settingsPauseTitle),
            subtitle: Text(l.settingsPauseSubtitle),
            value: settings.trackingPaused,
            onChanged: controller.setTrackingPaused,
          ),
            ],
          ),
          CardSection(
            title: l.settingsSectionNotifications,
            icon: Icons.notifications_none,
            children: [
              SwitchListTile(
                key: const Key('notifySwitch'),
                secondary: const Icon(Icons.notifications_active_outlined),
                title: Text(l.settingsNotifyTitle),
                subtitle: Text(l.settingsNotifySubtitle),
                value: settings.notifyOnTripStart,
                onChanged: (v) => _toggleNotify(context, ref, v),
              ),
              SwitchListTile(
                key: const Key('maintenanceSwitch'),
                secondary: const Icon(Icons.build_outlined),
                title: Text(l.settingsMaintenanceTitle),
                subtitle: Text(l.settingsMaintenanceSubtitle),
                value: settings.notifyMaintenance,
                onChanged: (v) => _toggleMaintenance(context, ref, v),
              ),
            ],
          ),
          CardSection(
            title: l.settingsSectionAccount,
            icon: Icons.person_outline,
            children: [
          SwitchListTile(
            key: const Key('cloudSwitch'),
            secondary: const Icon(Icons.cloud_outlined),
            title: Text(l.settingsCloudTitle),
            subtitle: Text(l.settingsCloudSubtitle),
            // Der Token entscheidet, nicht ein zweiter Schalterzustand:
            // sonst laufen beide auseinander.
            value: cloudOn,
            onChanged: (v) => _toggleCloud(context, ref, v),
          ),
          // Benutzername und Freunde: nur mit Konto.
          ..._accountRows(context, ref),
          if (cloudOn)
            _DestructiveTile(
              icon: Icons.person_remove,
              label: l.settingsDeleteAccount,
              onTap: () => _deleteAccount(context, ref),
            ),
            ],
          ),
          CardSection(
            title: l.settingsSectionData,
            icon: Icons.folder_outlined,
            children: [
          // Bewusst nicht im Konto-Abschnitt: der blendet sich aus, wenn
          // das Konto nicht geladen werden kann -- also gerade dann,
          // wenn Uploads warten, naemlich ohne Netz.
          if (cloudOn) const _PendingUploads(),
          // Nicht mehr hinter der Cloud versteckt: ohne sie liegen die
          // Fahrten nur auf dem Geraet, und die Sicherung ist dann das
          // einzige Netz, das es gibt.
          ListTile(
            leading: const Icon(Icons.save_outlined),
            title: Text(l.settingsBackup),
            subtitle: Text(l.settingsBackupSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute(builder: (_) => const BackupScreen()),
            ),
          ),
          _DestructiveTile(
            icon: Icons.delete_forever,
            label: l.settingsDeleteAll,
            onTap: () => _confirmDeleteAll(context, ref),
          ),
            ],
          ),
          CardSection(
            title: l.settingsSectionHelp,
            icon: Icons.help_outline,
            children: [
          SwitchListTile(
            key: const Key('demoRideSwitch'),
            secondary: const Icon(Icons.speed),
            title: Text(l.settingsDemoRide),
            subtitle: Text(l.settingsDemoRideSubtitle),
            value: settings.demoRide,
            onChanged: ref
                .read(settingsControllerProvider.notifier)
                .setDemoRide,
          ),
          ListTile(
            leading: const Icon(Icons.explore_outlined),
            title: Text(l.settingsTour),
            subtitle: Text(l.settingsTourSubtitle),
            trailing: const Icon(Icons.chevron_right),
            // Erneut aufrufbar: ein Rundgang, den man genau einmal sieht
            // und nie wieder, ist beim zweiten Fragezeichen wertlos.
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute(builder: (_) => const TourScreen()),
            ),
          ),
          ..._helpRows(context),
            ],
          ),
          CardSection(
            title: l.settingsSectionLegal,
            icon: Icons.gavel_outlined,
            children: _legalRows(context),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Insets.screen,
              Insets.l,
              Insets.screen,
              Insets.xl,
            ),
            child: Text(
              l.settingsDisclaimer,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Benutzername und Freunde -- nur mit Konto.
///
/// Eine Zeilenliste und kein Widget: ein Widget, das sich selbst
/// ausblendet, ist fuer die Karte darum trotzdem ein Kind, und sie zieht
/// dann eine Trennlinie zu einer leeren Flaeche.
List<Widget> _accountRows(BuildContext context, WidgetRef ref) {
  final account = ref.watch(cloudAccountProvider).asData?.value;
  if (account == null) return const [];

  final l = AppLocalizations.of(context);

  return [
    ListTile(
      leading: const Icon(Icons.alternate_email),
      title: Text(l.settingsUsername),
      subtitle: Text(
        // Bestandskonten haben noch keinen; vergeben wird er im Web.
        account.username ?? l.settingsUsernameMissing,
      ),
      // Ohne Namen fuehrt der Weg ueber das Web -- die App aendert nur
      // einen bestehenden.
      trailing:
          account.username == null ? null : const Icon(Icons.edit_outlined),
      onTap: account.username == null
          ? null
          : () => showDialog<void>(
                context: context,
                builder: (_) => UsernameDialog(account: account),
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
  ];
}

/// Oeffnet einen Rechtstext oder eine Hilfeseite im Browser.
Future<void> _openLink(BuildContext context, String url) async {
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

/// Hilfe und Unterstuetzung.
///
/// Eine Liste von Zeilen und kein eigenes Widget: die Karte darum zieht
/// die Trennlinien zwischen ihnen, und ein Widget dazwischen waere fuer
/// sie ein einziges Kind ohne Linien.
List<Widget> _helpRows(BuildContext context) {
  final l = AppLocalizations.of(context);

  return [
    ListTile(
      leading: const Icon(Icons.help_outline),
      title: Text(l.settingsHelp),
      subtitle: Text(l.settingsHelpSubtitle),
      onTap: () => _openLink(context, AppLinks.help),
    ),
    ListTile(
      leading: const Icon(Icons.star_outline),
      title: Text(l.settingsRate),
      onTap: () => _openLink(context, AppLinks.review),
    ),
    ListTile(
      leading: const Icon(Icons.rate_review_outlined),
      title: Text(l.settingsFeedback),
      subtitle: Text(l.settingsFeedbackSubtitle),
      onTap: () => _openLink(context, AppLinks.appStore),
    ),
    ListTile(
      leading: const Icon(Icons.mail_outline),
      title: Text(l.settingsContact),
      subtitle: Text(l.settingsContactSubtitle),
      onTap: () => _openLink(context, AppLinks.contact),
    ),
    ListTile(
      leading: const Icon(Icons.volunteer_activism_outlined),
      title: Text(l.settingsTip),
      subtitle: Text(l.settingsTipSubtitle),
      onTap: () => _openLink(context, AppLinks.tip),
    ),
  ];
}

/// Rechtliches und die Fassung.
List<Widget> _legalRows(BuildContext context) {
  final l = AppLocalizations.of(context);

  return [
    // Rechtstexte liegen in der Cloud, nicht in der App: ein Text statt
    // zweier, und Aenderungen brauchen kein App-Update.
    ListTile(
      leading: const Icon(Icons.gavel_outlined),
      title: Text(l.settingsImprint),
      onTap: () => _openLink(context, AppLinks.imprint),
    ),
    ListTile(
      leading: const Icon(Icons.privacy_tip_outlined),
      title: Text(l.settingsPrivacy),
      onTap: () => _openLink(context, AppLinks.privacy),
    ),
    const _VersionTile(),
  ];
}

/// Wie weit die Ortung erlaubt ist -- und was das bedeutet.
///
/// Ohne diese Zeile merkte niemand, dass nur "Beim Verwenden" erteilt
/// ist: die App zeichnete auf, solange sie lief, und schwieg dazu, dass
/// sie nach einem Beenden durch iOS nichts mehr mitbekommt.
class _LocationAccessTile extends ConsumerWidget {
  const _LocationAccessTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final access = ref.watch(locationAccessProvider).asData?.value;
    if (access == null) return const SizedBox.shrink();

    final (icon, text, incomplete) = switch (access) {
      LocationAccess.always => (
          Icons.my_location,
          l.settingsLocationAlways,
          false,
        ),
      LocationAccess.whileInUse => (
          Icons.location_searching,
          l.settingsLocationWhileInUse,
          true,
        ),
      LocationAccess.denied => (
          Icons.location_disabled,
          l.settingsLocationDenied,
          true,
        ),
    };

    return ListTile(
      // Die Fehlerfarbe nur, wenn tatsaechlich etwas fehlt -- sonst waere
      // sie Tapete.
      leading: Icon(icon, color: incomplete ? scheme.error : null),
      title: Text(l.settingsLocation),
      subtitle: Text(text),
      trailing: incomplete
          ? TextButton(
              onPressed: () async {
                final gate = ref.read(permissionGateProvider);
                // Erst der Systemdialog; iOS zeigt ihn nur einmal, danach
                // fuehrt der Weg ueber die Einstellungen.
                if (access == LocationAccess.whileInUse) {
                  await gate.requestAlways();
                } else {
                  await gate.openSettings();
                }
                ref.invalidate(locationAccessProvider);
              },
              child: Text(l.settingsLocationFix),
            )
          : null,
    );
  }
}

/// Eine Zeile, die Daten unwiederbringlich loescht.
///
/// Traegt die Fehlerfarbe: vorher sah "Alle Daten loeschen" genauso aus
/// wie "App bewerten" -- gleiches Symbol, gleiche Schrift, gleiches Grau.
class _DestructiveTile extends StatelessWidget {
  const _DestructiveTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;

    return ListTile(
      leading: Icon(icon, color: error),
      title: Text(label, style: TextStyle(color: error)),
      onTap: onTap,
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

/// Wie viele Fahrten auf den Upload warten -- und ein Knopf, es jetzt zu
/// versuchen.
///
/// Ohne diese Anzeige ist der Upload eine Blackbox: eine Fahrt fehlt in
/// der Cloud, und niemand kann sagen, ob sie wartet, abgewiesen wurde
/// oder nie aufgezeichnet worden ist.
class _PendingUploads extends ConsumerStatefulWidget {
  const _PendingUploads();

  @override
  ConsumerState<_PendingUploads> createState() => _PendingUploadsState();
}

class _PendingUploadsState extends ConsumerState<_PendingUploads> {
  bool _busy = false;

  Future<void> _upload() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final sync = ref.read(cloudSyncServiceProvider);

    setState(() => _busy = true);

    String message;
    try {
      final outcome = await sync.syncOnce();

      // Vier Faelle, die sich vorher alle gleich anfuehlten. Vor allem
      // der erste: ohne Anmeldung tat der Abgleich nichts und meldete
      // "nichts zu tun" -- neben vier wartenden Fahrten.
      message = switch (outcome) {
        SyncOutcome(loggedIn: false) => l.settingsPendingLoggedOut,
        SyncOutcome(unreachable: true) => l.settingsPendingFailed,
        SyncOutcome(serverStatus: final status?) =>
          l.settingsPendingServerError(status),
        SyncOutcome(rejected: final n) when n > 0 =>
          l.settingsPendingRejected(n),
        SyncOutcome(uploaded: final n) => l.settingsPendingDone(n),
      };
    } on Exception {
      message = l.settingsPendingFailed;
    }

    ref
      ..invalidate(pendingUploadsProvider)
      ..invalidate(keptTripsProvider);

    if (mounted) setState(() => _busy = false);
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    // ConsumerState kennt `ref` selbst -- ein Parameter waere hier der
    // falsche Bauplan.
    final l = AppLocalizations.of(context);
    final pending = ref.watch(pendingUploadsProvider).asData?.value;

    // Ohne Cloud gibt es nichts hochzuladen -- dann auch keine Zeile
    // darueber.
    if (!(ref.watch(cloudActiveProvider).asData?.value ?? false)) {
      return const SizedBox.shrink();
    }

    return ListTile(
      leading: const Icon(Icons.cloud_upload_outlined),
      title: Text(l.settingsPending),
      subtitle: Text(l.settingsPendingCount(pending ?? 0)),
      trailing: _busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : TextButton(
              // Auch bei null wartenden Fahrten anklickbar: der Lauf holt
              // dann nichts, aber der Nutzer bekommt eine Antwort statt
              // eines toten Knopfes.
              onPressed: _upload,
              child: Text(l.settingsPendingAction),
            ),
    );
  }
}
