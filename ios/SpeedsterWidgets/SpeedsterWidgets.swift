import SwiftUI
import WidgetKit

/// Ein Eintrag der Zeitachse.
///
/// Alle vier Widgets teilen sich einen: Sie lesen dieselbe Ablage, und
/// vier getrennte Anbieter waeren vier Stellen, an denen derselbe
/// Lesevorgang auseinanderlaufen kann.
struct SpeedsterEntry: TimelineEntry {
  let date: Date
  let store: SharedStore
}

struct SpeedsterProvider: TimelineProvider {
  func placeholder(in context: Context) -> SpeedsterEntry {
    SpeedsterEntry(date: Date(), store: SharedStore())
  }

  func getSnapshot(in context: Context, completion: @escaping (SpeedsterEntry) -> Void) {
    completion(SpeedsterEntry(date: Date(), store: SharedStore()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<SpeedsterEntry>) -> Void) {
    // Die Werte aendern sich nur, wenn die App etwas schreibt -- und dann
    // stoesst sie das Neuzeichnen selbst an (WidgetCenter im
    // WidgetStoreBridge). Ein eigener Zeitplan waere reine
    // Batterieverschwendung; `.never` ueberlaesst die Entscheidung der App.
    completion(
      Timeline(entries: [SpeedsterEntry(date: Date(), store: SharedStore())],
               policy: .never)
    )
  }
}

/// Gemeinsames Aussehen: Beschriftung klein in Versalien, Wert gross.
private struct Metric: View {
  let label: String
  let value: String
  var unit: String?

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(label.uppercased())
        .font(.system(size: 10, weight: .semibold))
        .foregroundStyle(.secondary)
      HStack(alignment: .firstTextBaseline, spacing: 3) {
        Text(value)
          .font(.system(size: 22, weight: .semibold, design: .rounded))
          .monospacedDigit()
          .minimumScaleFactor(0.6)
          .lineLimit(1)
        if let unit {
          Text(unit)
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
        }
      }
    }
  }
}

/// Hinweis, solange die App noch nichts hinterlegt hat.
private struct NoData: View {
  var body: some View {
    VStack(spacing: 4) {
      Image(systemName: "car")
        .foregroundStyle(.secondary)
      Text("Noch keine Fahrt")
        .font(.caption2)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
  }
}

// MARK: - Letzte Fahrt

struct LastTripWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "SpeedsterLastTrip", provider: SpeedsterProvider()) { entry in
      LastTripView(store: entry.store).widgetPadding()
    }
    .configurationDisplayName("Letzte Fahrt")
    .description("Datum, Distanz und Höchstgeschwindigkeit deiner letzten Fahrt.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

private struct LastTripView: View {
  let store: SharedStore

  var body: some View {
    if let distance = store.double(WidgetKeys.lastTripDistance) {
      VStack(alignment: .leading, spacing: 8) {
        Text(WidgetFormat.date(store.string(WidgetKeys.lastTripAt)))
          .font(.caption2)
          .foregroundStyle(.secondary)
        Metric(label: "Distanz", value: WidgetFormat.distance(distance))
        Metric(
          label: "Höchstgeschwindigkeit",
          value: WidgetFormat.speed(store.double(WidgetKeys.lastTripMaxSpeed) ?? 0)
        )
        Spacer(minLength: 0)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    } else {
      NoData()
    }
  }
}

// MARK: - Gesamtzahlen

struct TotalsWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "SpeedsterTotals", provider: SpeedsterProvider()) { entry in
      TotalsView(store: entry.store).widgetPadding()
    }
    .configurationDisplayName("Gesamtzahlen")
    .description("Fahrten, Distanz, Höchstgeschwindigkeit und beste 0–100.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

private struct TotalsView: View {
  let store: SharedStore

  var body: some View {
    if let count = store.int(WidgetKeys.tripCount) {
      VStack(alignment: .leading, spacing: 10) {
        HStack(alignment: .top) {
          Metric(label: "Fahrten", value: "\(count)")
          Spacer()
          Metric(
            label: "Distanz",
            value: WidgetFormat.distance(store.double(WidgetKeys.totalDistance) ?? 0)
          )
        }
        HStack(alignment: .top) {
          Metric(
            label: "Max",
            value: WidgetFormat.speed(store.double(WidgetKeys.maxSpeed) ?? 0)
          )
          Spacer()
          Metric(
            label: "0–100",
            value: WidgetFormat.seconds(store.double(WidgetKeys.bestZeroToHundred))
          )
        }
        Spacer(minLength: 0)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    } else {
      NoData()
    }
  }
}

// MARK: - Eigener Rang

struct RankWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "SpeedsterRank", provider: SpeedsterProvider()) { entry in
      RankView(store: entry.store).widgetPadding()
    }
    .configurationDisplayName("Dein Rang")
    .description("Dein Platz in der Bestenliste.")
    .supportedFamilies([.systemSmall])
  }
}

