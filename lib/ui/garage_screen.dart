import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/cloud/vehicle_repository.dart';
import 'package:speedster/app/spacing.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';
import 'package:speedster/ui/components/empty_state.dart';
import 'package:speedster/ui/components/metric_value.dart';
import 'package:speedster/ui/components/card_section.dart';

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
          ? EmptyState(icon: Icons.cloud_off, message: l.garageNeedsCloud)
          : vehicles.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline,
                message: l.commonError(e.toString()),
              ),
              data: (list) => list.isEmpty
                  ? EmptyState(
                      icon: Icons.garage_outlined,
                      message: l.garageEmpty,
                    )
                  : ListView(
                      // Kein Wert aus dem Raster: die Zahl richtet sich
                      // nach der Hoehe des schwebenden Knopfes, damit er
                      // die letzte Kachel nicht verdeckt.
                      padding: const EdgeInsets.only(
                        top: Insets.s,
                        bottom: 88,
                      ),
                      children: [
                        // Keine Seitenueberschrift mehr: die traegt der
                        // Kopfbereich der App.
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            Insets.screen,
                            Insets.s,
                            Insets.screen,
                            Insets.s,
                          ),
                          child: Text(
                            l.garageLead,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
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
      // Die Einheit ist nicht ueberall dieselbe: PS im Deutschen, hp im
      // Englischen.
      if (vehicle.powerPs != null) '${vehicle.powerPs} ${l.garagePowerUnit}',
      if (vehicle.model?.vehicleClass != null) vehicle.model!.vehicleClass!,
      if (vehicle.model?.fuel != null) vehicle.model!.fuel!,
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Der Name steht ueber den Karten und nicht darin: er ist der
        // Gegenstand, nicht die Ueberschrift eines Abschnitts.
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Insets.screen,
            Insets.s,
            Insets.s,
            Insets.s,
          ),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  vehicle.name,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (vehicle.isDefault) ...[
                const SizedBox(width: Insets.s),
                _DefaultBadge(label: l.garageDefault),
              ],
              const Spacer(),
              // Ein Klappmenue statt dreier Schaltflaechen. Vorher
              // standen "Bearbeiten", "Zum Standard machen" und
              // "Loeschen" als rote Beschriftungen in der Kachel -- alle
              // drei gleich auffaellig, obwohl nur eine davon etwas
              // zerstoert.
              _VehicleMenu(
                vehicle: vehicle,
                onEdit: onEdit,
                onDelete: onDelete,
                onMakeDefault: () async {
                  await ref
                      .read(vehicleRepositoryProvider)
                      .makeDefault(vehicle.id);
                  ref.invalidate(vehiclesProvider);
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Insets.screen,
            0,
            Insets.screen,
            Insets.m,
          ),
          child: Text(
            details,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ),
        _OdometerBlock(vehicle: vehicle),
        _MaintenanceBlock(vehicle: vehicle),
        const SizedBox(height: Insets.s),
      ],
    );
  }
}

/// Die Pille am Standardfahrzeug.
class _DefaultBadge extends StatelessWidget {
  const _DefaultBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Insets.s, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Text(
        label,
        // Flaeche und Schrift aus demselben Paar -- sonst steht die
        // Beschriftung auf eigener Farbe.
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

/// Alles, was man mit einem Fahrzeug tun kann, an einer Stelle.
class _VehicleMenu extends StatelessWidget {
  const _VehicleMenu({
    required this.vehicle,
    required this.onEdit,
    required this.onDelete,
    required this.onMakeDefault,
  });

  final Vehicle vehicle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onMakeDefault;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return PopupMenuButton<VoidCallback>(
      icon: const Icon(Icons.more_vert),
      tooltip: l.garageEdit,
      position: PopupMenuPosition.under,
      onSelected: (action) => action(),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: onEdit,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.edit_outlined),
            title: Text(l.garageEdit),
          ),
        ),
        if (!vehicle.isDefault)
          PopupMenuItem(
            value: onMakeDefault,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.star_outline),
              title: Text(l.garageMakeDefault),
            ),
          ),
        PopupMenuItem(
          value: onDelete,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            // Zerstoerendes traegt die Fehlerfarbe, nicht den Akzent:
            // vorher sah "Loeschen" genauso aus wie "Erledigt".
            iconColor: scheme.error,
            textColor: scheme.error,
            leading: const Icon(Icons.delete_outline),
            title: Text(l.garageDelete),
          ),
        ),
      ],
    );
  }
}

