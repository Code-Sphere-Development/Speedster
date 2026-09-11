import AVFoundation
import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var carSink: FlutterEventSink?
  private let liveActivity = LiveActivityBridge()
  private let widgetStore = WidgetStoreBridge()
  private let locationWake = LocationWakeBridge()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Ohne das zeigt iOS eine Mitteilung nicht an, solange die App im
    // Vordergrund steht -- sie wird stillschweigend verworfen. Genau das
    // ist aber der Fall, in dem man die Meldung zum Fahrtbeginn zuerst
    // ausprobiert: App offen, losgefahren, nichts passiert.
    UNUserNotificationCenter.current().delegate =
      self as? UNUserNotificationCenterDelegate

    // Hier und nirgends sonst: nur an dieser Stelle steht in den
    // Startoptionen, ob iOS die App wegen einer Ortsaenderung geweckt hat.
    locationWake.noteLaunch(options: launchOptions)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    FlutterEventChannel(
      name: "de.codesphere.speedster/car_connection",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    ).setStreamHandler(self)

    let messenger = engineBridge.applicationRegistrar.messenger()
    liveActivity.register(messenger: messenger)
    widgetStore.register(messenger: messenger)
    locationWake.register(messenger: messenger)
  }

  /// CarPlay meldet sich als Audio-Ausgang vom Typ `carAudio`. Das laesst
  /// sich ohne CarPlay-Entitlement lesen — ein Entitlement braeuchte erst
  /// eine eigene App auf dem Autodisplay.
  private func isCarConnected() -> Bool {
    AVAudioSession.sharedInstance().currentRoute.outputs.contains {
      $0.portType == .carAudio
    }
  }

  @objc private func routeChanged(_ notification: Notification) {
    carSink?(isCarConnected())
  }
}

extension AppDelegate: FlutterStreamHandler {
  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    carSink = events
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(routeChanged(_:)),
      name: AVAudioSession.routeChangeNotification,
      object: nil
    )
    events(isCarConnected())
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    NotificationCenter.default.removeObserver(
      self,
      name: AVAudioSession.routeChangeNotification,
      object: nil
    )
    carSink = nil
    return nil
  }
}