private struct RankView: View {
  let store: SharedStore

  var body: some View {
    if let rank = store.int(WidgetKeys.rank) {
      VStack(alignment: .leading, spacing: 6) {
        Text((store.string(WidgetKeys.rankScope) ?? "").uppercased())
          .font(.system(size: 10, weight: .semibold))
          .foregroundStyle(.secondary)
        Text("#\(rank)")
          .font(.system(size: 40, weight: .bold, design: .rounded))
          .monospacedDigit()
          .minimumScaleFactor(0.5)
          .lineLimit(1)
        if let value = store.string(WidgetKeys.rankValue) {
          Text(value)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        Spacer(minLength: 0)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    } else {
      VStack(spacing: 4) {
        Image(systemName: "trophy")
          .foregroundStyle(.secondary)
        Text("Cloud nicht aktiv")
          .font(.caption2)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      }
    }
  }
}

// MARK: - Mini-Heatmap

struct HeatmapWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "SpeedsterHeatmap", provider: SpeedsterProvider()) { entry in
      HeatmapView(store: entry.store)
    }
    .configurationDisplayName("Heatmap")
    .description("Deine häufigsten Strecken.")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}

private struct HeatmapView: View {
  let store: SharedStore

  var body: some View {
    if let image = store.image(WidgetKeys.heatmapImage) {
      // Randlos: das Bild ist die Aussage, ein Rahmen nimmt ihm Flaeche.
      image
        .resizable()
        .aspectRatio(contentMode: .fill)
        .widgetBackgroundFill()
    } else {
      NoData().widgetPadding()
    }
  }
}

// MARK: - Hintergrund

/// Ab iOS 17 verlangt WidgetKit `containerBackground`; davor wird der
/// Hintergrund unmittelbar gesetzt. Beides an einer Stelle, damit die
/// Fallunterscheidung nicht in jedem Widget steht.
private extension View {
  func widgetPadding() -> some View {
    modifier(WidgetContainer(padded: true))
  }

  func widgetBackgroundFill() -> some View {
    modifier(WidgetContainer(padded: false))
  }
}

private struct WidgetContainer: ViewModifier {
  let padded: Bool

  func body(content: Content) -> some View {
    if #available(iOS 17.0, *) {
      content
        .padding(padded ? 12 : 0)
        .containerBackground(for: .widget) { WidgetBackground() }
    } else {
      content.padding(padded ? 12 : 0)
    }
  }
}

/// Der Systemhintergrund (`.fill.tertiary`) allein laesst die Kachel auf
/// dem Homescreen wie eine abgeblendete Systemkachel aussehen. Darueber
/// liegt deshalb ein schwacher Verlauf in der Markenfarbe -- gerade genug,
/// dass die Kachel als Speedster erkennbar ist, und schwach genug, dass
/// die Zahlen darauf lesbar bleiben.
@available(iOS 17.0, *)
private struct WidgetBackground: View {
  var body: some View {
    Rectangle()
      .fill(.fill.tertiary)
      .overlay {
        LinearGradient(
          colors: [Color("AccentColor").opacity(0.22), .clear],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      }
  }
}
