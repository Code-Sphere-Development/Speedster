import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var carSink: FlutterEventSink?
  private let liveActivity = LiveActivityBridge()
  private let widgetStore = WidgetStoreBridge()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
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
