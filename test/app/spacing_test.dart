import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/app/spacing.dart';

void main() {
  test('die Stufen steigen und sind alle positiv', () {
    // Billiger Waechter: verdreht jemand zwei Werte, faellt es hier auf
    // und nicht erst daran, dass ein Abstand auf einem Bildschirm
    // groesser ist als der naechstgroessere.
    const steps = [
      Insets.xs,
      Insets.s,
      Insets.m,
      Insets.l,
      Insets.xl,
      Insets.xxl,
    ];

    expect(steps.first, greaterThan(0));
    for (var i = 1; i < steps.length; i++) {
      expect(steps[i], greaterThan(steps[i - 1]));
    }
  });

  test('der Seitenrand liegt zwischen l und xl', () {
    // 20, weil ScreenHeader und listTileTheme diesen Wert fuehren --
    // faellt er auf eine der Nachbarstufen, wandert die Ueberschrift
    // jedes Bildschirms.
    expect(Insets.screen, greaterThan(Insets.l));
    expect(Insets.screen, lessThan(Insets.xl));
  });

  test('die Radien steigen von der Schaltflaeche zum Dialog', () {
    expect(Radii.small, lessThan(Radii.card));
    expect(Radii.card, lessThan(Radii.dialog));
    expect(Radii.dialog, lessThan(Radii.pill));
  });
}
