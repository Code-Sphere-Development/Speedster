import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:speedster/app/spacing.dart';
import 'package:speedster/app/theme.dart';
import 'package:speedster/settings/unit_system.dart';

/// Tacho: ein Bogen, der sich mit dem Tempo fuellt.
///
/// Die Zahl allein stand vorher gross in der Mitte des Bildschirms und
/// sagte nichts darueber, wo man sich befindet -- 80 liest sich wie 180,
/// wenn nichts daneben steht. Der Bogen gibt der Zahl einen Rahmen: man
/// sieht auf einen Blick, ob es viel ist.
///
/// Bewusst ohne Nadel. Eine Nadel muesste von Messung zu Messung springen
/// oder animiert nachlaufen; beides lenkt waehrend der Fahrt mehr ab, als
/// es nuetzt. Der Bogen aendert nur seine Laenge.
class SpeedGauge extends StatelessWidget {
  const SpeedGauge({
    required this.speedMps,
    required this.unit,
    this.size = 260,
    super.key,
  });

  final double speedMps;
  final UnitSystem unit;
  final double size;

  /// Der Bogen laeuft ueber 270 Grad, wie an einem Armaturenbrett: unten
  /// bleibt die Luecke, in der bei einem echten Tacho die Achse sitzt.
  static const double _sweep = 270 * math.pi / 180;
  static const double _start = 135 * math.pi / 180;

  /// Ende der Skala. Wird schrittweise groesser, falls jemand darueber
  /// hinauskommt -- ein Bogen, der bei Vollausschlag stehen bleibt,
  /// verschweigt genau den Fall, der interessiert.
  static double scaleFor(double value, UnitSystem unit) {
    final steps = unit == UnitSystem.kmh
        ? const [60.0, 120.0, 200.0, 260.0, 320.0]
        : const [40.0, 80.0, 120.0, 160.0, 200.0];

    for (final step in steps) {
      if (value <= step) return step;
    }

    return steps.last;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final measure = SpeedFormat.speedParts(speedMps, unit);
    final value = double.tryParse(measure.value) ?? 0;
    final scale = scaleFor(value, unit);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GaugePainter(
          fraction: (value / scale).clamp(0.0, 1.0),
          scale: scale,
          track: theme.colorScheme.outlineVariant,
          fill: theme.colorScheme.primary,
          ticks: theme.colorScheme.onSurfaceVariant,
          // Aus dem Textthema und nicht von Hand: eine TextStyle ohne
          // Schriftfamilie faellt auf die Standardschrift zurueck, und die
          // ist nicht ueberall dieselbe.
          labelStyle: theme.textTheme.labelSmall!.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                measure.value,
                style: SpeedsterTheme.metric(context, size: size * 0.28),
              ),
              Text(
                measure.unit,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({
    required this.fraction,
    required this.scale,
    required this.track,
    required this.fill,
    required this.ticks,
    required this.labelStyle,
  });

  final double fraction;
  final double scale;
  final Color track;
  final Color fill;
  final Color ticks;
  final TextStyle labelStyle;

  static const double _stroke = 14;

  /// So viele Abschnitte hat die Skala -- fuenf Striche, vier Felder.
  static const int _tickCount = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (math.min(size.width, size.height) - _stroke) / 2;
    final centre = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: centre, radius: radius);

    canvas.drawArc(
      rect,
      SpeedGauge._start,
      SpeedGauge._sweep,
      false,
      Paint()
        ..color = track
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    if (fraction > 0) {
      canvas.drawArc(
        rect,
        SpeedGauge._start,
        SpeedGauge._sweep * fraction,
        false,
        Paint()
          // Von gedaempft nach voll: der Bogen wird zum Ende hin
          // kraeftiger, statt auf ganzer Laenge gleich laut zu sein.
          ..shader = SweepGradient(
            startAngle: SpeedGauge._start,
            endAngle: SpeedGauge._start + SpeedGauge._sweep,
            colors: [fill.withValues(alpha: 0.45), fill],
            transform: const GradientRotation(SpeedGauge._start),
          ).createShader(rect)
          ..strokeWidth = _stroke
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    }

    _paintTicks(canvas, centre, radius);
  }

  /// Striche mit Beschriftung innen am Bogen.
  void _paintTicks(Canvas canvas, Offset centre, double radius) {
    final paint = Paint()
      ..color = ticks
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < _tickCount; i++) {
      final angle = SpeedGauge._start + SpeedGauge._sweep * i / (_tickCount - 1);
      final outer = radius - _stroke;
      final inner = outer - 8;

      canvas.drawLine(
        centre + Offset(math.cos(angle), math.sin(angle)) * inner,
        centre + Offset(math.cos(angle), math.sin(angle)) * outer,
        paint,
      );

      // Nur jeder zweite Strich bekommt eine Zahl: die beiden dazwischen
      // liegen auf halber Hoehe und stiessen bei dreistelligem Tempo an
      // die grosse Zahl in der Mitte.
      if (i.isOdd) continue;

      final label = TextPainter(
        text: TextSpan(
          text: '${(scale * i / (_tickCount - 1)).round()}',
          style: labelStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Ein Stueck weiter nach innen als der Strich, sonst sitzt die Zahl
      // auf dem Bogen -- unten, wo Bogen und Strich am naechsten
      // beieinanderliegen, faellt das zuerst auf.
      final at = centre +
          Offset(math.cos(angle), math.sin(angle)) * (inner - Insets.xl);
      label.paint(
        canvas,
        at - Offset(label.width / 2, label.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.fraction != fraction ||
      old.scale != scale ||
      old.fill != fill ||
      old.track != track ||
      old.labelStyle != labelStyle;
}
