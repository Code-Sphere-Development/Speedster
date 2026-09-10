import 'package:flutter/material.dart';
import 'package:speedster/app/spacing.dart';
import 'package:speedster/app/theme.dart';
import 'package:speedster/settings/unit_system.dart';

/// Eine Kennzahl: Zahl gross, Einheit klein daneben, Beschriftung darunter.
///
/// Die App zeigt fast nur Zahlen, hat sie aber bislang gesetzt wie Fliesstext
/// -- Wert und Einheit in einem String, in derselben Groesse wie das Wort
/// davor. Damit stand nirgends, worauf man zuerst schauen soll.
///
/// Einheit und Zahl kommen getrennt herein (siehe [SpeedFormat.speedParts]);
/// als ein String liessen sie sich nicht verschieden setzen.
class MetricValue extends StatelessWidget {
  const MetricValue({
    required this.value,
    this.unit,
    this.label,
    this.icon,
    this.size,
    this.color,
    this.unitColor,
    this.alignment = CrossAxisAlignment.start,
    super.key,
  });

  /// Aus einer bereits zerlegten Groesse.
  MetricValue.of(
    Measure measure, {
    this.label,
    this.icon,
    this.size,
    this.color,
    this.unitColor,
    this.alignment = CrossAxisAlignment.start,
    super.key,
  })  : value = measure.value,
        unit = measure.unit;

  final String value;
  final String? unit;
  final String? label;
  final IconData? icon;

  /// Schriftgroesse der Zahl. Ohne Angabe die des Themenstils.
  final double? size;
  final Color? color;

  /// Farbe von Einheit und Beschriftung. Gebraucht auf getoenter Flaeche:
  /// dort passt die gedaempfte Vordergrundfarbe der gewoehnlichen Flaeche
  /// nicht mehr -- genau daran war "Dein Rang" einmal unlesbar.
  final Color? unitColor;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = unitColor ?? theme.colorScheme.onSurfaceVariant;
    final centred = alignment == CrossAxisAlignment.center;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 28, color: color ?? theme.colorScheme.onSurface),
          const SizedBox(height: Insets.xs),
        ],
        Row(
          mainAxisSize: MainAxisSize.min,
          // Auf der Grundlinie und nicht mittig: eine kleine Einheit
          // schwebte sonst in halber Hoehe neben der Zahl.
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: SpeedsterTheme.metric(context, size: size, color: color),
            ),
            if (unit != null) ...[
              const SizedBox(width: Insets.xs),
              Text(
                unit!,
                style: theme.textTheme.labelMedium?.copyWith(color: muted),
              ),
            ],
          ],
        ),
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(top: Insets.xs),
            child: Text(
              label!,
              textAlign: centred ? TextAlign.center : TextAlign.start,
              style: theme.textTheme.labelMedium?.copyWith(color: muted),
            ),
          ),
      ],
    );
  }
}
