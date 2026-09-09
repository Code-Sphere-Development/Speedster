import 'package:flutter/material.dart';

/// Farbwelt der App: rotes Markenzeichen, elektrisch-türkiser Gegenpol,
/// kühle Flächen.
///
/// Das Schema wird **von Hand** gesetzt und nicht aus einer Saatfarbe
/// abgeleitet. Material 3 entsättigt aus dem Logo-Rot sonst ein Lachsrosa
/// auf bräunlichem Grund. Der frühere Ausweg — `DynamicSchemeVariant.
/// monochrome` — vermied das, machte dafür aber alles grau: die
/// Oberfläche sah aus, als wäre sie durchgehend deaktiviert. Beides ist
/// der Grund, warum hier jede tragende Farbe ausdrücklich dasteht.
///
/// Alle Paare sind nach WCAG 2 geprüft (Exponent 2,4, nicht 2,0 — mit
/// 2,0 fallen die Werte zu niedrig aus). Die Zahlen stehen an den
/// Konstanten; ein Test hält sie fest.
class SpeedsterTheme {
  const SpeedsterTheme._();

  /// Das Rot aus `tool/branding/speedster.png`.
  static const Color brandRed = Color(0xFFE21C23);

  // --- Hell ---------------------------------------------------------

  /// Weiss darauf erreicht 5,24:1.
  static const Color _lightPrimary = Color(0xFFD7141A);
  static const Color _lightSecondary = Color(0xFF0092B8);
  static const Color _lightSurface = Color(0xFFF7F8FA);
  static const Color _lightContainer = Color(0xFFE9EDF2);
  static const Color _lightInk = Color(0xFF101418);
  static const Color _lightMuted = Color(0xFF5B6672);

  // --- Dunkel -------------------------------------------------------

  /// 5,45:1 gegen die dunkle Flaeche; dunkle Schrift darauf 4,96:1.
  static const Color _darkPrimary = Color(0xFFFF3B41);
  static const Color _onDarkPrimary = Color(0xFF3D0004);
  static const Color _darkSecondary = Color(0xFF25D0F5);
  static const Color _darkSurface = Color(0xFF0B0F14);
  static const Color _darkContainer = Color(0xFF17202A);
  static const Color _darkInk = Color(0xFFEDF2F7);
  static const Color _darkMuted = Color(0xFF9BA8B5);

  /// Deckkraft, mit der der Akzent als Toenung ueber der Flaeche liegt.
  ///
  /// Kraeftig genug, dass die Flaeche als hervorgehoben zu erkennen ist,
  /// zurueckhaltend genug, dass gewoehnlicher Text darauf lesbar bleibt.
  static const double _containerTint = 0.14;

  /// Hervorgehobene Flaeche in der Akzentfamilie.
  ///
  /// Muss ausdruecklich gesetzt werden: wird sie einem abgeleiteten
  /// Schema ueberlassen, entsteht eine Flaeche, deren Vordergrundfarbe
  /// nicht zu der passt, die das Widget tatsaechlich verwendet -- genau
  /// so war "Dein Rang" einmal unlesbar.
  static Color containerFor(ColorScheme scheme) => Color.alphaBlend(
        scheme.primary.withValues(alpha: _containerTint),
        scheme.surface,
      );

  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ColorScheme scheme(Brightness brightness) {
    final dark = brightness == Brightness.dark;

    final primary = dark ? _darkPrimary : _lightPrimary;
    final surface = dark ? _darkSurface : _lightSurface;
    final container = dark ? _darkContainer : _lightContainer;
    final ink = dark ? _darkInk : _lightInk;
    final muted = dark ? _darkMuted : _lightMuted;

    final base = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    ).copyWith(
      primary: primary,
      onPrimary: dark ? _onDarkPrimary : Colors.white,
      secondary: dark ? _darkSecondary : _lightSecondary,
      onSecondary: dark ? _onDarkPrimary : Colors.white,
      surface: surface,
      onSurface: ink,
      onSurfaceVariant: muted,
      // Alle Container-Ebenen auf denselben Ton: Material staffelt sie
      // sonst in fuenf kaum unterscheidbaren Graustufen, und genau das
      // liess die Oberflaeche flau wirken.
      surfaceContainerLowest: surface,
      surfaceContainerLow: container,
      surfaceContainer: container,
      surfaceContainerHigh: container,
      surfaceContainerHighest: container,
      outlineVariant: Color.alphaBlend(muted.withValues(alpha: 0.28), surface),
      outline: muted,
    );

    final accentSurface = containerFor(base);

    return base.copyWith(
      primaryContainer: accentSurface,
      onPrimaryContainer: ink,
      secondaryContainer: Color.alphaBlend(
        base.secondary.withValues(alpha: _containerTint),
        surface,
      ),
      onSecondaryContainer: ink,
    );
  }

  static ThemeData _build(Brightness brightness) {
    final scheme = SpeedsterTheme.scheme(brightness);

    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
      // Die Reiter tragen keine Titelleiste mehr -- ihre Ueberschrift
      // steht im Inhalt (siehe ScreenHeader). Das Thema gilt weiterhin
      // fuer die Bildschirme darunter, die eine haben: Fahrtdetail,
      // Freunde, Rundgang.
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        // Kein Farbwechsel beim Scrollen: die Leiste soll ruhig stehen.
        scrolledUnderElevation: 0,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        // Der Akzent markiert den aktiven Reiter -- vorher tat das ein
        // Grau, das sich kaum von der Leiste abhob.
        indicatorColor: scheme.primary.withValues(alpha: 0.22),
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainer,
        elevation: 0,
        // Ohne Rahmen und ohne Schatten: die Karte hebt sich allein durch
        // ihre Flaeche ab. Eine Linie darum wirkt neben einer getoenten
        // Flaeche wie ein doppelter Rand.
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      ),
    );

    // Tabellenziffern durchgehend: in dieser App steht in fast jedem
    // Textstil eine Zahl -- Tempo, Distanz, Dauer, Rang, Datum. Ohne sie
    // haben "1" und "7" verschiedene Breiten, und die Spalten einer Liste
    // springen von Zeile zu Zeile. Eine Ausnahmeliste je Stil waere
    // Pflegeaufwand fuer nichts.
    //
    // Nachtraeglich per copyWith: das Textthema entsteht erst aus dem
    // Farbschema, und TextTheme.apply() kennt keine Schriftmerkmale.
    return base.copyWith(textTheme: _tabularFigures(base.textTheme));
  }

  static TextTheme _tabularFigures(TextTheme base) {
    const features = [FontFeature.tabularFigures()];
    TextStyle? tabular(TextStyle? style) =>
        style?.copyWith(fontFeatures: features);

    return base.copyWith(
      displayLarge: tabular(base.displayLarge),
      displayMedium: tabular(base.displayMedium),
      displaySmall: tabular(base.displaySmall),
      headlineLarge: tabular(base.headlineLarge),
      headlineMedium: tabular(base.headlineMedium),
      headlineSmall: tabular(base.headlineSmall),
      titleLarge: tabular(base.titleLarge),
      titleMedium: tabular(base.titleMedium),
      titleSmall: tabular(base.titleSmall),
      bodyLarge: tabular(base.bodyLarge),
      bodyMedium: tabular(base.bodyMedium),
      bodySmall: tabular(base.bodySmall),
      labelLarge: tabular(base.labelLarge),
      labelMedium: tabular(base.labelMedium),
      labelSmall: tabular(base.labelSmall),
    );
  }
}
