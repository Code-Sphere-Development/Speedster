import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speedster/app/app.dart';
import 'package:speedster/app/spacing.dart';
import 'package:speedster/app/theme.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';
import 'package:speedster/settings/settings_controller.dart';
import 'package:speedster/ui/consent_screen.dart';
import 'package:speedster/ui/map_tiles.dart';

Future<Widget> app() async {
  SharedPreferences.setMockInitialValues({'consentAccepted': false});
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const SpeedsterApp(),
  );
}

Brightness shownBrightness(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(ConsentScreen))).brightness;

void main() {
  _containerTests();

  testWidgets('uebernimmt den hellen Systemmodus', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(await app());
    await tester.pump();

    expect(shownBrightness(tester), Brightness.light);
  });

  testWidgets('uebernimmt den dunklen Systemmodus', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(await app());
    await tester.pump();

    expect(shownBrightness(tester), Brightness.dark);
  });

  test('beide Helligkeiten sind definiert', () {
    expect(SpeedsterTheme.light.colorScheme.brightness, Brightness.light);
    expect(SpeedsterTheme.dark.colorScheme.brightness, Brightness.dark);
    expect(SpeedsterTheme.brandRed, const Color(0xFFE21C23));
  });

  test('Flaechen tragen einen kuehlen Stich, aber keinen kraeftigen', () {
    // Frueher galt hier das Gegenteil: die Flaechen sollten neutral grau
    // sein. Das Ergebnis wirkte durchgehend deaktiviert. Sie tragen jetzt
    // einen leichten kuehlen Stich -- deutlich genug, dass die Oberflaeche
    // eine Handschrift hat, und schwach genug, dass sie nicht blau wird.
    for (final brightness in Brightness.values) {
      final surface = SpeedsterTheme.scheme(brightness).surface;

      expect(
        surface.b,
        greaterThan(surface.r),
        reason: 'Flaeche bei $brightness ist nicht kuehl: $surface',
      );
      expect(
        surface.b - surface.r,
        lessThan(0.08),
        reason: 'Flaeche bei $brightness ist zu blau: $surface',
      );
    }
  });

  test('Akzent und Zweitfarbe liegen auf gegenueberliegenden Seiten', () {
    // Bewusst nicht ueber das Kontrastverhaeltnis geprueft: das beruht auf
    // Helligkeit, und Rot und Tuerkis liegen dort nah beieinander,
    // obwohl sie sofort zu unterscheiden sind. Gemeint ist die
    // Gegenlaeufigkeit -- der Akzent warm, die Zweitfarbe kuehl. Ohne
    // zweiten Ton wird jede Hervorhebung rot, und dann hebt sich nichts
    // mehr ab.
    for (final brightness in Brightness.values) {
      final scheme = SpeedsterTheme.scheme(brightness);

      expect(
        scheme.primary.r - scheme.primary.b,
        greaterThan(0.4),
        reason: 'Akzent bei $brightness ist nicht warm genug',
      );
      expect(
        scheme.secondary.b - scheme.secondary.r,
        greaterThan(0.4),
        reason: 'Zweitfarbe bei $brightness ist nicht kuehl genug',
      );
    }
  });

  test('die Zweitfarbe bleibt auf der Flaeche lesbar', () {
    for (final brightness in Brightness.values) {
      final scheme = SpeedsterTheme.scheme(brightness);

      expect(
        contrastRatio(scheme.secondary, scheme.surface),
        greaterThanOrEqualTo(3.0),
        reason: 'Zweitfarbe bei $brightness zu schwach',
      );
    }
  });

  test('der Akzent bleibt ein kraeftiges Rot', () {
    // Der abgeleitete Akzent waere im Dunkelmodus ein blasses Lachsrosa.
    final dark = SpeedsterTheme.scheme(Brightness.dark).primary;
    expect(dark.r, greaterThan(0.9));
    expect(dark.g, lessThan(0.4));

    final light = SpeedsterTheme.scheme(Brightness.light).primary;
    expect(light.r, greaterThan(0.7));
    expect(light.g, lessThan(0.2));
  });

  Future<void> pumpMap(WidgetTester tester, ThemeData theme) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: theme,
        home: const FlutterMap(
          options: MapOptions(),
          children: [OsmTileLayer(), OsmAttribution()],
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('Karte bleibt in beiden Helligkeiten unveraendert',
      (tester) async {
    // Der fruehere Abdunkelungsfilter wirkte fahl und ist entfallen.
    for (final theme in [SpeedsterTheme.light, SpeedsterTheme.dark]) {
      await pumpMap(tester, theme);
      expect(find.byType(ColorFiltered), findsNothing);
    }
  });

  testWidgets('Karte nennt ihre Quelle', (tester) async {
    // Die Nutzungsrichtlinie von OpenStreetMap verlangt die Angabe.
    await pumpMap(tester, SpeedsterTheme.light);
    expect(find.textContaining('OpenStreetMap'), findsOneWidget);
  });
}

/// WCAG-2-Kontrastverhaeltnis zweier Farben.
///
/// Die Linearisierung nutzt den Exponenten 2,4, nicht 2,0. Mit 2,0 fallen
/// alle Werte zu niedrig aus, und eine Rampe erscheint schlechter als sie
/// ist -- ein Fehler, der in diesem Projekt schon einmal zu einer
/// unnoetigen Farbaenderung gefuehrt hat.
double contrastRatio(Color a, Color b) {
  double channel(double c) =>
      c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  double luminance(Color c) =>
      0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);

  final la = luminance(a);
  final lb = luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);

  return (hi + 0.05) / (lo + 0.05);
}

