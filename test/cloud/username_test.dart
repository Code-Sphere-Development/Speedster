import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/cloud/username.dart';

void main() {
  group('normaliseUsername', () {
    test('lowercases so Collin and collin are the same account', () {
      expect(normaliseUsername('Collin'), 'collin');
    });

    test('trims surrounding whitespace', () {
      expect(normaliseUsername('  collin '), 'collin');
    });
  });

  group('validateUsername', () {
    test('accepts the shortest allowed name', () {
      expect(validateUsername('abc'), isNull);
    });

    test('accepts the longest allowed name', () {
      expect(validateUsername('a' * 30), isNull);
    });

    test('accepts digits and underscore', () {
      expect(validateUsername('a_1'), isNull);
    });

    test('accepts uppercase input because it is normalised first', () {
      expect(validateUsername('Collin'), isNull);
    });

    test('rejects two characters', () {
      expect(validateUsername('ab'), isNotNull);
    });

    test('rejects 31 characters', () {
      expect(validateUsername('a' * 31), isNotNull);
    });

    test('rejects umlauts and other special characters', () {
      expect(validateUsername('collin!'), isNotNull);
      expect(validateUsername('cöllin'), isNotNull);
    });

    test('rejects inner whitespace', () {
      expect(validateUsername('col lin'), isNotNull);
    });

    test('reports an empty field as missing, not as a format error', () {
      expect(validateUsername('   '), 'Bitte einen Benutzernamen angeben.');
    });

    test('names the rule instead of only saying invalid', () {
      final message = validateUsername('ab')!;
      expect(message, contains('3 bis 30'));
    });
  });
}
