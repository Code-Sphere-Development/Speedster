import 'package:flutter/material.dart';
import 'package:speedster/app/spacing.dart';

/// Grosse Ueberschrift im Inhalt, statt einer Titelleiste darueber.
///
/// Die Reiterleiste unten nennt den gewaehlten Bereich bereits; eine
/// Titelleiste wiederholte dasselbe Wort und nahm dafuer eine Zeile
/// Hoehe. Die Ueberschrift gehoert zum Inhalt: sie scrollt mit, statt
/// dauerhaft Platz zu belegen.
///
/// [subtitle] traegt den Zusammenhang, der sonst fehlte -- wie viele
/// Fahrten, welcher Zeitraum, wie viele Fahrzeuge. Ohne ihn wirkt der
/// obere Rand leer, mit ihm beantwortet er eine Frage.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({required this.title, this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      // Volle Breite, damit die Ausrichtung nicht davon abhaengt, worin
      // die Ueberschrift steckt: in einer ListView wuerde sie gedehnt, in
      // einer Column landete sie mittig.
      width: double.infinity,
      // Oben grosszuegig: darueber liegt nur noch die Statusleiste, und
      // die Ueberschrift soll nicht daran kleben.
      padding: const EdgeInsets.fromLTRB(
        Insets.screen,
        Insets.xl,
        Insets.screen,
        Insets.m,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: Insets.xs),
              child: Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
