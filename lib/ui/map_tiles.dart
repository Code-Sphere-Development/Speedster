import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// OpenStreetMap-Kacheln, in beiden Helligkeiten unveraendert.
///
/// Eine fruehere Fassung dunkelte die Kacheln im Dunkelmodus per Farbfilter
/// ab. Das Ergebnis wirkte fahl, deshalb bleibt die Karte jetzt so, wie OSM
/// sie ausliefert.
class OsmTileLayer extends StatelessWidget {
  const OsmTileLayer({super.key});

  @override
  Widget build(BuildContext context) => TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'de.mediacologne.speedster',
      );
}

/// Quellenangabe zu den Kacheln.
///
/// Die Nutzungsrichtlinie von OpenStreetMap verlangt sie; bisher fehlte sie
/// auf beiden Karten. Bewusst nicht `SimpleAttributionWidget`: das stellt
/// "flutter_map |" voran, was Nutzer nichts angeht.
class OsmAttribution extends StatelessWidget {
  const OsmAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Text(
              '© OpenStreetMap',
              style: TextStyle(fontSize: 10, color: scheme.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}
