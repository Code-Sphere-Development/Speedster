import 'package:flutter/material.dart';
import 'package:speedster/app/spacing.dart';

/// Ueberschrift eines Abschnitts, wahlweise mit einer Aktion rechts.
///
/// Loest drei verschiedene Antworten auf dieselbe Frage ab: eine eigene
/// Klasse bei den Freunden, nackte Trennlinien in den Einstellungen und
/// kleingesetzte Zeilen in der Garage. Trennlinien gliedern nur optisch;
/// eine Ueberschrift sagt auch, *was* da unten steht.
///
/// [trailing] traegt die Aktion des Abschnitts -- etwa ein Plus, um einen
/// Eintrag hinzuzufuegen. Sie steht hier und nicht als eigene Zeile
/// darunter, weil sie zur Ueberschrift gehoert und nicht zum Inhalt.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.trailing,
    this.padding,
    super.key,
  });

  final String title;
  final Widget? trailing;

  /// Abweichende Polsterung fuer Abschnitte, die nicht am Bildschirmrand
  /// stehen -- innerhalb einer Karte etwa bringt die Karte den Rand schon
  /// mit, und der Standardwert legte ihn ein zweites Mal darauf.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: padding ??
          EdgeInsets.fromLTRB(
            Insets.screen,
            Insets.xl,
            // Ein Symbolknopf bringt eigene Polsterung mit; ohne diese
            // Ausnahme staende er sichtbar weiter innen als der Text
            // darunter.
            trailing == null ? Insets.screen : Insets.s,
            Insets.s,
          ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.3,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
