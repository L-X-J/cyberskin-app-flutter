import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  // Live Activity 管理器；iOS 16.1+ 启用，旧系统编译时条件排除。
  @available(iOS 16.1, *)
  private lazy var playbackActivityManager = PlaybackActivityManager()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if #available(iOS 16.1, *) {
      playbackActivityManager.register(
        binaryMessenger: engineBridge.pluginRegistry.registrar(forPlugin: "PlaybackActivity")!.messenger()
      )
    }
  }
}
