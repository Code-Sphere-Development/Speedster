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
  const PlatformCarConnection();

  static const _channel =
      EventChannel('de.mediacologne.speedster/car_connection');

  @override
  Stream<bool> get connected => _channel
      .receiveBroadcastStream()
      .map((event) => event == true)
      .handleError((Object _) {});
}

class FakeCarConnection implements CarConnection {
  FakeCarConnection(this._stream);

  final Stream<bool> _stream;

  @override
  Stream<bool> get connected => _stream;
}
