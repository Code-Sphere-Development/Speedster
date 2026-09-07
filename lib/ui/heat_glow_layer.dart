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

    final projected = [
      for (final e in edges)
        _ProjectedEdge(
          camera.getOffsetFromOrigin(LatLng(e.aLat, e.aLng)),
          camera.getOffsetFromOrigin(LatLng(e.bLat, e.bLng)),
          HeatPalette.styleFor(e.count, maxCount),
        ),
    ];

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
