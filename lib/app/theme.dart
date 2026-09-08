import 'package:flutter/material.dart';

/// Farbwelt der App: neutrale Flaechen, ein kraeftiger roter Akzent.
///
/// Material 3 leitet aus einer Saatfarbe sonst auch die Flaechen ab und
/// entsaettigt den Akzent im Dunkelmodus. Aus dem Logo-Rot wurde dabei ein
/// Lachsrosa auf braeunlichem Grund. Deshalb werden Flaeche und Akzent hier
/// getrennt: die Grautoene kommen aus der neutralen Variante, der Akzent wird
/// explizit gesetzt.
class SpeedsterTheme {
  const SpeedsterTheme._();

  /// Das Rot aus `tool/branding/speedster.png`.
  static const Color brandRed = Color(0xFFE21C23);

  /// Etwas abgedunkelt: weisse Schrift darauf erreicht 5,06:1 statt 4,39:1.
  static const Color _lightAccent = Color(0xFFCC1A20);

  /// Etwas aufgehellt: 4,74:1 gegen die dunkle Flaeche, und dunkle Schrift
  /// darauf kommt auf 4,83:1.
  static const Color _darkAccent = Color(0xFFFF3B41);
  static const Color _onDarkAccent = Color(0xFF3D0004);

  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  /// Deckkraft, mit der der Akzent als Toenung ueber der Flaeche liegt.
  ///
  /// Gerade so kraeftig, dass die Flaeche als hervorgehoben zu erkennen
  /// ist, und gerade so zurueckhaltend, dass gewoehnlicher Text darauf
  /// lesbar bleibt: 13,9:1 im Hellmodus, 13,1:1 im Dunkelmodus.
  static const double _containerTint = 0.10;

  /// Hervorgehobene Flaeche in der Akzentfamilie.
  ///
  /// Muss ausdruecklich gesetzt werden. `scheme()` ueberschrieb bisher nur
  /// `primary` und `secondary` und ueberliess den Rest der Familie der
  /// monochromen Variante -- die baut Container *invers* zur Flaeche auf
  /// und lieferte damit #3B3B3B (fast schwarz) im Hellmodus und #D4D4D4
  /// (hellgrau) im Dunkelmodus. Text in der jeweiligen Vordergrundfarbe
  /// kam darauf auf 1,54:1 bzw. 1,14:1 und war praktisch unsichtbar.
  static Color containerFor(ColorScheme scheme) => Color.alphaBlend(
        scheme.primary.withValues(alpha: _containerTint),
        scheme.surface,
      );

  static ColorScheme scheme(Brightness brightness) {
    final base = ColorScheme.fromSeed(
      seedColor: brandRed,
      brightness: brightness,
      // Neutrale Graustufen statt eingefaerbter Flaechen.
      dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
    );

    final accented = brightness == Brightness.dark
        ? base.copyWith(
            primary: _darkAccent,
            onPrimary: _onDarkAccent,
            secondary: _darkAccent,
            onSecondary: _onDarkAccent,
          )
        : base.copyWith(
            primary: _lightAccent,
            onPrimary: Colors.white,
            secondary: _lightAccent,
            onSecondary: Colors.white,
          );

    // Die Container-Paare erst jetzt, weil sie vom bereits gesetzten
    // Akzent abgeleitet werden. Vordergrund bleibt die gewoehnliche
    // Textfarbe -- die Toenung ist schwach genug, dass sie traegt.
    final container = containerFor(accented);

    return accented.copyWith(
      primaryContainer: container,
      onPrimaryContainer: accented.onSurface,
      secondaryContainer: container,
      onSecondaryContainer: accented.onSurface,
    );
  }

  static ThemeData _build(Brightness brightness) => ThemeData(
        colorScheme: scheme(brightness),
        useMaterial3: true,
      );
}
