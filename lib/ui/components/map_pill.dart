import 'package:flutter/material.dart';
import 'package:speedster/app/spacing.dart';

/// Durchscheinendes Schildchen ueber der Karte.
///
/// Auf Kachelbildern ist Text ohne eigenen Grund nicht zuverlaessig
/// lesbar -- ueber einem hellen Feld verschwindet er. Die Flaeche darunter
/// ist bewusst nicht deckend: sie soll die Karte daempfen, nicht
/// verdecken.
///
/// Zuvor gab es dieselbe Pille dreimal, mit drei verschiedenen
/// Polsterungen und drei verschiedenen Deckkraeften.
class MapPill extends StatelessWidget {
  const MapPill({required this.child, this.compact = false, super.key});

  final Widget child;

  /// Fuer die Quellenangabe der Kacheln: dieselbe Pille, aber so klein,
  /// dass sie die Karte nicht beansprucht.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(
          compact ? Insets.s : Radii.small,
        ),
      ),
      child: Padding(
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: Insets.s, vertical: 2)
            : const EdgeInsets.symmetric(
                horizontal: Insets.m,
                vertical: Insets.s,
              ),
        child: child,
      ),
    );
  }
}
