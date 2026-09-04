import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
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
  static const _initialZoom = 12.0;

  HeatQuery _query = const HeatQuery(level: 1);
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
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

    return Scaffold(
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Heatmap nicht verfügbar: $e')),
        data: (map) {
          if (map.edges.isEmpty) {
            return const Center(
              child: Text('Noch keine Strecken aufgezeichnet'),
            );
          }
          return Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter:
                      LatLng(map.edges.first.aLat, map.edges.first.aLng),
                  initialZoom: _initialZoom,
                  onMapEvent: (e) => _onCameraChanged(e.camera),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'de.mediacologne.speedster',
                  ),
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
            ],
          );
        },
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
