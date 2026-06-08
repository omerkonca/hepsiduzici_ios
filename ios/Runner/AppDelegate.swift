import Flutter
import UIKit
import UserNotifications
import workmanager

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    application.registerForRemoteNotifications()

    // Arka plan isolate içinde diğer plugin'lerin çalışması için (workmanager 0.5.2)
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }

    if let registrar = self.registrar(forPlugin: "be.tramckrijte.workmanager.WorkmanagerPlugin") {
      WorkmanagerPlugin.register(with: registrar)
    }

    // iOS Background Fetch — sistem ne zaman izin verirse haber kontrolü çalışır
    UIApplication.shared.setMinimumBackgroundFetchInterval(15 * 60)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Uygulama ön plandayken de yerel bildirim banner'ı göster (iOS varsayılanı: gizler).
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .list, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }
}
