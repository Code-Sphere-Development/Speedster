import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/ui/formatters.dart';

void main() {
  group('Start und Ziel als Zeile', () {
    test('zwei Orte werden ein Weg', () {
      expect(Formatters.route('Köln', 'Düsseldorf'), 'Köln › Düsseldorf');
    });

    test('derselbe Ort steht nur einmal', () {
      // Eine Runde durch die Stadt als "Köln → Köln" zu schreiben sagt
      // nichts und liest sich wie ein Fehler.
      expect(Formatters.route('Köln', 'Köln'), 'Köln');
    });

    test('ein bekanntes Ende behaelt die Richtung', () {
      // "… › Düsseldorf" heisst "irgendwoher nach Düsseldorf". Der Name
      // allein hiesse "innerhalb von Düsseldorf" -- eine andere Aussage.
      expect(Formatters.route(null, 'Düsseldorf'), '… › Düsseldorf');
      expect(Formatters.route('Köln', null), 'Köln › …');
    });

    test('kein Pfeil U+2192', () {
      // Das Roboto, das Flutter als Rueckfallschrift mitbringt, hat ihn
      // nicht -- dort stuende ein leeres Kaestchen.
      expect(Formatters.route('Köln', 'Bonn'), isNot(contains('\u2192')));
    });

    test('ohne Orte gibt es keine Zeile', () {
      // Dann traegt das Datum die Zeile wie vor dieser Aenderung.
      expect(Formatters.route(null, null), isNull);
    });
  });
}
