import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:speedster/heat/heat_map.dart';
import 'package:speedster/heat/heat_palette.dart';

/// Zeichnet alle Heatmap-Kanten mit echtem Weichzeichner-Schein statt
/// dreier harter `PolylineLayer`-Striche.
///
/// `PolylineLayer` kann keine weichen Kanten zeichnen. Diese Ebene malt
/// stattdessen selbst auf einen Canvas: einen breiten Schein-Durchgang und
/// einen schmalen, scharfen Kern-Durchgang, beide additiv
/// (`BlendMode.plus`) innerhalb eines `saveLayer`. So addieren sich
/// ueberlappende Strecken von selbst Richtung Weiss -- Kreuzungen brennen
/// aus, ohne dass das berechnet werden muesste. Der aeussere `saveLayer`
/// ist noetig, damit sich die additive Mischung nur zwischen den
/// Durchgaengen abspielt und nicht gegen die Kartenkacheln darunter.
///
/// Der Weichzeichner laeuft **einmal ueber die gesamte Schein-Ebene**, per
/// `ImageFilter.blur` auf deren `saveLayer` -- nicht als `MaskFilter` je
/// Strich. Das war die urspruengliche Fassung und der Grund, weshalb sich
/// die Karte nicht fluessig bedienen liess: ein `MaskFilter` zwingt Skia,
/// jeden einzelnen Strich in einen eigenen Zwischenspeicher zu zeichnen
/// und zu verwischen. Bei mehreren tausend Kanten sind das ebenso viele
/// Durchgaenge -- in jedem Bild, und waehrend des Verschiebens rechnet die
/// Ebene bei jedem Bild neu.
///
/// Die additive Ueberlagerung bleibt dabei erhalten: sie geschieht
/// innerhalb der Ebene zwischen den Strichen, der Weichzeichner wirkt erst
/// auf das fertig zusammengesetzte Ergebnis. Verwischte Haeufungen sehen
/// dadurch sogar zusammenhaengender aus als einzeln verwischte Striche.
class HeatGlowLayer extends StatefulWidget {
  const HeatGlowLayer({super.key, required this.edges, required this.maxCount});

  final List<HeatEdgeView> edges;
  final int maxCount;

  @override
  State<HeatGlowLayer> createState() => _HeatGlowLayerState();
}

class _HeatGlowLayerState extends State<HeatGlowLayer> {
  /// Der Painter wird bei jeder Kamerabewegung neu erzeugt; der
  /// Zwischenspeicher muss das ueberdauern und haengt deshalb hier.
  final _cache = _CacheSlot();

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    return MobileLayerTransformer(
      child: CustomPaint(
        painter: _HeatGlowPainter(
          edges: widget.edges,
          maxCount: widget.maxCount,
          camera: camera,
          cache: _cache,
        ),
        size: camera.size,
      ),
    );
  }
}

/// Haelt den Projektions-Zwischenspeicher ueber Painter-Wechsel hinweg.
class _CacheSlot {
  _ProjectionCache? value;
}

class _ProjectedEdge {
  const _ProjectedEdge(this.a, this.b, this.style);

  final Offset a;
  final Offset b;
  final HeatStyle style;
}

/// Absolute Pixelpositionen der Kanten auf einer festen Zoomstufe.
///
/// Beim Verschieben der Karte aendert sich die Zoomstufe nicht -- die
/// Projektion jedes Punktes bleibt also gleich und unterscheidet sich von
/// Bild zu Bild nur um den Kamera-Ursprung. Ohne diesen Zwischenspeicher
/// rechnete jede Kante in jedem Bild zwei Mercator-Projektionen neu; bei
/// mehreren tausend Kanten ist das der zweitgroesste Posten nach dem
/// Weichzeichner.
class _ProjectionCache {
  _ProjectionCache(
    this.edges,
    this.zoom,
    this.maxCount,
    this.points,
    this.styles,
  );

  final List<HeatEdgeView> edges;
  final double zoom;

  /// Teil des Schluessels, weil die Farben davon abhaengen: eine neue
  /// Abfrage kann dieselbe Kantenliste mit anderem Maximum liefern.
  final int maxCount;

  /// Zwei Eintraege je Kante: Anfang und Ende.
  final List<Offset> points;
  final List<HeatStyle> styles;

  bool matches(List<HeatEdgeView> other, double otherZoom, int otherMax) =>
      identical(edges, other) && zoom == otherZoom && maxCount == otherMax;

  static _ProjectionCache build(
    List<HeatEdgeView> edges,
    MapCamera camera,
    int maxCount,
  ) {
    final points = <Offset>[];
    final styles = <HeatStyle>[];
    for (final e in edges) {
      points.add(camera.projectAtZoom(LatLng(e.aLat, e.aLng)));
      points.add(camera.projectAtZoom(LatLng(e.bLat, e.bLng)));
      styles.add(HeatPalette.styleFor(e.count, maxCount));
    }

    return _ProjectionCache(edges, camera.zoom, maxCount, points, styles);
  }
}

