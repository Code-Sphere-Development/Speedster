import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/cloud/vehicle_repository.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';

/// Die Garage: Fahrzeuge anlegen, das Standardfahrzeug waehlen, loeschen.
///
/// Die Fahrzeuge stehen in der Cloud, nicht auf dem Geraet -- sie gehoeren
/// zum Konto, und die Fahrzeugwertung braucht sie ohnehin dort.
class GarageScreen extends ConsumerWidget {
  const GarageScreen({super.key});

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Vehicle vehicle,
  ) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(vehicle.name),
        content: Text(l.garageDeleteConfirm),
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
      await ref.read(vehicleRepositoryProvider).remove(vehicle.id);
      ref.invalidate(vehiclesProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final vehicles = ref.watch(vehiclesProvider);
    final cloud = ref.watch(cloudActiveProvider).asData?.value ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(l.garageTitle)),
      floatingActionButton: cloud
          ? FloatingActionButton.extended(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const VehicleDialog(),
              ),
              icon: const Icon(Icons.add),
              label: Text(l.garageAdd),
            )
          : null,
      body: !cloud
          // Ohne Cloud gibt es kein Konto, an dem Fahrzeuge haengen
          // koennten. Eine leere Liste saehe aus wie ein Fehler.
          ? _Hint(text: l.garageNeedsCloud)
          : vehicles.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _Hint(text: l.commonError(e.toString())),
              data: (list) => list.isEmpty
                  ? _Hint(text: l.garageEmpty)
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 88),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            l.garageLead,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        for (final vehicle in list)
                          _VehicleTile(
                            vehicle: vehicle,
                            onDelete: () => _confirmDelete(context, ref, vehicle),
                          ),
                      ],
                    ),
            ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(text, textAlign: TextAlign.center),
        ),
      );
}

class _VehicleTile extends ConsumerWidget {
  const _VehicleTile({required this.vehicle, required this.onDelete});

  final Vehicle vehicle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    // Baujahr, Leistung, Klasse und Antrieb in einer Zeile: einzeln
    // aufgefuehrt bliebe die Kachel meist halb leer, weil der Katalog
    // Klasse und Antrieb nur fuer einen Teil der Modelle kennt.
    final details = [
      vehicle.model?.label ?? l.garageModelNone,
      if (vehicle.year != null) '${vehicle.year}',
      if (vehicle.powerPs != null) '${vehicle.powerPs} PS',
      if (vehicle.model?.vehicleClass != null) vehicle.model!.vehicleClass!,
      if (vehicle.model?.fuel != null) vehicle.model!.fuel!,
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    vehicle.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (vehicle.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      l.garageDefault,
                      // Flaeche und Schrift aus demselben Paar -- sonst
                      // steht die Beschriftung auf eigener Farbe.
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(details, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Row(
              children: [
                if (!vehicle.isDefault)
                  TextButton(
                    onPressed: () async {
                      await ref
                          .read(vehicleRepositoryProvider)
                          .makeDefault(vehicle.id);
                      ref.invalidate(vehiclesProvider);
                    },
                    child: Text(l.garageMakeDefault),
                  ),
                const Spacer(),
                TextButton(onPressed: onDelete, child: Text(l.garageDelete)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Anlegen eines Fahrzeugs, mit Suche im Katalog der Cloud.
class VehicleDialog extends ConsumerStatefulWidget {
  const VehicleDialog({super.key});

  @override
  ConsumerState<VehicleDialog> createState() => _VehicleDialogState();
}

class _VehicleDialogState extends ConsumerState<VehicleDialog> {
  final _name = TextEditingController();
  final _search = TextEditingController();
  final _year = TextEditingController();
  final _power = TextEditingController();

  List<VehicleModel> _models = const [];
  VehicleModel? _chosen;
  bool _searching = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _search.dispose();
    _year.dispose();
    _power.dispose();
    super.dispose();
  }

  Future<void> _searchModels() async {
    setState(() => _searching = true);
    final found =
        await ref.read(vehicleRepositoryProvider).searchModels(_search.text);
    if (mounted) {
      setState(() {
        _models = found;
        _searching = false;
      });
    }
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    if (_name.text.trim().isEmpty) {
      setState(() => _error = l.garageName);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(vehicleRepositoryProvider).create(
            name: _name.text.trim(),
            vehicleModelId: _chosen?.id,
            year: int.tryParse(_year.text),
            powerPs: int.tryParse(_power.text),
          );
      ref.invalidate(vehiclesProvider);
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(l.garageSaved)));
    } on VehicleException catch (e) {
      setState(() {
        _error = e.message ?? l.commonNoConnection;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l.garageAdd),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _name,
              decoration: InputDecoration(
                labelText: l.garageName,
                helperText: l.garageNameHint,
                errorText: _error,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    decoration: InputDecoration(labelText: l.garageModelSearch),
                    onSubmitted: (_) => _searchModels(),
                  ),
                ),
                IconButton(
                  onPressed: _searching ? null : _searchModels,
                  icon: const Icon(Icons.search),
                ),
              ],
            ),
            if (_models.isNotEmpty)
              // Die Auswahl kommt vom Server; ohne Suchbegriff antwortet er
              // mit einer leeren Liste, statt zehntausend Modelle zu
              // schicken.
              DropdownButton<VehicleModel>(
                isExpanded: true,
                value: _chosen,
                hint: Text(l.garageModelNone),
                items: [
                  for (final model in _models)
                    DropdownMenuItem(value: model, child: Text(model.label)),
                ],
                onChanged: (m) => setState(() => _chosen = m),
              )
            else if (_search.text.isNotEmpty && !_searching)
              Text(
                l.garageNoModels,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            Text(
              l.garageModelHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _year,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l.garageYear),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _power,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l.garagePower),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(l.commonSave),
        ),
      ],
    );
  }
}
