import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';

Map<String, dynamic> arb(String locale) => jsonDecode(
      File('lib/l10n/app_$locale.arb').readAsStringSync(),
    ) as Map<String, dynamic>;

Set<String> keysOf(Map<String, dynamic> tree) =>
    tree.keys.where((k) => !k.startsWith('@')).toSet();

void main() {
  group('Sprachdateien', () {
    test('fuehren in jeder Sprache dieselben Schluessel', () {
      // Fehlt einer, faellt Flutter auf die Vorlage zurueck -- der Nutzer
      // saehe dann mitten im englischen Text einen deutschen Satz, ohne
      // dass es beim Bauen aufgefallen waere.
      final de = keysOf(arb('de'));
      final en = keysOf(arb('en'));

      expect(de.difference(en), isEmpty, reason: 'fehlt in app_en.arb');
      expect(en.difference(de), isEmpty, reason: 'ueberzaehlig in app_en.arb');
    });

    test('lassen keinen Text leer', () {
      for (final locale in ['de', 'en']) {
        final tree = arb(locale);
        for (final key in keysOf(tree)) {
          expect(
            (tree[key] as String).trim(),
            isNotEmpty,
            reason: '$locale: $key ist leer',
          );
        }
      }
    });

    test('behalten Platzhalter in beiden Sprachen', () {
      // Fehlt {message} in einer Fassung, zeigt die Oberflaeche einen Satz
      // mit einem Loch darin.
      final pattern = RegExp(r'\{(\w+)\}');
      final de = arb('de');
      final en = arb('en');

      for (final key in keysOf(de)) {
        Set<String> names(String text) =>
            pattern.allMatches(text).map((m) => m.group(1)!).toSet();

        expect(
          names(en[key] as String),
          names(de[key] as String),
          reason: 'Platzhalter weichen ab bei "$key"',
        );
      }
    });

    test('sind ohne offene Uebersetzungen', () {
      // gen-l10n schreibt hier hinein, was in einer Sprache fehlt.
      final open = File('lib/l10n/untranslated.json');
      final content = open.existsSync() ? open.readAsStringSync().trim() : '{}';

      expect(content, anyOf('{}', ''));
    });
  });

  group('AppLocalizations', () {
    Future<AppLocalizations> load(WidgetTester tester, Locale locale) async {
      late AppLocalizations result;
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              result = AppLocalizations.of(context);

              return const SizedBox.shrink();
            },
          ),
        ),
      );

      return result;
    }

    testWidgets('kennt Deutsch und Englisch', (tester) async {
      expect(
        AppLocalizations.supportedLocales.map((l) => l.languageCode),
        containsAll(['de', 'en']),
      );

      final de = await load(tester, const Locale('de'));
      expect(de.tabTrips, 'Fahrten');

      final en = await load(tester, const Locale('en'));
      expect(en.tabTrips, 'Drives');
    });

    testWidgets('setzt Platzhalter ein', (tester) async {
      final en = await load(tester, const Locale('en'));

      expect(en.commonError('boom'), contains('boom'));
      expect(en.authSocialSoon('Apple'), contains('Apple'));
    });

    testWidgets('faellt bei einer fremden Sprache auf Deutsch zurueck',
        (tester) async {
      // Deutsch ist die Vorlage; Flutter nimmt bei fehlender Passung die
      // erste unterstuetzte Sprache.
      final other = await load(tester, const Locale('es'));

      expect(other.tabTrips, 'Fahrten');
    });
  });
}
