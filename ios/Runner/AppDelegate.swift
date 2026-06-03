import Flutter
import UIKit
import workmanager

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Arka plan isolate içinde diğer plugin'lerin çalışması için (workmanager 0.5.2)
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }

    // iOS periyodik görev: Background Fetch (registerPeriodicTask yalnızca Android)
    UIApplication.shared.setMinimumBackgroundFetchInterval(15 * 60)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
