import 'package:flutter/material.dart';
import 'package:speedster/ui/components/gradient_header.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/domain/track_point.dart';
import 'package:speedster/domain/trip.dart';
import 'package:speedster/app/spacing.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';
import 'package:speedster/ui/components/card_section.dart';
import 'package:speedster/ui/components/empty_state.dart';
import 'package:speedster/ui/components/metric_value.dart';
import 'package:speedster/settings/settings_controller.dart';
import 'package:speedster/settings/unit_system.dart';
import 'package:speedster/ui/formatters.dart';
import 'package:speedster/ui/map_tiles.dart';

/// Schluessel der Punkte-Abfrage: die stabile `client_uuid` und, sofern
/// die Fahrt lokal vorliegt, ihre Zeilen-Id. Ein Record, weil Riverpod-
/// Families Wertgleichheit brauchen -- [Trip] hat keine.
typedef TripPointsKey = ({String clientUuid, int? localId});

/// Punkte einer Fahrt, aus dem lokalen Vorrat oder aus der Cloud.
final tripPointsProvider =
    FutureProvider.family<List<TrackPoint>, TripPointsKey>((ref, key) {
  return ref.watch(tripSourceProvider).pointsFor(
        clientUuid: key.clientUuid,
        localId: key.localId,
      );
});

class TripDetailScreen extends ConsumerWidget {
  const TripDetailScreen({super.key, required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(settingsControllerProvider).unit;
    final l = AppLocalizations.of(context);
    final pointsAsync = ref.watch(
      tripPointsProvider(
        (clientUuid: trip.clientUuid, localId: trip.id),
      ),
    );

    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: Formatters.dateTime(trip.startTime),
            showBack: true,
          ),
          Expanded(
            child: ListView(
        children: [
          SizedBox(
            height: 280,
            child: pointsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                Center(child: Text(l.tripMapUnavailable(e.toString()))),
              data: (points) => _TripMap(points: points),
            ),
          ),
          _PurposeBlock(trip: trip),
          CardSection(
            title: l.tripMetrics,
            icon: Icons.speed,
            children: [
              for (final (label, measure) in [
                (l.metricMax, SpeedFormat.speedParts(trip.maxSpeed, unit)),
                (l.metricAverage, SpeedFormat.speedParts(trip.avgSpeed, unit)),
                (
                  l.metricDistance,
                  SpeedFormat.distanceParts(trip.distance, unit)
                ),
                (
                  l.metricDuration,
                  (value: Formatters.duration(trip.durationSeconds), unit: '')
                ),
                (
                  l.metricZeroToHundred,
                  Formatters.secondsParts(trip.zeroToHundredSeconds)
                ),
                (l.metricElevation, Formatters.metersParts(trip.elevationGain)),
              ])
                _MetricRow(label: label, measure: measure),
            ],
          ),
        ],
      ),
          ),
        ],
      )
    );
  }
}

class _TripMap extends StatelessWidget {
  const _TripMap({required this.points});

  final List<TrackPoint> points;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    if (points.isEmpty) {
      // Bei aktiver Cloud liegen nur die zuletzt gefahrenen Strecken als
      // Punkte auf dem Geraet (siehe TripCacheService); fuer aeltere
      // Fahrten kommt die Strecke aus dem Netz.
      return EmptyState(icon: Icons.route_outlined, message: l.tripNoRoute);
    }
    final coords = points.map((p) => LatLng(p.lat, p.lng)).toList();
    return FlutterMap(
      options: MapOptions(
        initialCenter: coords.first,
        initialZoom: 14,
        // Wie in der Heatmap. Vorher waren helle OSM-Kacheln mit blauer
        // Linie das einzige Kartenbild der App, das anders aussah -- und
        // Blau kommt sonst nirgends vor.
        backgroundColor: esriDarkBackground,
      ),
      children: [
        const EsriDarkTileLayer(),
        const EsriDarkLabelsTileLayer(),
        const EsriDarkAttribution(),
        PolylineLayer(
          polylines: [
            Polyline(
              points: coords,
              strokeWidth: 4,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ],
    );
  }
}

/// Eine Kennzahl als Zeile: Beschriftung links, Wert rechts.
///
/// Vorher lagen die sechs Werte als Kacheln in einem Raster und nahmen
/// den halben Bildschirm. Als Zeilen in einer Karte stehen sie
/// untereinander auf derselben Kante -- und lassen sich damit vergleichen,
/// was bei Kacheln nebeneinander nicht ging.
class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.measure});

  final String label;
  final Measure measure;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Insets.s),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          MetricValue(
            value: measure.value,
            unit: measure.unit.isEmpty ? null : measure.unit,
            size: 20,
            alignment: CrossAxisAlignment.end,
          ),
        ],
      ),
    );
  }
}


/// Zweck und Notiz einer Fahrt.
///
/// Getrennt vom Fahrzeug, weil beides zu verschiedenen Zeitpunkten
/// feststeht: das Fahrzeug beim Losfahren, der Zweck oft erst danach.
///
/// Gespeichert wird zuerst lokal und dann, sofern die Fahrt schon in der
/// Cloud liegt, auch dort. Scheitert das Zweite, bleibt das Erste
/// bestehen -- ohne Netz soll die Eingabe nicht verlorengehen.
class _PurposeBlock extends ConsumerStatefulWidget {
  const _PurposeBlock({required this.trip});

  final Trip trip;

  @override
  ConsumerState<_PurposeBlock> createState() => _PurposeBlockState();
}

/// Beschriftung eines Zwecks. `null` heisst "kein Zweck" und ist ein
/// gueltiger Wert, kein fehlender.
///
/// Als Funktion und nicht als Konstante: eine Konstante liesse sich nicht
/// uebersetzen, weil sie ohne Kontext ausgewertet wird.
String purposeLabel(AppLocalizations l, String? purpose) => switch (purpose) {
      'private' => l.tripPurposePrivate,
      'commute' => l.tripPurposeCommute,
      'business' => l.tripPurposeBusiness,
      _ => l.tripPurposeNone,
    };

class _PurposeBlockState extends ConsumerState<_PurposeBlock> {
  static const _purposes = ['private', 'commute', 'business'];

  late String? _purpose = widget.trip.purpose;
  late final _note = TextEditingController(text: widget.trip.note);

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();

    await ref
        .read(tripRepositoryProvider)
        .setPurpose(widget.trip.id!, _purpose, note);
    ref.invalidate(keptTripsProvider);

    try {
      await ref
          .read(cloudSyncServiceProvider)
          .updatePurpose(widget.trip.clientUuid, _purpose, note);
    } on Exception {
      // Ohne Netz bleibt es beim lokalen Stand; der naechste Abgleich
      // holt es nach. Ein Fehler hier waere fuer den Nutzer bloss
      // verwirrend -- gespeichert ist gespeichert.
    }

    messenger.showSnackBar(SnackBar(content: Text(l.tripPurposeSaved)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Insets.screen,
        Insets.l,
        Insets.screen,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final value in <String?>[null, ..._purposes])
                ChoiceChip(
                  label: Text(purposeLabel(l, value)),
                  selected: _purpose == value,
                  onSelected: (_) => setState(() => _purpose = value),
                ),
            ],
          ),
          const SizedBox(height: Insets.s),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _note,
                  decoration: InputDecoration(labelText: l.tripNote),
                ),
              ),
              const SizedBox(width: Insets.s),
              FilledButton(onPressed: _save, child: Text(l.commonSave)),
            ],
          ),
        ],
      ),
    );
  }
}
