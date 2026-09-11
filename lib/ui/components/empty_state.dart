import 'package:flutter/material.dart';
import 'package:speedster/app/spacing.dart';

/// Leerer oder blockierter Zustand: Symbol, ein Satz, wahlweise ein Ausweg.
///
/// Vorher stand dieselbe Anordnung viermal im Code -- in der Garage, im
/// Ranking gleich zweimal und bei den Freunden. Sie sahen sich aehnlich,
/// waren aber nirgends gleich, und keine Aenderung erreichte je alle vier.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.message,
    this.icon,
    this.action,
    super.key,
  });

  final String message;
  final IconData? icon;

  /// Der eine Schritt, der aus diesem Zustand herausfuehrt -- Anmelden,
  /// Fahrzeug anlegen. Fehlt er, gibt es keinen.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Insets.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: Insets.l),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              // Gedeckelt, weil hier auch Fehlermeldungen landen: eine
              // Ausnahme samt Stapelspur sprengte sonst das Layout --
              // gemessen einmal um 123.760 Bildpunkte.
              maxLines: 8,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: Insets.xl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
