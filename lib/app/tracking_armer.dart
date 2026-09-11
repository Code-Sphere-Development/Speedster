import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedster/app/permissions.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/settings/settings_controller.dart';

/// Macht die Aufzeichnung scharf -- und die Ortsueberwachung dazu.
///
/// Eigene Klasse und kein Widget-Zustand, weil es **vor dem ersten Frame**
/// laufen koennen muss: startet iOS die App wegen einer Ortsaenderung im
/// Hintergrund neu, wird moeglicherweise nie etwas gezeichnet, und ein
/// `addPostFrameCallback` liefe nie an. Genau dann muss aber aufgezeichnet
/// werden.
class TrackingArmer {
  const TrackingArmer(this._ref);

  final Ref _ref;

  /// Gibt zurueck, wie weit die Ortung erlaubt ist.
  Future<LocationAccess> arm() async {
    final settings = _ref.read(settingsControllerProvider);

    // Vor der Einwilligung wird nichts gefragt und nichts aufgezeichnet --
    // ein Ortungsdialog davor waere die Frage vor der Erklaerung.
    if (!settings.consentAccepted) return LocationAccess.denied;

    final access = await _ref.read(permissionGateProvider).ensure();
    final watcher = _ref.read(locationWakeProvider);

    if (settings.trackingPaused || !access.canRecord) {
      await watcher.stopCoarse();
      return access;
    }

    // Nur mit "Immer" startet iOS die App von sich aus wieder. Mit "Beim
    // Verwenden" liefe die Ueberwachung ins Leere und kostete Batterie
    // fuer nichts.
    if (access.survivesTermination) {
      await watcher.startCoarse();
    } else {
      await watcher.stopCoarse();
    }

    // Erst hier den Rekorder anfassen: er haengt an der Datenbank, und
    // ohne Berechtigung soll gar nichts davon aufgebaut werden.
    //
    // Laeuft die Aufzeichnung schon, tut ein zweiter Aufruf nichts --
    // sonst laege bei jedem Wechsel nach vorn ein weiterer Leser auf
    // demselben Strom, und jede Position zaehlte doppelt.
    final recorder = _ref.read(recorderProvider);
    if (!recorder.isRunning) {
      // Fire-and-forget: der Strom ist langlebig.
      unawaited(recorder.start());
    }

    return access;
  }
}
