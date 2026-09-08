import ActivityKit
import Foundation

/// Zustand der laufenden Fahrt, wie ihn der Sperrbildschirm zeigt.
///
/// Diese Datei gehoert **beiden** Targets an: Die App startet und
/// aktualisiert die Live Activity, die Erweiterung stellt sie dar, und
/// ActivityKit verlangt dafuer denselben Typ auf beiden Seiten. Zwei
/// getrennte Fassungen waeren zwei Typen -- die Aktualisierung fiele
/// stillschweigend ins Leere.
@available(iOS 16.1, *)
public struct SpeedsterActivityAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    /// Ganze km/h: Nachkommastellen flackerten im Sekundentakt, ohne dass
    /// sie jemand liest.
    public var speedKmh: Int

    /// Verhaeltnis zur eigenen Gewohnheit an diesem Ort.
    public var verdict: Verdict

    public var distanceMeters: Double
    public var elapsedSeconds: Int

    public init(
      speedKmh: Int,
      verdict: Verdict,
      distanceMeters: Double,
      elapsedSeconds: Int
    ) {
      self.speedKmh = speedKmh
      self.verdict = verdict
      self.distanceMeters = distanceMeters
      self.elapsedSeconds = elapsedSeconds
    }
  }

  public init() {}
}

/// Urteil ueber die aktuelle Geschwindigkeit.
///
/// Bezugsgroesse ist die eigene Gewohnheit an diesem Ort, nicht ein
/// Tempolimit: Die App kennt keine Limits, und es gibt dafuer keine
/// brauchbare freie Quelle (siehe lib/heat/usual_speed.dart).
public enum Verdict: String, Codable, Hashable {
  /// Zu wenige eigene Messungen hier -- keine Aussage.
  case none
  case slower
  case usual
  case faster
}
