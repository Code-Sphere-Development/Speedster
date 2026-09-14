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
    this.ramp,
    super.key,
  });

  final double speedMps;
  final UnitSystem unit;
  final double size;

  /// Die Farbskala des Bogens. Ohne Angabe [rampFor].
  final GaugeRamp? ramp;

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

  /// Baender statt eines Farbtons.
  ///
  /// Vorher lief der Bogen von gedaempftem Rot zu vollem Rot -- zwei
  /// Toene derselben Farbe, die sich beim Fahren als "immer rot" lesen.
  /// Jetzt steht jedes Band fuer einen Bereich, und die Grenzen sind
  /// harte Kanten: man erkennt den Bereich, nicht nur einen Farbton.
  ///
  /// Zwischen dem orangen und dem roten Band liegt ein kurzer Uebergang
  /// statt einer Kante -- sonst spraenge die Farbe bei jedem Schwanken um
  /// die Grenze hin und her.
  static GaugeRamp rampFor(ColorScheme scheme, UnitSystem unit) {
    // In Meilen umgerechnet und auf glatte Werte gerundet: 30/50/120/130
    // km/h sind rund 20/30/75/80 mph.
    final bounds = unit == UnitSystem.kmh
        ? const [30.0, 50.0, 120.0, 130.0, 320.0]
        : const [20.0, 30.0, 75.0, 80.0, 200.0];

    return GaugeRamp(
      colors: [
        _paleGreen, _paleGreen,
        _green, _green,
        _orange, _orange,
        scheme.primary, scheme.primary,
      ],
      at: [
        0, bounds[0],
        bounds[0], bounds[1],
        bounds[1], bounds[2],
        bounds[3], bounds[4],
      ],
    );
  }

  /// Schritttempo und Stadtverkehr.
  static const Color _paleGreen = Color(0xFF7CE7A2);
  static const Color _green = Color(0xFF34C759);

  /// Derselbe Bernstein, den die Heatmap fuer ihr oberes Ende verwendet
  /// (HeatPalette.colorHigh). Nur dieser eine Ton: die Skala dort ist
  /// fuer additives Zeichnen auf dunklem Kartengrund gebaut, und ihr
  /// unteres Ende waere hier praktisch schwarz.
  static const Color _orange = Color(0xFFFF9A3C);

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
          ramp: ramp ?? rampFor(theme.colorScheme, unit),
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

/// Die Farbskala des Bogens.
///
/// Die Farben haengen am **absoluten Tempo**, nicht am Anteil des Bogens.
/// Der Grund ist die mitwachsende Skala: bei Tempo 45 reicht sie bis 60,
/// bei 175 bis 200. Ueber den Anteil gefaerbt gluehte der Bogen in der
/// Stadt genauso heiss wie auf der Autobahn -- und die Farbe hiesse
/// nichts.
class GaugeRamp {
  const GaugeRamp({required this.colors, required this.at});

  final List<Color> colors;

  /// Bei welchem Tempo -- in der angezeigten Einheit -- die jeweilige
  /// Farbe steht. Gleiche Werte hintereinander ergeben eine harte Kante
  /// statt eines Uebergangs.
  final List<double> at;

  /// Wie viele Stuetzstellen der Verlauf auf dem Bogen bekommt.
  ///
  /// Abgetastet statt umgerechnet: die Stuetzstellen eines Verlaufs
  /// muessen zwischen 0 und 1 liegen. Eine Schwelle jenseits der Skala
  /// -- Bernstein bei 130, Skala bis 120 -- wuerde ans Ende geklemmt, und
  /// 120 saehe dann so heiss aus wie 130. Beim Abtasten bleibt jede Farbe
  /// an ihrem Tempo.
  static const int _samples = 24;

  List<Color> colorsFor(double scale) => [
        for (var i = 0; i < _samples; i++)
          colorAt(scale * i / (_samples - 1)),
      ];

  /// Die Farbe fuer ein Tempo, stueckweise zwischen den Schwellen
  /// gemischt.
  Color colorAt(double value) {
    if (value <= at.first) return colors.first;
    if (value >= at.last) return colors.last;

    for (var i = 1; i < at.length; i++) {
      if (value > at[i]) continue;

      final from = colors[i - 1];
      final to = colors[i];
      // Innerhalb eines Bandes ohne Mischen: Color.lerp rechnet in
      // Gleitkomma, und bei gleichen Endfarben faellt je nach t ein
      // anderes letztes Bit heraus. Unsichtbar, aber die Farbe eines
      // Bandes soll ein Wert sein und nicht fast derselbe.
      if (from == to) return from;

      final span = at[i] - at[i - 1];
      // Zwei gleiche Schwellen sind eine harte Kante, kein Uebergang.
      final t = span <= 0 ? 1.0 : (value - at[i - 1]) / span;

      return Color.lerp(from, to, t)!;
    }

    return colors.last;
  }

  @override
  bool operator ==(Object other) =>
      other is GaugeRamp && _sameColors(other.colors) && _sameAt(other.at);

  @override
  int get hashCode => Object.hashAll([...colors, ...at]);

  bool _sameAt(List<double> other) =>
      at.length == other.length &&
      [for (var i = 0; i < at.length; i++) at[i] == other[i]]
          .every((same) => same);

  bool _sameColors(List<Color> other) =>
      colors.length == other.length &&
      [for (var i = 0; i < colors.length; i++) colors[i] == other[i]]
          .every((same) => same);
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({
    required this.fraction,
    required this.scale,
    required this.track,
    required this.ramp,
    required this.ticks,
    required this.labelStyle,
  });

  final double fraction;
  final double scale;
  final Color track;
  final GaugeRamp ramp;
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
            colors: ramp.colorsFor(scale),
            // Ohne zusaetzliche Drehung: startAngle und endAngle liegen
            // bereits auf dem Bogen. Beides zusammen drehte den Verlauf um
            // volle 135 Grad weiter -- bei zwei aehnlichen Rottoenen faellt
            // das nicht auf, bei einer echten Farbskala sofort.
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
      old.ramp != ramp ||
      old.track != track ||
      old.labelStyle != labelStyle;
}
