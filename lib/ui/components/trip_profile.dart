import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:speedster/app/spacing.dart';
import 'package:speedster/domain/track_point.dart';
import 'package:speedster/settings/unit_system.dart';

/// Tempo- und Hoehenverlauf einer Fahrt.
///
/// Die Punkte tragen Tempo **und** Hoehe je Messung, und die
/// Detailansicht laedt sie ohnehin fuer die Karte. Gezeigt wurden davon
/// bisher zwei gerundete Zahlen -- aus einer Fahrt wird so keine
/// Geschichte. Der Verlauf zeigt, was die Zahlen verschweigen: wo die
/// Autobahn anfing, wo der Stau stand, wo die Ortsdurchfahrt lag.
///
/// Die Zeit traegt die Waagerechte, nicht der Index: die Messungen kommen
/// nicht in gleichmaessigem Takt, und ueber den Index gezeichnet zoege
/// sich eine Standzeit auf dieselbe Breite wie eine Minute Fahrt.
class TripProfile extends StatelessWidget {
  const TripProfile({required this.points, required this.unit, super.key});

  final List<TrackPoint> points;
  final UnitSystem unit;

  /// Unter zwei Punkten gibt es keinen Verlauf, nur einen Punkt.
  static bool worthShowing(List<TrackPoint> points) => points.length >= 2;

  static const double _speedHeight = 96;
  static const double _elevationHeight = 48;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    final caption = theme.textTheme.labelMedium?.copyWith(color: muted);

    final maxSpeed = points.fold<double>(0, (m, p) => math.max(m, p.speed));
    final climb = _range(points.map((p) => p.altitude));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: Insets.xs),
          child: Text(
            SpeedFormat.speed(maxSpeed, unit),
            style: caption,
          ),
        ),
        SizedBox(
          height: _speedHeight,
          child: CustomPaint(
            painter: _ProfilePainter(
              points: points,
              value: (p) => p.speed,
              color: theme.colorScheme.primary,
              filled: true,
              // Tempo wird immer gegen null gemessen: ein Verlauf, dessen
              // Grundlinie beim langsamsten Punkt der Fahrt liegt, machte
              // aus einer Ortsdurchfahrt einen Einbruch.
              baseAtZero: true,
            ),
            size: Size.infinite,
          ),
        ),
        if (climb > 0) ...[
          const SizedBox(height: Insets.m),
          Padding(
            padding: const EdgeInsets.only(bottom: Insets.xs),
            child: Text('Δ ${climb.round()} m', style: caption),
          ),
          SizedBox(
            height: _elevationHeight,
            child: CustomPaint(
              painter: _ProfilePainter(
                points: points,
                value: (p) => p.altitude,
                color: muted,
                filled: false,
                // Hoehe dagegen ist ein Relativwert: gegen null gezeichnet
                // waere jede Fahrt im Flachland eine gerade Linie am
                // oberen Rand.
                baseAtZero: false,
              ),
              size: Size.infinite,
            ),
          ),
        ],
      ],
    );
  }

  static double _range(Iterable<double> values) {
    var min = double.infinity;
    var max = double.negativeInfinity;
    for (final v in values) {
      min = math.min(min, v);
      max = math.max(max, v);
    }
    return max - min;
  }
}

class _ProfilePainter extends CustomPainter {
  const _ProfilePainter({
    required this.points,
    required this.value,
    required this.color,
    required this.filled,
    required this.baseAtZero,
  });

  final List<TrackPoint> points;
  final double Function(TrackPoint) value;
  final Color color;
  final bool filled;
  final bool baseAtZero;

  @override
  void paint(Canvas canvas, Size size) {
    final start = points.first.timestamp.millisecondsSinceEpoch;
    final span = points.last.timestamp.millisecondsSinceEpoch - start;
    // Alle Messungen in derselben Millisekunde: dann gibt es keine
    // Waagerechte, ueber die sich etwas auftragen liesse.
    if (span <= 0) return;

    var min = double.infinity;
    var max = double.negativeInfinity;
    for (final p in points) {
      final v = value(p);
      min = math.min(min, v);
      max = math.max(max, v);
    }
    if (baseAtZero) min = 0;

    // Verhindert eine Division durch null, wenn alle Werte gleich sind --
    // die Linie liegt dann in der Mitte statt am Rand.
    final extent = max - min;
    final scale = extent <= 0 ? 0.0 : 1 / extent;

    Offset at(TrackPoint p) {
      final x =
          (p.timestamp.millisecondsSinceEpoch - start) / span * size.width;
      final y = extent <= 0
          ? size.height / 2
          : size.height - (value(p) - min) * scale * size.height;
      return Offset(x, y);
    }

    final line = Path()..moveTo(at(points.first).dx, at(points.first).dy);
    for (final p in points.skip(1)) {
      final o = at(p);
      line.lineTo(o.dx, o.dy);
    }

    if (filled) {
      final area = Path.from(line)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.28),
              color.withValues(alpha: 0.02),
            ],
          ).createShader(Offset.zero & size),
      );
    }

    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..strokeWidth = filled ? 2 : 1.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_ProfilePainter old) =>
      old.color != color || !identical(old.points, points);
}
