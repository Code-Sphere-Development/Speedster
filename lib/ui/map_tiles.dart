import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// OpenStreetMap-Kacheln, im Dunkelmodus abgedunkelt.
///
/// OSM liefert ausschliesslich helle Kacheln. Ungefiltert waere die Karte im
/// Dunkelmodus eine grosse leuchtende Flaeche — auf dem Start-Screen der App
/// besonders stoerend. Der Filter invertiert die Luminanz; die Kacheln werden
/// dunkel und die roten Heatmap-Linien heben sich staerker ab.
class OsmTileLayer extends StatelessWidget {
  const OsmTileLayer({super.key});

  static TileLayer get _tiles => TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'de.mediacologne.speedster',
      );

  /// Luminanz-Inversion: hell wird dunkel, die Saettigung faellt weg.
  static const ColorFilter _darken = ColorFilter.matrix(<double>[
    -0.2126, -0.7152, -0.0722, 0, 255, //
    -0.2126, -0.7152, -0.0722, 0, 255, //
    -0.2126, -0.7152, -0.0722, 0, 255, //
    0, 0, 0, 1, 0, //
  ]);

  /// Kennzeichnet die Filterebene, damit Tests sie von den internen
  /// Farbfiltern von FlutterMap unterscheiden koennen.
  static const Key darkFilterKey = ValueKey('osm-dark-filter');

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).brightness != Brightness.dark) return _tiles;
    return ColorFiltered(
      key: darkFilterKey,
      colorFilter: _darken,
      child: _tiles,
    );
  }
}
