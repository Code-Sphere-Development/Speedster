import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/ui/auth_screen.dart';
import 'package:speedster/ui/ranking_screen.dart';

/// Fuehrt durch die Anmeldung und macht den Stand der Cloud danach neu
/// lesbar. `true`, wenn angemeldet wurde.
///
/// Der Aufruf allein genuegt nicht: [cloudActiveProvider] liest den Token
/// genau einmal und haelt das Ergebnis. Ohne das Ungueltigmachen bleibt
/// die ganze App auf "abgemeldet" stehen, bis sie neu startet -- der
/// Bildschirm, von dem aus man sich angemeldet hat, eingeschlossen.
///
/// An zwei Stellen gebraucht (Einstellungen und Bestenliste). Als
/// gemeinsame Funktion, weil die eine sie hatte und die andere nicht --
/// und das im Review aufgefallen ist.
Future<bool> signInToCloud(BuildContext context, WidgetRef ref) async {
  final loggedIn = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => const AuthScreen()),
  );

  if (loggedIn != true) return false;

  ref
    ..invalidate(cloudActiveProvider)
    // Die Wertung hat als abgemeldeter Nutzer einen Fehler gemerkt; ohne
    // das stuende er weiter da.
    ..invalidate(rankingBoardProvider);

  return true;
}
