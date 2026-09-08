import Foundation
import SwiftUI

/// Was die App fuer die Widgets in der App Group hinterlegt.
///
/// Die Schluessel sind zeilengetreu mit `lib/widgets/widget_store.dart`
/// abgestimmt. Ein Tippfehler auf einer Seite faellt nirgends auf -- das
/// Widget zeigt dann einfach die Ersatzwerte -- deshalb stehen sie hier
/// als Konstanten und nicht verstreut als Zeichenketten.
enum WidgetKeys {
  static let tripCount = "trip_count"
  static let totalDistance = "total_distance"
  static let maxSpeed = "max_speed"
  static let bestZeroToHundred = "best_zero_to_hundred"

  static let lastTripAt = "last_trip_at"
  static let lastTripDistance = "last_trip_distance"
  static let lastTripMaxSpeed = "last_trip_max_speed"

  static let rank = "rank"
  static let rankScope = "rank_scope"
  static let rankValue = "rank_value"

  static let heatmapImage = "heatmap_image"
  static let updatedAt = "updated_at"
}

/// Liest die Ablage der App Group.
struct SharedStore {
  static let appGroup = "group.de.codesphere.speedster"

  private let defaults: UserDefaults?

  init() {
    defaults = UserDefaults(suiteName: Self.appGroup)
  }

  func double(_ key: String) -> Double? {
    guard let defaults, defaults.object(forKey: key) != nil else { return nil }

    return defaults.double(forKey: key)
  }

  func int(_ key: String) -> Int? {
    guard let defaults, defaults.object(forKey: key) != nil else { return nil }

    return defaults.integer(forKey: key)
  }

  func string(_ key: String) -> String? {
    defaults?.string(forKey: key)
  }

  /// Die Mini-Heatmap kommt als PNG, das die App vorgerendert hat.
  ///
  /// Ein Widget kann keine Karte zeichnen: Kachelserver sind ihm nicht
  /// erreichbar und die Zeichenebene der App steht ihm nicht zur
  /// Verfuegung. Es zeigt deshalb ein Bild, das die App erzeugt hat.
  func image(_ key: String) -> Image? {
    guard
      let encoded = defaults?.string(forKey: key),
      let data = Data(base64Encoded: encoded),
      let ui = UIImage(data: data)
    else {
      return nil
    }

    return Image(uiImage: ui)
  }
}

/// Anzeigehelfer, gespiegelt aus lib/ui/formatters.dart.
enum WidgetFormat {
  static func distance(_ meters: Double) -> String {
    String(format: "%.1f km", meters / 1000).replacingOccurrences(of: ".", with: ",")
  }

  static func speed(_ metersPerSecond: Double) -> String {
    "\(Int((metersPerSecond * 3.6).rounded())) km/h"
  }

  static func seconds(_ value: Double?) -> String {
    guard let value else { return "—" }

    return String(format: "%.1f s", value).replacingOccurrences(of: ".", with: ",")
  }

  static func date(_ iso: String?) -> String {
    guard let iso, let parsed = ISO8601DateFormatter().date(from: iso) else {
      return "—"
    }
    let formatter = DateFormatter()
    formatter.dateFormat = "dd.MM.yyyy HH:mm"

    return formatter.string(from: parsed)
  }
}
