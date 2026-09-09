import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
                            onEdit: () => showDialog<void>(
                              context: context,
                              builder: (_) => VehicleDialog(vehicle: vehicle),
                            ),
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
  const _VehicleTile({
    required this.vehicle,
    required this.onDelete,
    required this.onEdit,
  });

  final Vehicle vehicle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

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
            const SizedBox(height: 12),
            _OdometerBlock(vehicle: vehicle),
            const SizedBox(height: 8),
            _MaintenanceBlock(vehicle: vehicle),
            const SizedBox(height: 4),
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
                TextButton(onPressed: onEdit, child: Text(l.garageEdit)),
                TextButton(onPressed: onDelete, child: Text(l.garageDelete)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Der geschaetzte Tachostand samt der Ablesung, auf der er beruht.
///
/// Immer mit "ca." und immer mit der Grundlage daneben: aufgezeichnet
/// wird nur, was die App mitbekommen hat, und die nackte Zahl waere eine
/// Behauptung.
class _OdometerBlock extends ConsumerWidget {
  const _OdometerBlock({required this.vehicle});

  final Vehicle vehicle;

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final controller = TextEditingController(
      text: vehicle.odometer.estimateKm?.toString(),
    );

    final kilometers = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.garageOdometerAdd),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l.garageOdometerKm,
            suffixText: 'km',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(ctx).pop(int.tryParse(controller.text.trim())),
            child: Text(l.commonSave),
          ),
        ],
      ),
    );

    if (kilometers == null) return;
    if (!context.mounted) return;

    // Vor dem Warten holen: danach ist der Kontext moeglicherweise nicht
    // mehr eingehaengt.
    final messenger = ScaffoldMessenger.of(context);
    try {
      // Der Zeitpunkt ist jetzt: abgelesen wird in dem Moment, in dem man
      // es eintraegt. Ab hier zaehlt jede weitere Fahrt darauf.
      final deviation = await ref
          .read(vehicleRepositoryProvider)
          .addReading(vehicle.id, kilometers, DateTime.now());
      ref.invalidate(vehiclesProvider);
      messenger.showSnackBar(SnackBar(
        content: Text(deviation == null
            ? l.garageOdometerSaved
            : l.garageOdometerDeviation(
                '${deviation > 0 ? '+' : ''}$deviation')),
      ));
    } on VehicleException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.message ?? l.commonNoConnection)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final odometer = vehicle.odometer;
    final small = Theme.of(context).textTheme.bodySmall;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                odometer.estimateKm == null
                    ? l.garageOdometerNone
                    : l.garageOdometerEstimate('${odometer.estimateKm}'),
                style: odometer.estimateKm == null
                    ? small
                    : Theme.of(context).textTheme.titleSmall,
              ),
            ),
            TextButton(
              onPressed: () => _add(context, ref),
              child: Text(l.garageOdometerAdd),
            ),
          ],
        ),
        if (odometer.readingKm != null && odometer.readAt != null)
          Text(
            l.garageOdometerBasis(
              '${odometer.readingKm}',
              DateFormat.yMd(Localizations.localeOf(context).toLanguageTag())
                  .format(odometer.readAt!),
              odometer.trackedKm.round().toString(),
            ),
            style: small,
          ),
      ],
    );
  }
}

/// Faellige Wartungen, nach Termin oder Laufleistung.
class _MaintenanceBlock extends ConsumerWidget {
  const _MaintenanceBlock({required this.vehicle});

  final Vehicle vehicle;

  /// Wie weit es noch ist -- in Tagen, in Kilometern oder in beidem.
  ///
  /// Ohne geschaetzten Tachostand bleibt die Kilometerangabe aus: eine
  /// Restangabe ohne Bezugsgroesse waere keine Auskunft.
  String _due(AppLocalizations l, MaintenanceItem item) {
    final parts = <String>[];

    final days = item.daysLeft;
    if (days != null) {
      parts.add(days == 0
          ? l.garageMaintenanceToday
          : days > 0
              ? l.garageMaintenanceInDays(days)
              : l.garageMaintenanceOverdueDays(-days));
    }

    final km = item.kilometersLeft;
    if (km != null) {
      parts.add(km >= 0
          ? l.garageMaintenanceInKm('$km')
          : l.garageMaintenanceOverdueKm('${-km}'));
    } else if (item.dueKm != null) {
      parts.add(l.garageMaintenanceKmUnknown('${item.dueKm}'));
    }

    return parts.join(' · ');
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final added = await showDialog<bool>(
      context: context,
      builder: (_) => MaintenanceDialog(vehicle: vehicle),
    );

    if (added ?? false) ref.invalidate(vehiclesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final small = Theme.of(context).textTheme.bodySmall;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(l.garageMaintenance, style: small)),
            TextButton(
              onPressed: () => _add(context, ref),
              child: Text(l.garageMaintenanceAdd),
            ),
          ],
        ),
        if (vehicle.maintenance.isEmpty)
          Text(l.garageMaintenanceNone, style: small)
        else
          for (final item in vehicle.maintenance)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            // Ueberfaelliges in der Akzentfarbe: es ist
                            // die einzige Zeile, die eine Handlung
                            // verlangt.
                            color: item.overdue ? scheme.primary : null,
                          ),
                        ),
                        Text(_due(l, item), style: small),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await ref
                          .read(vehicleRepositoryProvider)
                          .completeMaintenance(vehicle.id, item.id);
                      ref.invalidate(vehiclesProvider);
                    },
                    child: Text(l.garageMaintenanceDone),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

