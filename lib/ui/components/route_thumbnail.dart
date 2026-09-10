import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:speedster/app/spacing.dart';
import 'package:speedster/domain/route_preview.dart';

/// Das Streckenbild einer Fahrt, klein neben ihren Kennzahlen.
///
/// Bewusst ein [CustomPainter] und nicht `HeatThumbnail`: jenes rendert
/// ein PNG fuer die Homescreen-Widgets und ist deshalb asynchron -- in
/// einer scrollenden Liste hiesse das, dass jede Zeile erst leer erscheint
/// und dann nachspringt. Uebernommen ist nur die Rechnung: gleichmaessige
/// Skalierung auf die laengere Achse, Laengengrad um den Kosinus der
/// Breite gestaucht.
///
/// Ohne Strecke steht hier ein ruhiger Platzhalter. Das trifft Fahrten,
/// die auf einem anderen Geraet aufgezeichnet und nur aus der Cloud
/// geladen wurden -- eine leere Flaeche saehe dort aus wie ein Ladefehler.
class RouteThumbnail extends StatelessWidget {
  const RouteThumbnail({required this.encoded, this.size = 64, super.key});

  final String? encoded;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final points = RoutePreview.decode(encoded);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        // Eine Stufe unter der Karte darum, damit sich das Feld abhebt,
        // ohne einen Rahmen zu brauchen.
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(Radii.small),
      ),
      child: points.length < 2
          ? Icon(
              Icons.route_outlined,
              size: size * 0.4,
              color: scheme.outlineVariant,
            )
          : CustomPaint(
              painter: _RoutePainter(
                points: points,
                color: scheme.primary,
              ),
            ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter({required this.points, required this.color});

  final List<LatLng> points;
  final Color color;

  /// Damit die Strecke am Rand nicht abgeschnitten wird.
  static const double _margin = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = _bounds(points);
    final path = Path();

    for (var i = 0; i < points.length; i++) {
      final o = _project(points[i], bounds, size);
      if (i == 0) {
        path.moveTo(o.dx, o.dy);
      } else {
        path.lineTo(o.dx, o.dy);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  static ({double minLat, double maxLat, double minLng, double maxLng}) _bounds(
    List<LatLng> points,
  ) {
    var minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;
    for (final p in points) {
      minLat = math.min(minLat, p.lat);
      maxLat = math.max(maxLat, p.lat);
      minLng = math.min(minLng, p.lng);
      maxLng = math.max(maxLng, p.lng);
    }

    return (minLat: minLat, maxLat: maxLat, minLng: minLng, maxLng: maxLng);
  }

  static Offset _project(
    LatLng point,
    ({double minLat, double maxLat, double minLng, double maxLng}) b,
    Size size,
  ) {
    final cos = math.cos((b.minLat + b.maxLat) / 2 * math.pi / 180).abs();
    // Untergrenzen, damit eine Fahrt auf gerader Strecke nicht durch Null
    // teilt: Nord-Sued gefahren ist die Breite der Umschliessenden null.
    final width = math.max((b.maxLng - b.minLng) * cos, 1e-9);
    final height = math.max(b.maxLat - b.minLat, 1e-9);
    final usable = math.max(math.min(size.width, size.height) - _margin * 2, 1);
    final scale = math.min(usable / width, usable / height);

    final x = (point.lng - b.minLng) * cos * scale;
    final y = (b.maxLat - point.lat) * scale;

    return Offset(
      _margin + x + (usable - width * scale) / 2,
      _margin + y + (usable - height * scale) / 2,
    );
  }

  @override
  bool shouldRepaint(_RoutePainter old) =>
      old.color != color || !identical(old.points, points);
}
