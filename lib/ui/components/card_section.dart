import 'package:flutter/material.dart';
import 'package:speedster/app/spacing.dart';

/// Eine gruppierte Karte: Versalueberschrift, Haarlinie, Zeilen.
///
/// Das Ordnungsmittel aus EasyWallet. Statt einer Karte je Eintrag
/// traegt eine Karte einen ganzen Abschnitt, und die Eintraege darin
/// trennt eine halbe Bildpunktlinie. Das ergibt weniger Kanten auf dem
/// Bildschirm und eine erkennbare Gruppierung -- vorher stand jede Fahrt
/// als eigene Insel da, ohne dass etwas sie zusammenfasste.
class CardSection extends StatelessWidget {
  const CardSection({
    required this.title,
    required this.children,
    this.icon,
    this.trailing,
    super.key,
  });

  final String title;
  final List<Widget> children;
  final IconData? icon;

  /// Rechts neben der Ueberschrift -- eine Summe, eine Aktion.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    final caption = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      color: muted,
    );

    return Container(
      margin: const EdgeInsets.only(
        left: Insets.l,
        right: Insets.l,
        bottom: Insets.l,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.card),
        // Im Dunkelmodus praktisch unsichtbar, im Hellmodus traegt er die
        // Karte ueber die Flaeche. Beide Modi bekommen dieselbe Regel,
        // statt einen Zweig fuer jeden.
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // Die Flaeche traegt ein Material und nicht die Dekoration darum:
      // ListTile und InkWell malen Hintergrund und Wellenanimation auf
      // das naechste Material: liegt darueber ein gefaerbter Container,
      // sind beide unsichtbar. Flutter warnt darueber ausdruecklich.
      child: Material(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(Radii.card),
        clipBehavior: Clip.antiAlias,
        child: Padding(
        padding: const EdgeInsets.all(Insets.l),
        // Die Karte bringt ihren Rand selbst mit; eine ListTile darin
        // legte den ihres Themas noch einmal darauf und stuende dann
        // sichtbar weiter innen als die Ueberschrift darueber.
        child: ListTileTheme.merge(
          contentPadding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 14, color: muted),
                    const SizedBox(width: Insets.xs + 2),
                  ],
                  Expanded(child: Text(title.toUpperCase(), style: caption)),
                  if (trailing != null)
                    DefaultTextStyle.merge(style: caption, child: trailing!),
                ],
              ),
              const _Hairline(margin: EdgeInsets.only(top: Insets.s)),
              for (final (i, child) in children.indexed) ...[
                if (i > 0)
                  const _Hairline(
                    margin: EdgeInsets.symmetric(vertical: Insets.xs),
                  ),
                child,
              ],
            ],
          ),
          ),
        ),
      ),
    );
  }
}

/// Eine halbe Bildpunktlinie -- duenner als der Divider des Themas, so
/// wie EasyWallet sie zieht.
class _Hairline extends StatelessWidget {
  const _Hairline({required this.margin});

  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) => Container(
        margin: margin,
        height: 0.5,
        color: Theme.of(context).colorScheme.outlineVariant,
      );
}
