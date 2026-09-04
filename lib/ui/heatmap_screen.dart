import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:speedster/ui/map_tiles.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/heat/heat_map.dart';
import 'package:speedster/heat/heat_palette.dart';

/// Karte aller gefahrenen Strecken, eingefaerbt nach Befahrungshaeufigkeit.
class HeatmapScreen extends ConsumerStatefulWidget {
  const HeatmapScreen({super.key});

  @override
  ConsumerState<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends ConsumerState<HeatmapScreen> {
  /// Zoomstufe, sobald ein konkreter Ort bekannt ist.
  static const _localZoom = 12.0;

  /// Ohne jeden Anhaltspunkt zeigt die Karte lieber eine Uebersicht, als
  /// eine willkuerliche Stadt vorzutaeuschen.
  static const _overviewCenter = LatLng(51.1657, 10.4515);
  static const _overviewZoom = 5.0;

  final MapController _controller = MapController();

  HeatQuery _query = const HeatQuery(level: 1);
  Timer? _debounce;

  /// Die Kamera wird nur einmal automatisch gesetzt; danach gehoert sie dem
  /// Nutzer.
  bool _cameraPlaced = false;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /// Rueckt die Karte einmalig auf die vorhandenen Strecken oder ersatzweise
  /// auf die letzte bekannte Position.
  void _placeCamera(HeatMap map) {
    if (_cameraPlaced) return;

    if (map.edges.isNotEmpty) {
      _cameraPlaced = true;
      final lats = [for (final e in map.edges) ...[e.aLat, e.bLat]];
      final lngs = [for (final e in map.edges) ...[e.aLng, e.bLng]];
      final bounds = LatLngBounds(
        LatLng(lats.reduce(math.min), lngs.reduce(math.min)),
        LatLng(lats.reduce(math.max), lngs.reduce(math.max)),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _controller.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(32)),
        );
      });
      return;
    }

    final fallback = ref.read(mapFallbackCenterProvider).asData?.value;
    if (fallback == null) return; // Uebersicht beibehalten
    _cameraPlaced = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.move(LatLng(fallback.lat, fallback.lng), _localZoom);
    });
  }

  /// Ohne Entprellung loeste jeder Pan-Frame eine neue Abfrage aus.
  void _onCameraChanged(MapCamera camera) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final b = camera.visibleBounds;
      setState(() {
        _query = HeatQuery(
          level: HeatGridZoom.levelForZoom(camera.zoom),
          bounds: HeatBounds(b.south, b.west, b.north, b.east),
          range: _query.range,
        );
      });
    });
  }

  void _setRange(HeatRange range) {
    setState(() => _query = _query.copyWith(range: range));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(heatMapProvider(_query));
    // Sobald die letzte bekannte Position eintrifft, soll die Kamera sie
    // nutzen koennen, falls noch keine Strecken vorliegen.
    ref.watch(mapFallbackCenterProvider);

    final map = async.asData?.value ?? HeatMap.empty;
    _placeCamera(map);

    return Scaffold(
      body: Stack(
            children: [
              FlutterMap(
                mapController: _controller,
                options: MapOptions(
                  initialCenter: _overviewCenter,
                  initialZoom: _overviewZoom,
                  onMapEvent: (e) => _onCameraChanged(e.camera),
                ),
                children: [
                  const OsmTileLayer(),
                  PolylineLayer(
                    polylines: [
                      for (final e in map.edges)
                        Polyline(
                          points: [
                            LatLng(e.aLat, e.aLng),
                            LatLng(e.bLat, e.bLng),
                          ],
                          strokeWidth: 4,
                          color: HeatPalette.colorFor(e.count, map.maxCount),
                        ),
                    ],
                  ),
                ],
              ),
              const Positioned(left: 12, bottom: 12, child: _Legend()),
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Consumer(
                  builder: (context, ref, _) {
                    // Nur die Cloud kennt Monatsbuckets; lokal gibt es
                    // nichts zu filtern.
                    final cloud =
                        ref.watch(cloudActiveProvider).asData?.value ?? false;
                    if (!cloud) return const SizedBox.shrink();
                    return Wrap(
                      spacing: 8,
                      children: [
                        for (final (range, label) in const [
                          (HeatRange.all, 'Alles'),
                          (HeatRange.months12, '12 Monate'),
                          (HeatRange.months3, '3 Monate'),
                        ])
                          ChoiceChip(
                            label: Text(label),
                            selected: _query.range == range,
                            onSelected: (_) => _setRange(range),
                          ),
                      ],
                    );
                  },
                ),
              ),
              if (async.hasError)
                const Positioned(
                  left: 12,
                  right: 12,
                  bottom: 56,
                  child: _Notice('Heatmap nicht verfügbar'),
                )
              else if (async.isLoading)
                const Positioned(
                  left: 12,
                  right: 12,
                  bottom: 56,
                  child: _Notice('Heatmap wird geladen …'),
                )
              else if (map.edges.isEmpty)
                const Positioned(
                  left: 12,
                  right: 12,
                  bottom: 56,
                  child: _Notice('Noch keine Strecken aufgezeichnet'),
                ),
            ],
      ),
    );
  }
}

/// Kurze Statusmeldung ueber der Karte. Bewusst eine Ueberlagerung: die Karte
/// soll auch dann stehen bleiben, wenn es nichts einzuzeichnen gibt.
class _Notice extends StatelessWidget {
  const _Notice(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text, style: TextStyle(color: scheme.onSurface)),
      ),
    );
  }
}

/// Ohne Legende ist die Farbskala nicht interpretierbar.
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('selten'),
          const SizedBox(width: 8),
          Container(
            width: 80,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(
                colors: [for (final s in HeatPalette.stops) s.$2],
                stops: [for (final s in HeatPalette.stops) s.$1],
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text('oft'),
        ],
      ),
    );
  }
}
