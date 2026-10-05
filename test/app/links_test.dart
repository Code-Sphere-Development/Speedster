import 'dart:io';
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
      AppLinks.cloud,
      AppLinks.invitation('x'),
    ]) {
      final uri = Uri.parse(url);
      expect(uri.isAbsolute, isTrue, reason: url);
      expect(uri.scheme, 'https', reason: url);
      expect(uri.host, isNotEmpty, reason: url);
    }
  });

  test('die App fuehrt keinen Weg zu einer Zahlung am Store vorbei', () {
    // Apple hat die App dafuer abgelehnt (Guideline 3.1.1): eine Spende
    // gilt als Bezahlung fuer digitale Inhalte und muesste ueber
    // In-App-Kauf laufen. Der Verweis auf den Browser ist nur auf dem
    // US-Storefront und nur mit eigener Berechtigung erlaubt.
    final quelle = File('lib/app/links.dart').readAsStringSync();

    for (final anbieter in ['paypal', 'ko-fi', 'buymeacoffee', 'patreon',
      'stripe.com', 'gofundme']) {
      expect(quelle.toLowerCase(), isNot(contains(anbieter)), reason: anbieter);
    }
  });
}