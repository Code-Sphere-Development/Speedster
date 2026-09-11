import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/app/permissions.dart';

void main() {
  test('ohne Erlaubnis gibt es nichts aufzuzeichnen', () async {
    final gate = FakePermissionGate(granted: false);

    expect(await gate.ensure(), LocationAccess.denied);
    expect(LocationAccess.denied.canRecord, isFalse);
  });

  test('"Beim Verwenden" reicht zum Aufzeichnen, aber nicht darueber hinaus',
      () async {
    // Der Unterschied, an dem die App bisher gescheitert ist: es wurde
    // aufgezeichnet, solange sie lief -- und niemand startete sie wieder,
    // nachdem iOS sie beendet hatte.
    final gate = FakePermissionGate(access: LocationAccess.whileInUse);

    expect(await gate.ensure(), LocationAccess.whileInUse);
    expect(LocationAccess.whileInUse.canRecord, isTrue);
    expect(LocationAccess.whileInUse.survivesTermination, isFalse);
  });

  test('"Immer" ueberlebt das Beenden der App', () async {
    final gate = FakePermissionGate(granted: true);

    expect(await gate.ensure(), LocationAccess.always);
    expect(LocationAccess.always.survivesTermination, isTrue);
  });

  test('current fragt nicht', () async {
    // Fuer Anzeigen: ueber ensure erschiene beim blossen Aufrufen der
    // Einstellungen ein Systemdialog.
    final gate = FakePermissionGate(access: LocationAccess.whileInUse);

    expect(await gate.current(), LocationAccess.whileInUse);
    expect(gate.alwaysRequests, 0);
  });
}
