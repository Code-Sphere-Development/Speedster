/// Abstandsraster der App.
///
/// Vorher standen 25 verschiedene Zahlen als Polsterung und Abstand im
/// Code verteilt -- der Seitenrand war je nach Bildschirm 12, 16, 20, 24
/// oder 32. Das faellt einzeln nicht auf und in der Summe sofort: nichts
/// steht untereinander auf derselben Kante.
///
/// [screen] ist 20 und nicht 16, weil `ScreenHeader` und `listTileTheme`
/// diesen Wert bereits fuehren. Alles andere richtet sich danach, nicht
/// umgekehrt -- sonst muesste die Ueberschrift jedes Bildschirms wandern.
abstract final class Insets {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Seitenrand jedes Bildschirms.
  static const double screen = 20;
}

/// Eckenradien. Drei Stufen, mehr braucht die App nicht.
abstract final class Radii {
  /// Knoepfe, Eingabefelder, Miniaturen.
  static const double small = 12;

  /// Karten.
  static const double card = 16;

  /// Dialoge und Bogenblaetter.
  static const double dialog = 20;

  /// Pillen und Punkte -- alles, was rund sein soll.
  static const double pill = 999;
}
