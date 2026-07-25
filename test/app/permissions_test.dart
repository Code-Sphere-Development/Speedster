import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/app/permissions.dart';

void main() {
  test('recorder gate reports denied', () async {
    final gate = FakePermissionGate(granted: false);
    expect(await gate.ensure(), isFalse);
  });

  test('recorder gate reports granted', () async {
    final gate = FakePermissionGate(granted: true);
    expect(await gate.ensure(), isTrue);
  });
}
