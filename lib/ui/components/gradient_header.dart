import 'package:flutter/material.dart';
import 'package:speedster/app/spacing.dart';
import 'package:speedster/app/theme.dart';

/// Der Kopfbereich der App: Verlauf, Name, zwei Kennzahlen.
///
/// Nach dem Vorbild von EasyWallet, aber in den Farben dieser App --
/// tiefes Markenrot, das nach unten rechts ins Fast-Schwarz der Flaeche
/// laeuft. Weisse Schrift darauf ist auf der gesamten Strecke lesbar.
///
/// Er nennt bewusst den **Namen der App** und nicht den des Reiters: den
/// sagt die Leiste unten bereits, und ihn oben zu wiederholen war der
/// Grund, warum die Titelleiste seinerzeit weggefallen ist. Was hier oben
/// steht und sonst nirgends, sind die beiden Summen.
class GradientHeader extends StatelessWidget {
  const GradientHeader({
    required this.title,
    this.stats = const [],
    this.leading,
    this.trailing,
    this.showBack = false,
    super.key,
  });

  final String title;

  /// Hoechstens zwei -- mehr wird auf einem Telefon zu schmal, um die
  /// Zahlen noch gross zu setzen.
  final List<HeaderStat> stats;

  final Widget? leading;
  final Widget? trailing;

  /// Ein Zurueck-Pfeil im linken Slot. Fuer Bildschirme, die auf den
  /// Stapel gelegt werden -- sie tragen keine Reiterleiste, ueber die
  /// man sie sonst wieder verliesse.
  final bool showBack;

  /// Fast schwarz nach tiefrot -- in dieser Richtung, nicht umgekehrt.
  ///
  /// EasyWallets Verlauf wird nach unten rechts *heller* (#1a1a2e nach
  /// #0f3460); genau daraus bezieht der Kopf seine Praesenz. Andersherum
  /// gelegt endete er im Ton der Flaeche darunter, und die Unterkante
  /// verschwand -- dann ist es kein Kopfbereich mehr, sondern ein Fleck.
  static const List<Color> gradient = [
    Color(0xFF14161C),
    Color(0xFF2E0C14),
    Color(0xFF5E0C15),
  ];

  /// Breite der Slots links und rechts. Gleich gross, damit der Titel
  /// mittig steht -- auch wenn nur eine Seite belegt ist.
  static const double _slot = 44;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Insets.m,
            Insets.s,
            Insets.m,
            Insets.l,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: _slot,
                    child: showBack
                        ? IconButton(
                            icon: const Icon(Icons.arrow_back),
                            color: Colors.white,
                            tooltip: MaterialLocalizations.of(context)
                                .backButtonTooltip,
                            onPressed: () => Navigator.of(context).maybePop(),
                          )
                        : leading,
                  ),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: _slot, child: trailing),
                ],
              ),
              if (stats.isNotEmpty) ...[
                const SizedBox(height: Insets.m),
                Row(
                  children: [
                    for (final (i, stat) in stats.indexed) ...[
                      if (i > 0) const SizedBox(width: Insets.m),
                      Expanded(child: stat),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Eine Kennzahl im Kopfbereich.
///
/// Glasig statt deckend: der Verlauf soll durchscheinen, sonst saessen
/// zwei graue Kaesten auf einem Farbverlauf. Die Kante macht sie
/// trotzdem als Flaeche erkennbar.
class HeaderStat extends StatelessWidget {
  const HeaderStat({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.m,
        vertical: Insets.s,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(Radii.small),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SpeedsterTheme.metric(context, size: 22, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