/// Wie weit eine Kante ueber ihre geometrische Strecke hinaus sichtbar
/// bleibt: der halbe breiteste Strich plus die Weichzeichnung.
///
/// Reine Funktion, eigens fuer die Sichtbarkeitspruefung -- ein
/// weichgezeichneter Strich blutet sichtbar ueber seine geometrischen
/// Grenzen hinaus, also darf die Kulisse nicht am rohen Streckenrechteck
/// abschneiden, sonst reisst der Schein am Bildschirmrand hart ab.
/// `glow` ist immer breiter und staerker weichgezeichnet als `core`
/// (siehe `HeatPalette.styleFor`), deshalb reicht es, sie zu betrachten.
/// Der Faktor 3 auf `blurSigma` ist eine grobe, bewusst grosszuegige
/// Naeherung an die sichtbare Reichweite eines Gauss-Weichzeichners.
double heatCullMargin(HeatStyle style) =>
    style.glow.strokeWidth / 2 + style.glow.blurSigma * 3;

/// Prueft, ob die Bounding-Box einer bereits projizierten Strecke (samt
/// [margin]) den sichtbaren Ausschnitt [viewport] ueberlappt.
///
/// Reine Funktion, arbeitet ausschliesslich auf den uebergebenen Offsets --
/// keine Neuprojektion, kein Kamerazugriff. Damit einzeln testbar und im
/// Malvorgang billig: nur Min/Max und ein Rechteckvergleich pro Kante.
bool heatSegmentOverlapsViewport({
  required Offset a,
  required Offset b,
  required Size viewport,
  required double margin,
}) {
  final left = math.min(a.dx, b.dx) - margin;
  final right = math.max(a.dx, b.dx) + margin;
  final top = math.min(a.dy, b.dy) - margin;
  final bottom = math.max(a.dy, b.dy) + margin;

  return right >= 0 &&
      left <= viewport.width &&
      bottom >= 0 &&
      top <= viewport.height;
}

class _HeatGlowPainter extends CustomPainter {
  _HeatGlowPainter({
    required this.edges,
    required this.maxCount,
    required this.camera,
    required this.cache,
  });

  final List<HeatEdgeView> edges;
  final int maxCount;
  final MapCamera camera;
  final _CacheSlot cache;

  _ProjectionCache _cacheFor(List<HeatEdgeView> edges, MapCamera camera) {
    final cached = cache.value;
    if (cached != null && cached.matches(edges, camera.zoom, maxCount)) {
      return cached;
    }

    return cache.value = _ProjectionCache.build(edges, camera, maxCount);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (edges.isEmpty) return;

    // PolylineLayer culled Segmente ausserhalb des Ausschnitts; das ging
    // beim Ersatz durch diese Ebene verloren, weil hier jede Kante
    // bedingungslos gezeichnet wurde. Besonders die allererste Abfrage
    // (HeatQuery(level: 1), noch ohne bounds, bevor das erste Kamera-Event
    // feuert) liefert sonst jede gespeicherte Kante im ganzen Zeitraum.
    final cache = _cacheFor(edges, camera);
    final origin = camera.pixelOrigin;

    final projected = <_ProjectedEdge>[];
    for (var i = 0; i < cache.styles.length; i++) {
      final a = cache.points[i * 2] - origin;
      final b = cache.points[i * 2 + 1] - origin;
      final style = cache.styles[i];
      if (!heatSegmentOverlapsViewport(
        a: a,
        b: b,
        viewport: size,
        margin: heatCullMargin(style),
      )) {
        continue;
      }
      projected.add(_ProjectedEdge(a, b, style));
    }
    if (projected.isEmpty) return;

    final viewport = Offset.zero & size;
    // Aeusserer saveLayer, damit BlendMode.plus zwischen den Durchgaengen
    // wirkt statt gegen die Kartenkacheln unter dieser Ebene.
    canvas.saveLayer(viewport, Paint());

    // Innerer saveLayer traegt den Weichzeichner fuer die gesamte
    // Schein-Ebene. Die Flaeche ist um die Reichweite des Weichzeichners
    // vergroessert, sonst schnitte er am Rand des Ausschnitts hart ab.
    final bleed = HeatPalette.glowBlurSigma * 3;
    canvas.saveLayer(
      viewport.inflate(bleed),
      Paint()
        ..imageFilter = ui.ImageFilter.blur(
          sigmaX: HeatPalette.glowBlurSigma,
          sigmaY: HeatPalette.glowBlurSigma,
        ),
    );
    for (final edge in projected) {
      _drawLayer(canvas, edge.a, edge.b, edge.style.glow);
    }
    canvas.restore();

    for (final edge in projected) {
      _drawLayer(canvas, edge.a, edge.b, edge.style.core);
    }

    canvas.restore();
  }

  void _drawLayer(Canvas canvas, Offset a, Offset b, HeatLayer layer) {
    // Bewusst ohne MaskFilter: die Weichzeichnung besorgt der umgebende
    // saveLayer einmal fuer alle Striche. Ein MaskFilter hier waere ein
    // eigener Offscreen-Durchgang je Strich.
    final paint = Paint()
      ..color = layer.color
      ..strokeWidth = layer.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..blendMode = BlendMode.plus;
    canvas.drawLine(a, b, paint);
  }

  @override
  bool shouldRepaint(covariant _HeatGlowPainter oldDelegate) =>
      edges != oldDelegate.edges ||
      maxCount != oldDelegate.maxCount ||
      camera != oldDelegate.camera;
}
