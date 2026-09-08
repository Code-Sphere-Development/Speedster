import SwiftUI
import WidgetKit

@main
struct SpeedsterWidgetsBundle: WidgetBundle {
  var body: some Widget {
    LastTripWidget()
    TotalsWidget()
    RankWidget()
    HeatmapWidget()
    // Live Activities gibt es erst ab 16.1; das Target laeuft ab 15.6,
    // damit auch aeltere Geraete die Widgets bekommen.
    if #available(iOS 16.1, *) {
      SpeedsterWidgetsLiveActivity()
    }
  }
}
