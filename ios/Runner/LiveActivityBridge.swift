import ActivityKit
import Flutter
import Foundation

/// Steuert die Live Activity auf dem Sperrbildschirm von der Dart-Seite aus.
///
/// Eine Live Activity wird aus dem laufenden App-Prozess aktualisiert --
/// nicht aus der Erweiterung. Dass das waehrend der Fahrt ueberhaupt geht,
/// haengt daran, dass die App im Hintergrund weiterlaeuft: siehe
/// `allowBackgroundLocationUpdates` in lib/sensors/location_service.dart.
/// Ohne diese Einstellung wuerde die App beim Sperren angehalten und die
/// Anzeige bliebe auf dem letzten Wert stehen.
final class LiveActivityBridge {
  static let channelName = "de.codesphere.speedster/live_activity"

  private var activity: Any?

  func register(messenger: FlutterBinaryMessenger) {
    FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
      .setMethodCallHandler { [weak self] call, result in
        self?.handle(call, result: result)
      }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard #available(iOS 16.1, *) else {
      // Aeltere Systeme kennen keine Live Activities. Kein Fehler: die
      // Aufzeichnung selbst funktioniert dort unveraendert, nur die
      // Anzeige entfaellt.
      result(false)
      return
    }

    switch call.method {
    case "start":
      result(start(arguments: call.arguments))
    case "update":
      update(arguments: call.arguments)
      result(true)
    case "end":
      end()
      result(true)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  @available(iOS 16.1, *)
  private func state(from arguments: Any?) -> SpeedsterActivityAttributes.ContentState {
    let map = arguments as? [String: Any] ?? [:]

    return SpeedsterActivityAttributes.ContentState(
      speedKmh: map["speedKmh"] as? Int ?? 0,
      verdict: Verdict(rawValue: map["verdict"] as? String ?? "none") ?? .none,
      distanceMeters: map["distanceMeters"] as? Double ?? 0,
      elapsedSeconds: map["elapsedSeconds"] as? Int ?? 0
    )
  }

  @available(iOS 16.1, *)
  private func start(arguments: Any?) -> Bool {
    // Der Nutzer kann Live Activities systemweit oder je App abschalten.
    // Das ist kein Fehlerfall, sondern eine Entscheidung -- die Fahrt wird
    // trotzdem aufgezeichnet.
    guard ActivityAuthorizationInfo().areActivitiesEnabled else { return false }
    end()

    do {
      activity = try Activity.request(
        attributes: SpeedsterActivityAttributes(),
        contentState: state(from: arguments)
      )

      return true
    } catch {
      return false
    }
  }

  @available(iOS 16.1, *)
  private func update(arguments: Any?) {
    guard let activity = activity as? Activity<SpeedsterActivityAttributes> else {
      return
    }
    let next = state(from: arguments)
    Task { await activity.update(using: next) }
  }

  @available(iOS 16.1, *)
  private func end() {
    guard let activity = activity as? Activity<SpeedsterActivityAttributes> else {
      return
    }
    self.activity = nil
    // .immediate statt .default: nach dem Aussteigen soll die Karte nicht
    // noch Minuten auf dem Sperrbildschirm stehen bleiben.
    Task { await activity.end(dismissalPolicy: .immediate) }
  }
}