/// Anlegen einer Wartung: Termin, Laufleistung oder beides.
class MaintenanceDialog extends ConsumerStatefulWidget {
  const MaintenanceDialog({required this.vehicle, super.key});

  final Vehicle vehicle;

  @override
  ConsumerState<MaintenanceDialog> createState() => _MaintenanceDialogState();
}

class _MaintenanceDialogState extends ConsumerState<MaintenanceDialog> {
  final _title = TextEditingController();
  final _km = TextEditingController();
  DateTime? _dueOn;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _km.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
      initialDate: now,
    );
    if (picked != null) setState(() => _dueOn = picked);
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final km = int.tryParse(_km.text.trim());

    // Ohne Termin und ohne Laufleistung waere es kein Termin, sondern eine
    // Notiz -- dieselbe Regel wie am Server.
    if (_title.text.trim().isEmpty || (_dueOn == null && km == null)) {
      setState(() => _error = l.garageMaintenanceNeedsDue);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final navigator = Navigator.of(context);
    try {
      await ref.read(vehicleRepositoryProvider).addMaintenance(
            widget.vehicle.id,
            title: _title.text.trim(),
            dueOn: _dueOn,
            dueKm: km,
          );
      navigator.pop(true);
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
      title: Text(l.garageMaintenanceAdd),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _title,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l.garageMaintenanceTitle,
              helperText: l.garageMaintenanceTitleHint,
              errorText: _error,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _km,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l.garageMaintenanceDueKm,
              suffixText: 'km',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.event_outlined),
            label: Text(
              _dueOn == null
                  ? l.garageMaintenanceDueOn
                  : DateFormat.yMd(
                      Localizations.localeOf(context).toLanguageTag(),
                    ).format(_dueOn!),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
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

/// Anlegen und Bearbeiten eines Fahrzeugs, mit Suche im Katalog der Cloud.
///
/// Ein Dialog fuer beides: die Felder sind dieselben, und zwei Fassungen
/// liefen beim naechsten Feld auseinander. [vehicle] entscheidet, ob
/// angelegt oder geaendert wird.
class VehicleDialog extends ConsumerStatefulWidget {
  const VehicleDialog({this.vehicle, super.key});

  final Vehicle? vehicle;

  @override
  ConsumerState<VehicleDialog> createState() => _VehicleDialogState();
}

class _VehicleDialogState extends ConsumerState<VehicleDialog> {
  late final _name = TextEditingController(text: widget.vehicle?.name);
  final _search = TextEditingController();
  late final _year =
      TextEditingController(text: widget.vehicle?.year?.toString());
  late final _power =
      TextEditingController(text: widget.vehicle?.powerPs?.toString());

  /// Das bereits zugeordnete Modell steht in der Auswahl, ohne dass man
  /// erst danach suchen muss -- sonst verloere ein Konto es beim
  /// Aendern des Namens.
  late List<VehicleModel> _models = [
    if (widget.vehicle?.model != null) widget.vehicle!.model!,
  ];
  late VehicleModel? _chosen = widget.vehicle?.model;
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
    final repo = ref.read(vehicleRepositoryProvider);
    final existing = widget.vehicle;
    try {
      if (existing == null) {
        await repo.create(
          name: _name.text.trim(),
          vehicleModelId: _chosen?.id,
          year: int.tryParse(_year.text),
          powerPs: int.tryParse(_power.text),
        );
      } else {
        await repo.update(
          existing.id,
          name: _name.text.trim(),
          vehicleModelId: _chosen?.id,
          year: int.tryParse(_year.text),
          powerPs: int.tryParse(_power.text),
        );
      }
      ref.invalidate(vehiclesProvider);
      navigator.pop();
      messenger.showSnackBar(SnackBar(
        content: Text(existing == null ? l.garageSaved : l.garageSavedEdit),
      ));
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
      title: Text(widget.vehicle == null ? l.garageAdd : l.garageEdit),
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
