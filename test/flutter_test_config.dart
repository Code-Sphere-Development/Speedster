import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

/// Setzt die Sprache fuer alle Widget-Tests auf Deutsch.
///
/// Flutters Testbindung meldet sonst en_US, und der Bestand an Tests
/// prueft deutsche Texte -- er liefe also gegen die englische Fassung,
/// ohne dass das etwas mit dem geprueften Verhalten zu tun haette. Die
/// englische Fassung deckt localization_test.dart gesondert ab.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized()
      .platformDispatcher
      .localesTestValue = const [Locale('de')];

  // Auch fuer intl: Zahlen werden darueber formatiert, und ohne Vorgabe
  // faellt es auf en_US zurueck. Dann schriebe ein Test "1.5 km", waehrend
  // der deutsche Nutzer "1,5 km" sieht -- gerade das soll er nicht.
  // In der App setzt SpeedsterApp dasselbe aus der aufgeloesten Sprache.
  Intl.defaultLocale = 'de';

  await testMain();
}
