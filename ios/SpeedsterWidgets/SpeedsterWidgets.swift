import SwiftUI
import WidgetKit

/// Platzhalter, wird im naechsten Schritt durch die vier echten Widgets
/// ersetzt (letzte Fahrt, Gesamtzahlen, eigener Rang, Mini-Heatmap).
struct SpeedsterWidgets: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "SpeedsterWidgets", provider: PlaceholderProvider()) { _ in
      Text("Speedster")
    }
    .configurationDisplayName("Speedster")
    .description("Kennzahlen deiner Fahrten.")
  }
}

struct PlaceholderEntry: TimelineEntry {
  let date: Date
}

struct PlaceholderProvider: TimelineProvider {
  func placeholder(in context: Context) -> PlaceholderEntry {
    PlaceholderEntry(date: Date())
  }

  func getSnapshot(in context: Context, completion: @escaping (PlaceholderEntry) -> Void) {
    completion(PlaceholderEntry(date: Date()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<PlaceholderEntry>) -> Void) {
    completion(Timeline(entries: [PlaceholderEntry(date: Date())], policy: .never))
  }
}
