import 'package:flutter/material.dart';

/// Farbwelt der App, abgeleitet aus dem Rot des Logos.
///
/// Material 3 erzeugt aus einer Saatfarbe beide Helligkeiten, sodass Hell-
/// und Dunkelmodus automatisch zueinander passen.
class SpeedsterTheme {
  const SpeedsterTheme._();

  /// Das Rot aus `tool/branding/speedster.png`.
  static const Color seed = Color(0xFFE21C23);

  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: brightness,
        ),
        useMaterial3: true,
      );
}
