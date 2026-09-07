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
/// stattdessen selbst auf einen Canvas: einen breiten, stark
/// weichgezeichneten Schein-Durchgang und einen schmalen, kaum
/// weichgezeichneten Kern-Durchgang, beide additiv (`BlendMode.plus`)
/// innerhalb eines `saveLayer`. So addieren sich ueberlappende Strecken von
/// selbst Richtung Weiss -- Kreuzungen brennen aus, ohne dass das berechnet
/// werden muesste. Der `saveLayer` ist noetig, damit sich die additive
/// Mischung nur zwischen den beiden Durchgaengen abspielt und nicht gegen
/// die Kartenkacheln darunter.
class HeatGlowLayer extends StatelessWidget {
  const HeatGlowLayer({super.key, required this.edges, required this.maxCount});

  final List<HeatEdgeView> edges;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    return MobileLayerTransformer(
      child: CustomPaint(
        painter: _HeatGlowPainter(
          edges: edges,
          maxCount: maxCount,
          camera: camera,
        ),
        size: camera.size,
      ),
    );
  }
}

class _ProjectedEdge {
  const _ProjectedEdge(this.a, this.b, this.style);

  final Offset a;
  final Offset b;
  final HeatStyle style;
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
  });

  final List<HeatEdgeView> edges;
  final int maxCount;
  final MapCamera camera;

  @override
  void paint(Canvas canvas, Size size) {
    if (edges.isEmpty) return;

    // PolylineLayer culled Segmente ausserhalb des Ausschnitts; das ging
    // beim Ersatz durch diese Ebene verloren, weil hier jede Kante
    // bedingungslos gezeichnet wurde. Besonders die allererste Abfrage
    // (HeatQuery(level: 1), noch ohne bounds, bevor das erste Kamera-Event
    // feuert) liefert sonst jede gespeicherte Kante im ganzen Zeitraum.
    final projected = <_ProjectedEdge>[];
    for (final e in edges) {
      final a = camera.getOffsetFromOrigin(LatLng(e.aLat, e.aLng));
      final b = camera.getOffsetFromOrigin(LatLng(e.bLat, e.bLng));
      final style = HeatPalette.styleFor(e.count, maxCount);
      final margin = heatCullMargin(style);
      if (!heatSegmentOverlapsViewport(
        a: a,
        b: b,
        viewport: size,
        margin: margin,
      )) {
        continue;
      }
      projected.add(_ProjectedEdge(a, b, style));
    }
    if (projected.isEmpty) return;

    final viewport = Offset.zero & size;
    // Ein saveLayer, damit BlendMode.plus zwischen den beiden Durchgaengen
    // wirkt statt gegen die Kartenkacheln unter dieser Ebene.
    canvas.saveLayer(viewport, Paint());

    for (final edge in projected) {
      _drawLayer(canvas, edge.a, edge.b, edge.style.glow);
    }
    for (final edge in projected) {
      _drawLayer(canvas, edge.a, edge.b, edge.style.core);
    }

    canvas.restore();
  }

  void _drawLayer(Canvas canvas, Offset a, Offset b, HeatLayer layer) {
    final paint = Paint()
      ..color = layer.color
      ..strokeWidth = layer.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..blendMode = BlendMode.plus;
    if (layer.blurSigma > 0) {
      paint.maskFilter =
          ui.MaskFilter.blur(ui.BlurStyle.normal, layer.blurSigma);
    }
    canvas.drawLine(a, b, paint);
  }

  @override
  bool shouldRepaint(covariant _HeatGlowPainter oldDelegate) =>
      edges != oldDelegate.edges ||
      maxCount != oldDelegate.maxCount ||
      camera != oldDelegate.camera;
}
