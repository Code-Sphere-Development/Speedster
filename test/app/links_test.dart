import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/app/links.dart';

void main() {
  test('der Bewertungslink oeffnet das Formular, nicht nur den Eintrag', () {
    expect(AppLinks.review, startsWith(AppLinks.appStore));
    expect(AppLinks.review, contains('action=write-review'));
  });

  test('der Einladungslink traegt den eigenen Benutzernamen', () {
    expect(AppLinks.invitation('collin'), '${AppLinks.cloud}/einladung/collin');
  });

  test('alle Adressen sind absolut und verschluesselt', () {
    for (final url in [
      AppLinks.appStore,
      AppLinks.review,
      AppLinks.help,
      AppLinks.tip,
      AppLinks.cloud,
      AppLinks.invitation('x'),
    ]) {
      final uri = Uri.parse(url);
      expect(uri.isAbsolute, isTrue, reason: url);
      expect(uri.scheme, 'https', reason: url);
      expect(uri.host, isNotEmpty, reason: url);
    }
  });
}
