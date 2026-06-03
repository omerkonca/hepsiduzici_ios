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

    // iOS arka plan haber kontrolü (BGTaskScheduler) — 15 dk minimum
    if #available(iOS 13.0, *) {
      WorkmanagerPlugin.registerPeriodicTask(
        withIdentifier: "com.hepsiduzici.news_fetch_task",
        frequency: NSNumber(value: 15 * 60)
      )
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