/// Kilometerzahlen mit Tausendertrennung der jeweiligen Sprache.
///
/// Ohne sie steht dort "128430 km", und das liest niemand auf einen
/// Blick. Die Cloud macht es genauso.
String _km(BuildContext context, num value) => NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(value);

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

    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return CardSection(
      title: l.garageOdometer,
      icon: Icons.speed,
      // Ein Plus statt einer roten Beschriftung: die Aktion gehoert zur
      // Ueberschrift des Abschnitts, nicht in die Datenzeile.
      trailing: _AddButton(
        tooltip: l.garageOdometerAdd,
        onPressed: () => _add(context, ref),
      ),
      children: [
        // Wert und Grundlage sind ein Kind und nicht zwei: zwischen
        // ihnen gehoert keine Trennlinie, sie gehoeren zusammen.
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (odometer.estimateKm == null)
              Text(l.garageOdometerNone, style: small?.copyWith(color: muted))
            else
              MetricValue(
                value: _km(context, odometer.estimateKm!),
                unit: 'km',
                // Ohne Beschriftung: dass die Zahl geschaetzt ist, sagt
                // die Grundlagenzeile darunter -- dreimal dasselbe Wort
                // untereinander liest niemand.
                label:
                    odometer.readingKm == null ? l.garageOdometerApprox : null,
              ),
            if (odometer.readingKm != null && odometer.readAt != null)
              Padding(
                padding: const EdgeInsets.only(top: Insets.xs),
                child: Text(
                  l.garageOdometerBasis(
                    _km(context, odometer.readingKm!),
                    DateFormat.yMd(
                      Localizations.localeOf(context).toLanguageTag(),
                    ).format(odometer.readAt!),
                    _km(context, odometer.trackedKm.round()),
                  ),
                  style: small?.copyWith(color: muted),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Das Plus in der Ueberschrift eines Abschnitts.
///
/// Eigene Klasse, weil ein gewoehnlicher IconButton mit seinen 48 Pixeln
/// die Kopfzeile der Karte auseinanderzoege.
class _AddButton extends StatelessWidget {
  const _AddButton({required this.tooltip, required this.onPressed});

  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
        icon: const Icon(Icons.add, size: 20),
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 28, height: 28),
      );
}

/// Faellige Wartungen, nach Termin oder Laufleistung.
class _MaintenanceBlock extends ConsumerWidget {
  const _MaintenanceBlock({required this.vehicle});

  final Vehicle vehicle;

  /// Wie weit es noch ist -- in Tagen, in Kilometern oder in beidem.
  ///
  /// Ohne geschaetzten Tachostand bleibt die Kilometerangabe aus: eine
  /// Restangabe ohne Bezugsgroesse waere keine Auskunft.
  String _due(BuildContext context, AppLocalizations l, MaintenanceItem item) {
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
          ? l.garageMaintenanceInKm(_km(context, km))
          : l.garageMaintenanceOverdueKm(_km(context, -km)));
    } else if (item.dueKm != null) {
      parts.add(l.garageMaintenanceKmUnknown(_km(context, item.dueKm!)));
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

    final muted = scheme.onSurfaceVariant;

    return CardSection(
      title: l.garageMaintenance,
      icon: Icons.build_outlined,
      trailing: _AddButton(
        tooltip: l.garageMaintenanceAdd,
        onPressed: () => _add(context, ref),
      ),
      children: [
        if (vehicle.maintenance.isEmpty)
          Text(l.garageMaintenanceNone, style: small?.copyWith(color: muted))
        else
          for (final item in vehicle.maintenance)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Insets.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ein Punkt statt eingefaerbter Schrift: die Farbe
                  // steht damit vor der Zeile und nicht in ihr, und
                  // ueberfaellige Eintraege sind beim Ueberfliegen zu
                  // erkennen, ohne dass man den Titel lesen muss.
                  Padding(
                    padding: const EdgeInsets.only(top: 7, right: Insets.s),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: item.overdue
                            ? scheme.primary
                            : scheme.outlineVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          _due(context, l, item),
                          style: small?.copyWith(
                            color: item.overdue ? scheme.primary : muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<bool>(
                    icon: const Icon(Icons.more_horiz),
                    tooltip: l.garageEdit,
                    position: PopupMenuPosition.under,
                    onSelected: (done) async {
                      if (done) {
                        await ref
                            .read(vehicleRepositoryProvider)
                            .completeMaintenance(vehicle.id, item.id);
                        ref.invalidate(vehiclesProvider);
                        return;
                      }

                      final changed = await showDialog<bool>(
                        context: context,
                        builder: (_) => MaintenanceDialog(
                          vehicle: vehicle,
                          item: item,
                        ),
                      );
                      if (changed ?? false) ref.invalidate(vehiclesProvider);
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: true,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.check),
                          title: Text(l.garageMaintenanceDone),
                        ),
                      ),
                      PopupMenuItem(
                        value: false,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.edit_outlined),
                          title: Text(l.garageEdit),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

/// Anlegen und Aendern einer Wartung: Termin, Laufleistung oder beides.
///
/// Die Laufleistung laesst sich auf zwei Wegen angeben -- als Zielstand
/// ("bei 135 000 km", so steht es auf dem Werkstattaufkleber) oder als
/// Restweg ("in 5 000 km", so steht es im Wartungsplan). Umgerechnet wird
/// am Server: hier waere dieselbe Rechnung ein zweites Mal.
class MaintenanceDialog extends ConsumerStatefulWidget {
  const MaintenanceDialog({required this.vehicle, this.item, super.key});

  final Vehicle vehicle;

  /// Gesetzt heisst aendern statt anlegen.
  final MaintenanceItem? item;

  @override
  ConsumerState<MaintenanceDialog> createState() => _MaintenanceDialogState();
}

class _MaintenanceDialogState extends ConsumerState<MaintenanceDialog> {
  late final _title = TextEditingController(text: widget.item?.title);
  late final _km =
      TextEditingController(text: widget.item?.dueKm?.toString());
  late DateTime? _dueOn = widget.item?.dueOn;

  /// true = Restweg ("in x km"), false = Zielstand ("bei x km").
  ///
  /// Beim Aendern immer der Zielstand: gespeichert ist einer, und ihn als
  /// Restweg anzuzeigen hiesse, ihn gegen einen wandernden Bezugspunkt
  /// zurueckzurechnen.
  bool _relative = false;

  String? _error;
  bool _busy = false;

  /// Ohne geschaetzten Tachostand gibt es keinen Bezugspunkt fuer einen
  /// Restweg -- der Server lehnte ihn ab, also wird er hier gar nicht
  /// erst angeboten.
  bool get _canUseRelative => widget.vehicle.odometer.estimateKm != null;

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
    final repo = ref.read(vehicleRepositoryProvider);
    final existing = widget.item;
    try {
      if (existing == null) {
        await repo.addMaintenance(
          widget.vehicle.id,
          title: _title.text.trim(),
          dueOn: _dueOn,
          dueKm: _relative ? null : km,
          dueInKm: _relative ? km : null,
        );
      } else {
        await repo.updateMaintenance(
          widget.vehicle.id,
          existing.id,
          title: _title.text.trim(),
          dueOn: _dueOn,
          dueKm: _relative ? null : km,
          dueInKm: _relative ? km : null,
        );
      }
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
      title: Text(widget.item == null ? l.garageMaintenanceAdd : l.garageEdit),
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
          const SizedBox(height: Insets.m),
          if (_canUseRelative)
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                    value: false, label: Text(l.garageMaintenanceModeAt)),
                ButtonSegment(
                    value: true, label: Text(l.garageMaintenanceModeIn)),
              ],
              selected: {_relative},
              onSelectionChanged: (s) => setState(() => _relative = s.first),
            ),
          TextField(
            controller: _km,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: _relative
                  ? l.garageMaintenanceDueInKm
                  : l.garageMaintenanceDueKm,
              suffixText: 'km',
            ),
          ),
          const SizedBox(height: Insets.m),
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
            const SizedBox(height: Insets.l),
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
            const SizedBox(height: Insets.l),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _year,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l.garageYear),
                  ),
                ),
                const SizedBox(width: Insets.m),
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
