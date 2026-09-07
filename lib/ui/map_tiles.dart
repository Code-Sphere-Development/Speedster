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
  Widget build(BuildContext context) => const _TileAttribution(
        text: '© OpenStreetMap',
      );
}

/// Dunkle Kacheln fuer die Heatmap.
///
/// Auf hellen OSM-Kacheln liest sich die niedrige Intensitaet der Rampe
/// (dunkler Wein) wie ein dunkles Gekritzel -- der Look ist untrennbar von
/// einer dunklen Basiskarte. Esri liefert eine passende dunkle Basiskarte
/// ohne API-Schluessel.
///
/// Wichtig: Esri erwartet die Platzhalter in der Reihenfolge `{z}/{y}/{x}`,
/// anders als OSMs `{z}/{x}/{y}`.
class EsriDarkTileLayer extends StatelessWidget {
  const EsriDarkTileLayer({super.key});

  static const _base =
      'https://services.arcgisonline.com/ArcGIS/rest/services/Canvas/'
      'World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}';

  @override
  Widget build(BuildContext context) => TileLayer(
        urlTemplate: _base,
        userAgentPackageName: 'de.mediacologne.speedster',
      );
}

/// Beschriftungen (Orte, Strassen) als eigene Ebene ueber [EsriDarkTileLayer].
///
/// Esri liefert die Dark-Gray-Canvas-Basiskarte und ihre Beschriftungen als
/// zwei getrennte Kachelquellen; beide werden uebereinander gezeichnet.
class EsriDarkLabelsTileLayer extends StatelessWidget {
  const EsriDarkLabelsTileLayer({super.key});

  static const _labels =
      'https://services.arcgisonline.com/ArcGIS/rest/services/Canvas/'
      'World_Dark_Gray_Reference/MapServer/tile/{z}/{y}/{x}';

  @override
  Widget build(BuildContext context) => TileLayer(
        urlTemplate: _labels,
        userAgentPackageName: 'de.mediacologne.speedster',
      );
}

/// Quellenangabe zu den dunklen Esri-Kacheln.
///
/// Von Esri fuer die Dark-Gray-Canvas-Basiskarte vorgeschrieben.
class EsriDarkAttribution extends StatelessWidget {
  const EsriDarkAttribution({super.key});

  @override
  Widget build(BuildContext context) => const _TileAttribution(
        text: '© Esri, HERE, Garmin, © OpenStreetMap-Mitwirkende',
      );
}

/// Gemeinsame Darstellung fuer Kachel-Quellenangaben.
class _TileAttribution extends StatelessWidget {
  const _TileAttribution({required this.text});

  final String text;

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
              text,
              style: TextStyle(fontSize: 10, color: scheme.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}
