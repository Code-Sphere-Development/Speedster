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

  static ColorScheme scheme(Brightness brightness) {
    final base = ColorScheme.fromSeed(
      seedColor: brandRed,
      brightness: brightness,
      // Neutrale Graustufen statt eingefaerbter Flaechen.
      dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
    );

    return brightness == Brightness.dark
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
  }

  static ThemeData _build(Brightness brightness) => ThemeData(
        colorScheme: scheme(brightness),
        useMaterial3: true,
      );
}
