import CoreLocation
import Flutter
import UIKit

/// Laesst iOS die App wieder starten, wenn der Nutzer losfaehrt.
///
/// Ohne das zeichnet Speedster nur auf, solange die App zufaellig noch
/// laeuft. iOS beendet suspendierte Apps bei Speicherdruck -- und genau
/// dann faehrt man los. Regionsueberwachung und "Significant Location
/// Changes" sind die beiden Ortungsarten, fuer die das System eine
/// beendete App von sich aus wieder startet.
///
/// Beide laufen nebeneinander, weil sie verschiedene Faelle abdecken:
///
/// - **Region um den Parkplatz**: schlaegt an, sobald der Kreis verlassen
///   wird -- rund 150 Meter statt 500. Deckt den Normalfall ab, dass man
///   dort losfaehrt, wo man geparkt hat.
/// - **Significant Location Changes**: grob, rund 500 Meter oder ein
///   Funkzellenwechsel. Faengt ab, wenn woanders losgefahren wird -- nach
///   einer Zugfahrt, einem Neustart des Geraets.
///
/// Beides setzt **"Immer"** voraus. Mit "Beim Verwenden" startet das
/// System die App nicht neu, und beide Dienste laufen ins Leere.
final class LocationWakeBridge: NSObject {
  static let channelName = "de.codesphere.speedster/location_wake"

  /// Der Kreis um den Parkplatz. Kleiner waere nicht besser: iOS wertet
  /// Regionen ueber Funkzellen und WLAN aus, nicht ueber GPS -- unter rund
  /// hundert Metern haeufen sich Fehlausloesungen.
  private static let departureRadius: CLLocationDistance = 120

  /// Eine feste Kennung: es gibt immer hoechstens einen Parkplatz, und
  /// ein zweiter Aufruf soll den ersten ersetzen, nicht danebenlegen.
  private static let departureIdentifier = "de.codesphere.speedster.departure"

  private let manager = CLLocationManager()
  private var launchedByLocation = false

  override init() {
    super.init()
    manager.delegate = self
    // Die App soll auch dann weiterlaufen, wenn sie im Hintergrund
    // gestartet wurde.
    manager.allowsBackgroundLocationUpdates = true
    manager.pausesLocationUpdatesAutomatically = false
  }

  /// Muss aus `didFinishLaunchingWithOptions` kommen -- nur dort stehen
  /// die Startoptionen.
  ///
  /// Wurde die App wegen einer Ortsaenderung gestartet, muss die
  /// Ueberwachung **sofort** wieder anlaufen: sonst verwirft iOS das
  /// Ereignis und suspendiert die App gleich wieder.
  func noteLaunch(options: [UIApplication.LaunchOptionsKey: Any]?) {
    launchedByLocation = options?[.location] != nil
    if launchedByLocation {
      startCoarse()
    }
  }

  func register(messenger: FlutterBinaryMessenger) {
    FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
      .setMethodCallHandler { [weak self] call, result in
        guard let self else {
          result(nil)
          return
        }

        switch call.method {
        case "startCoarse":
          self.startCoarse()
          result(nil)
        case "stopCoarse":
          self.manager.stopMonitoringSignificantLocationChanges()
          result(nil)
        case "watchDeparture":
          let args = call.arguments as? [String: Any]
          if let lat = args?["lat"] as? Double, let lng = args?["lng"] as? Double {
            self.watchDeparture(lat: lat, lng: lng)
          }
          result(nil)
        case "clearDeparture":
          self.clearDeparture()
          result(nil)
        case "launchedByLocation":
          result(self.launchedByLocation)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
  }

  private func startCoarse() {
    // Auf Geraeten ohne Mobilfunk gibt es den Dienst nicht.
    guard CLLocationManager.significantLocationChangeMonitoringAvailable() else {
      return
    }
    manager.startMonitoringSignificantLocationChanges()
  }

  private func watchDeparture(lat: Double, lng: Double) {
    guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
      return
    }

    clearDeparture()

    // Das Geraet setzt eine Obergrenze; darueber wuerde die Region
    // stillschweigend nie ausloesen.
    let radius = min(Self.departureRadius, manager.maximumRegionMonitoringDistance)
    let region = CLCircularRegion(
      center: CLLocationCoordinate2D(latitude: lat, longitude: lng),
      radius: radius,
      identifier: Self.departureIdentifier
    )
    // Nur das Verlassen zaehlt: die Ankunft bekommt die App ohnehin mit,
    // da laeuft sie noch.
    region.notifyOnEntry = false
    region.notifyOnExit = true

    manager.startMonitoring(for: region)
  }

  private func clearDeparture() {
    for region in manager.monitoredRegions
    where region.identifier == Self.departureIdentifier {
      manager.stopMonitoring(for: region)
    }
  }
}

extension LocationWakeBridge: CLLocationManagerDelegate {
  /// Bewusst leer: der Empfang allein haelt die App wach. Aufgezeichnet
  /// wird ueber die feine Ortung, die Flutter aufsetzt -- zwei Quellen
  /// nebeneinander ergaeben doppelte Punkte.
  func locationManager(
    _ manager: CLLocationManager,
    didUpdateLocations locations: [CLLocation]
  ) {}

  func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {}

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}

  func locationManager(
    _ manager: CLLocationManager,
    monitoringDidFailFor region: CLRegion?,
    withError error: Error
  ) {}
}
