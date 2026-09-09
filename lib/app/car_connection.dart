import 'dart:async';

import 'package:flutter/services.dart';

/// Meldet, ob das Geraet mit CarPlay oder Android Auto verbunden ist.
///
/// Bewusst ein *zusaetzliches* Signal neben der Fahrterkennung, nie das
/// einzige: faellt der Plattformkanal aus, lautet die Antwort `false` und
/// die App verhaelt sich wie vorher.
abstract class CarConnection {
  Stream<bool> get connected;
}

class PlatformCarConnection implements CarConnection {
  const PlatformCarConnection({this.disconnectDelay = const Duration(minutes: 2)});

  /// Wie lange eine Trennung anhalten muss, bevor sie zaehlt.
  ///
  /// Die native Seite liest die Verbindung am Audio-Ausgang ab -- CarPlay
  /// meldet sich als Ausgang vom Typ `carAudio`. Das ist der einzige Weg
  /// ohne CarPlay-Entitlement, aber er ist wackelig: die Route beschreibt,
  /// wohin gerade Ton geht, nicht ob das Auto angesteckt ist. Endet ein
  /// Telefonat oder verstummt die Navigationsansage, kann sie kurz auf den
  /// Geraetelautsprecher zeigen, obwohl CarPlay durchgehend verbunden ist.
  ///
  /// Ein solcher Aussetzer beendete die Unterdrueckung des Fahrtendes, und
  /// stand man dann eine Minute an einer Ampel, zerfiel die Fahrt in zwei.
  /// Deshalb zaehlt eine Trennung erst, wenn sie anhaelt; ein Verbinden
  /// gilt sofort.
  final Duration disconnectDelay;

  static const _channel =
      EventChannel('de.codesphere.speedster/car_connection');

  @override
  Stream<bool> get connected => debounceDisconnect(
        _channel
            .receiveBroadcastStream()
            .map((event) => event == true)
            .handleError((Object _) {}),
        disconnectDelay,
      );
}

/// Laesst `true` sofort durch und `false` erst, wenn es anhaelt.
///
/// Ausgelagert und damit ohne Plattformkanal pruefbar.
Stream<bool> debounceDisconnect(Stream<bool> source, Duration delay) {
  late StreamController<bool> out;
  StreamSubscription<bool>? sub;
  Timer? pending;
  bool? last;

  void emit(bool value) {
    if (value == last) return;
    last = value;
    out.add(value);
  }

  out = StreamController<bool>(
    onListen: () {
      sub = source.listen(
        (connected) {
          if (connected) {
            pending?.cancel();
            pending = null;
            emit(true);

            return;
          }

          // Schon getrennt oder eine Trennung laeuft bereits: nichts tun,
          // sonst begaenne die Frist bei jedem Ereignis von vorn.
          if (last == false || pending != null) return;
          pending = Timer(delay, () {
            pending = null;
            emit(false);
          });
        },
        onError: out.addError,
        onDone: out.close,
      );
    },
    onCancel: () {
      pending?.cancel();

      return sub?.cancel();
    },
  );

  return out.stream;
}

class FakeCarConnection implements CarConnection {
  FakeCarConnection(this._stream);

  final Stream<bool> _stream;

  @override
  Stream<bool> get connected => _stream;
}
