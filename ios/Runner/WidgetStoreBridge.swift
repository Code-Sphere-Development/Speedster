import Flutter
import Foundation
import WidgetKit

/// Legt die Werte fuer die Widgets in der App Group ab.
///
/// Widget und App sind getrennte Prozesse; die gemeinsame Ablage ist der
/// einzige Weg dazwischen. Steht die Gruppe nur bei einem der beiden
/// Targets, bleibt das Widget leer -- ohne Fehlermeldung. Deshalb meldet
/// diese Klasse ausdruecklich `false`, wenn sie die Ablage nicht oeffnen
/// kann, statt so zu tun, als sei geschrieben worden.
final class WidgetStoreBridge {
  static let channelName = "de.codesphere.speedster/widget_store"
  static let appGroup = "group.de.codesphere.speedster"

  func register(messenger: FlutterBinaryMessenger) {
    FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
      .setMethodCallHandler { [weak self] call, result in
        self?.handle(call, result: result)
      }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "put":
      result(put(arguments: call.arguments))
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func put(arguments: Any?) -> Bool {
    guard
      let map = arguments as? [String: Any],
      let defaults = UserDefaults(suiteName: Self.appGroup)
    else {
      return false
    }

    for (key, value) in map {
      defaults.set(value, forKey: key)
    }

    // Ohne diesen Anstoss zeichnet das System die Widgets erst beim
    // naechsten eigenen Zeitplan neu -- unter Umstaenden Stunden spaeter.
    if #available(iOS 14.0, *) {
      WidgetCenter.shared.reloadAllTimelines()
    }

    return true
  }
}
