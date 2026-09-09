import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/domain/track_point.dart';
import 'package:speedster/domain/trip.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';
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
      appBar: AppBar(title: Text(Formatters.dateTime(trip.startTime))),
      body: ListView(
        children: [
          SizedBox(
            height: 260,
            child: pointsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                Center(child: Text(l.tripMapUnavailable(e.toString()))),
              data: (points) => _TripMap(points: points),
            ),
          ),
          _PurposeBlock(trip: trip),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatTile(l.metricMax, SpeedFormat.speed(trip.maxSpeed, unit)),
                _StatTile(l.metricAverage, SpeedFormat.speed(trip.avgSpeed, unit)),
                _StatTile(
                    l.metricDistance, SpeedFormat.distance(trip.distance, unit)),
                _StatTile(
                    l.metricDuration, Formatters.duration(trip.durationSeconds)),
                _StatTile(l.metricZeroToHundred,
                    Formatters.seconds(trip.zeroToHundredSeconds)),
                _StatTile(
                    l.metricElevation, Formatters.meters(trip.elevationGain)),
              ],
            ),
          ),
        ],
      ),
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            l.tripNoRoute,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final coords = points.map((p) => LatLng(p.lat, p.lng)).toList();
    return FlutterMap(
      options: MapOptions(
        initialCenter: coords.first,
        initialZoom: 14,
      ),
      children: [
                  const OsmTileLayer(),
                  const OsmAttribution(),
        PolylineLayer(
          polylines: [
            Polyline(points: coords, strokeWidth: 4, color: Colors.blue),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
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

class _PurposeBlockState extends ConsumerState<_PurposeBlock> {
  static const _purposes = ['private', 'commute', 'business'];

  late String? _purpose = widget.trip.purpose;
  late final _note = TextEditingController(text: widget.trip.note);

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  String _label(AppLocalizations l, String? purpose) => switch (purpose) {
        'private' => l.tripPurposePrivate,
        'commute' => l.tripPurposeCommute,
        'business' => l.tripPurposeBusiness,
        _ => l.tripPurposeNone,
      };

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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final value in <String?>[null, ..._purposes])
                ChoiceChip(
                  label: Text(_label(l, value)),
                  selected: _purpose == value,
                  onSelected: (_) => setState(() => _purpose = value),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _note,
                  decoration: InputDecoration(labelText: l.tripNote),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _save, child: Text(l.commonSave)),
            ],
          ),
        ],
      ),
    );
  }
}
