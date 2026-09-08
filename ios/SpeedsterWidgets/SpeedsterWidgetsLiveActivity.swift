import ActivityKit
import SwiftUI
import WidgetKit

/// Farbe und Wort zum Urteil.
///
/// An einer Stelle statt an dreien (Sperrbildschirm, aufgeklappte und
/// zusammengeklappte Dynamic Island): sonst weichen die Fassungen beim
/// naechsten Textwechsel voneinander ab.
extension Verdict {
  var label: String {
    switch self {
    case .none: "—"
    case .slower: "langsamer als sonst"
    case .usual: "wie üblich"
    case .faster: "schneller als sonst"
    }
  }

  var tint: Color {
    switch self {
    // Kein Rot fuer "schneller": Rot liest sich als Fehler, und ob
    // schneller schlecht ist, weiss die App nicht -- sie kennt keine
    // Tempolimits, nur die eigene Gewohnheit.
    case .none: .secondary
    case .slower: .blue
    case .usual: .green
    case .faster: .orange
    }
  }

  var symbol: String {
    switch self {
    case .none: "questionmark"
    case .slower: "arrow.down"
    case .usual: "equal"
    case .faster: "arrow.up"
    }
  }
}

@available(iOS 16.1, *)
struct SpeedsterWidgetsLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: SpeedsterActivityAttributes.self) { context in
      LockScreenView(state: context.state)
        .activityBackgroundTint(Color.black.opacity(0.55))
        .activitySystemActionForegroundColor(.white)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Label {
            Text(SpeedFormat.distance(context.state.distanceMeters))
          } icon: {
            Image(systemName: "road.lanes")
          }
          .font(.caption)
        }
        DynamicIslandExpandedRegion(.trailing) {
          Label {
            Text(SpeedFormat.duration(context.state.elapsedSeconds))
          } icon: {
            Image(systemName: "clock")
          }
          .font(.caption)
        }
        DynamicIslandExpandedRegion(.center) {
          SpeedReadout(state: context.state)
        }
      } compactLeading: {
        Image(systemName: context.state.verdict.symbol)
          .foregroundStyle(context.state.verdict.tint)
      } compactTrailing: {
        Text("\(context.state.speedKmh)")
          .monospacedDigit()
      } minimal: {
        Text("\(context.state.speedKmh)")
          .monospacedDigit()
      }
    }
  }
}

/// Die Karte auf dem Sperrbildschirm.
@available(iOS 16.1, *)
private struct LockScreenView: View {
  let state: SpeedsterActivityAttributes.ContentState

  var body: some View {
    HStack(alignment: .center, spacing: 16) {
      SpeedReadout(state: state)

      Spacer(minLength: 0)

      VStack(alignment: .trailing, spacing: 4) {
        Label(SpeedFormat.distance(state.distanceMeters), systemImage: "road.lanes")
        Label(SpeedFormat.duration(state.elapsedSeconds), systemImage: "clock")
      }
      .font(.caption)
      .foregroundStyle(.secondary)
      .labelStyle(.titleAndIcon)
    }
    .padding()
  }
}

/// Geschwindigkeit gross, Urteil klein darunter.
@available(iOS 16.1, *)
private struct SpeedReadout: View {
  let state: SpeedsterActivityAttributes.ContentState

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack(alignment: .firstTextBaseline, spacing: 4) {
        // Tabellenziffern, sonst springt die Breite im Sekundentakt und
        // die ganze Zeile zappelt.
        Text("\(state.speedKmh)")
          .font(.system(size: 40, weight: .semibold, design: .rounded))
          .monospacedDigit()
        Text("km/h")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      if state.verdict != .none {
        Label(state.verdict.label, systemImage: state.verdict.symbol)
          .font(.caption2)
          .foregroundStyle(state.verdict.tint)
      }
    }
  }
}

/// Anzeigehelfer, gespiegelt aus lib/ui/formatters.dart.
enum SpeedFormat {
  static func distance(_ meters: Double) -> String {
    String(format: "%.1f km", meters / 1000)
  }

  /// Ganzzahlige Division, kein Umbruch nach 24 Stunden -- wie in der App.
  static func duration(_ seconds: Int) -> String {
    let h = seconds / 3600
    let m = (seconds % 3600) / 60
    let s = seconds % 60

    return h > 0
      ? String(format: "%dh %02dm", h, m)
      : String(format: "%dm %02ds", m, s)
  }
}