void _containerTests() {
  for (final brightness in Brightness.values) {
    test('hervorgehobene Flaeche traegt lesbaren Text ($brightness)', () {
      final scheme = SpeedsterTheme.scheme(brightness);

      // Die Regression: scheme() ueberschrieb nur primary und secondary
      // und ueberliess primaryContainer der monochromen Variante. Die baut
      // Container invers zur Flaeche auf -- fast schwarz im Hellmodus,
      // hellgrau im Dunkelmodus. Text darauf kam auf 1,54:1 bzw. 1,14:1
      // und war unsichtbar.
      final ratio = contrastRatio(
        scheme.onPrimaryContainer,
        scheme.primaryContainer,
      );

      expect(ratio, greaterThanOrEqualTo(4.5), reason: 'WCAG AA fuer Text');
    });

    test('hervorgehobene Flaeche hebt sich von der gewoehnlichen ab '
        '($brightness)', () {
      final scheme = SpeedsterTheme.scheme(brightness);

      // Ohne diesen Unterschied waere die Hervorhebung zwar lesbar, aber
      // nicht als Hervorhebung zu erkennen.
      expect(scheme.primaryContainer, isNot(scheme.surface));
      expect(
        contrastRatio(scheme.primary, scheme.primaryContainer),
        greaterThanOrEqualTo(3.0),
        reason: 'die Akzentkante muss auf der Toenung sichtbar bleiben',
      );
    });
  }

  test('Zahlen laufen mit Tabellenziffern', () {
    // Ohne sie haben "1" und "7" verschiedene Breiten, und die Spalten
    // einer Fahrtenliste springen von Zeile zu Zeile.
    for (final brightness in Brightness.values) {
      final theme = brightness == Brightness.dark
          ? SpeedsterTheme.dark
          : SpeedsterTheme.light;

      for (final style in [
        theme.textTheme.bodyMedium,
        theme.textTheme.titleMedium,
        theme.textTheme.headlineMedium,
        theme.textTheme.labelSmall,
      ]) {
        expect(
          style?.fontFeatures,
          contains(const FontFeature.tabularFigures()),
          reason: 'Stil ohne Tabellenziffern bei $brightness',
        );
      }
    }
  });

  test('Karten heben sich ueber die Flaeche ab, nicht ueber einen Rahmen', () {
    // Eine Linie neben einer getoenten Flaeche wirkt wie ein doppelter
    // Rand.
    for (final brightness in Brightness.values) {
      final theme = brightness == Brightness.dark
          ? SpeedsterTheme.dark
          : SpeedsterTheme.light;

      expect(theme.cardTheme.elevation, 0);
      expect(theme.cardTheme.color, isNot(theme.colorScheme.surface));
    }
  });

  testWidgets('Schaltflaechen mit Beschriftung tragen nicht den Akzent',
      (tester) async {
    // Der eigentliche Defekt der alten Oberflaeche: in Material traegt
    // jede TextButton-Beschriftung `primary`, und in der Garage standen
    // dadurch bis zu achtzehn rote Woerter auf einem Bildschirm --
    // "Loeschen" sah aus wie "Erledigt". Rot markiert jetzt Zustand und
    // genau eine Hauptaktion je Bildschirm.
    for (final brightness in Brightness.values) {
      final theme = brightness == Brightness.dark
          ? SpeedsterTheme.dark
          : SpeedsterTheme.light;

      final foreground = theme.textButtonTheme.style?.foregroundColor
          ?.resolve(const <WidgetState>{});

      expect(foreground, isNotNull, reason: 'textButtonTheme ist gesetzt');
      expect(foreground, theme.colorScheme.onSurface);
      expect(foreground, isNot(theme.colorScheme.primary));
    }
  });

  testWidgets('der Rand der Karten kommt aus dem Thema, nicht vom Aufrufer',
      (tester) async {
    // Vorher setzte das Thema eine Margin, die beide Aufrufstellen
    // ueberschrieben -- der Wert hier wirkte nirgends, und die Karten der
    // Fahrtenliste standen auf einer anderen Kante als die Ueberschrift
    // darueber.
    for (final brightness in Brightness.values) {
      final theme = brightness == Brightness.dark
          ? SpeedsterTheme.dark
          : SpeedsterTheme.light;

      expect(
        theme.cardTheme.margin,
        const EdgeInsets.fromLTRB(
          Insets.screen,
          0,
          Insets.screen,
          Insets.m,
        ),
      );
    }
  });

  test('Eingabefelder liegen nicht auf der Farbe der Karten', () {
    // Alle Containerstufen sind hier bewusst derselbe Ton; ein gefuelltes
    // Feld auf einer Karte oder in einem Dialog waere damit unsichtbar.
    for (final brightness in Brightness.values) {
      final theme = brightness == Brightness.dark
          ? SpeedsterTheme.dark
          : SpeedsterTheme.light;

      expect(theme.inputDecorationTheme.filled, isTrue);
      expect(
        theme.inputDecorationTheme.fillColor,
        isNot(theme.colorScheme.surfaceContainer),
      );
    }
  });
}

