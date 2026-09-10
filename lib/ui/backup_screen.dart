import 'dart:io';

import 'package:flutter/material.dart';
import 'package:speedster/ui/components/gradient_header.dart';
import 'package:speedster/app/spacing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';

/// Sicherung der Fahrten in eine Datei und zurueck.
///
/// Ohne Cloud liegen die Fahrten ausschliesslich auf dem Geraet -- ein
/// neues Telefon faenge sonst bei null an.
///
/// Die Datei landet im Dokumentenordner der App und ist damit ueber die
/// Dateien-App erreichbar. Ein Auswahldialog waere schoener, braeuchte
/// aber ein weiteres Paket; der Ordner tut es auch, solange er sichtbar
/// ist (siehe UIFileSharingEnabled in der Info.plist).
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  List<File> _files = const [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final files = await ref.read(backupServiceProvider).available();
    if (mounted) setState(() => _files = files);
  }

  Future<void> _export() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);

    final service = ref.read(backupServiceProvider);
    await service.export();
    final trips = await ref.read(tripRepositoryProvider).keptTrips();
    await _refresh();

    if (mounted) setState(() => _busy = false);
    messenger.showSnackBar(
      SnackBar(content: Text(l.backupExportDone(trips.length))),
    );
  }

  Future<void> _import(File file) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);

    try {
      final result = await ref.read(backupServiceProvider).importFrom(file);
      // Fahrtenliste und Heatmap zeigen sonst weiter den alten Bestand.
      ref.invalidate(keptTripsProvider);
      messenger.showSnackBar(SnackBar(
        content: Text(l.backupImportDone(result.imported, result.skipped)),
      ));
    } on FormatException {
      messenger.showSnackBar(SnackBar(content: Text(l.backupImportFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      body: Column(
        children: [
          GradientHeader(title: l.backupTitle, showBack: true),
          Expanded(
            child: ListView(
        padding: const EdgeInsets.all(Insets.screen),
        children: [
          Text(l.backupLead),
          const SizedBox(height: Insets.l),
          FilledButton.icon(
            onPressed: _busy ? null : _export,
            icon: const Icon(Icons.save_outlined),
            label: Text(l.backupExport),
          ),
          const Divider(height: Insets.xxl),
          Text(l.backupFiles, style: Theme.of(context).textTheme.titleSmall),
          if (_files.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: Insets.s),
              child: Text(
                l.backupNone,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          else
            for (final file in _files)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined),
                title: Text(file.uri.pathSegments.last),
                trailing: TextButton(
                  onPressed: _busy ? null : () => _import(file),
                  child: Text(l.backupImport),
                ),
              ),
        ],
      ),
          ),
        ],
      )
    );
  }
}
