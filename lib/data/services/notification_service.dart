import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import 'news_background_checker.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  NotificationService.persistPendingNewsTap(response.payload);
}

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static const int newsNotificationId = 91001;
  static const int _newsUpdateNotificationId = newsNotificationId;
  static const String _pendingNewsTapKey = 'notif_pending_news_tap_key';

  Future<void> init() async {
    tz_data.initializeTimeZones();
    const AndroidInitializationSettings android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings settings = InitializationSettings(android: android, iOS: ios);
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        persistPendingNewsTap(response.payload);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    final launchDetails = await _notifications.getNotificationAppLaunchDetails();
    final payload = launchDetails?.notificationResponse?.payload;
    if (payload != null && payload.trim().isNotEmpty) {
      await persistPendingNewsTap(payload);
    }
  }

  Future<void> scheduleEventReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // Etkinlikten 1 saat once bildirim gonder
    final reminderTime = scheduledDate.subtract(const Duration(hours: 1));
    if (reminderTime.isBefore(DateTime.now())) return;

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(reminderTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'event_reminders',
          'Etkinlik Hatırlatıcıları',
          channelDescription: 'Favori etkinliklerinizden önce gelen bildirimler',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelReminder(int id) async {
    await _notifications.cancel(id);
  }

  /// Android 13+ ve iOS bildirim izinlerini ister.
  Future<bool> ensureNotificationPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? true;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  /// Geriye dönük uyumluluk.
  Future<bool> ensureAndroidNotificationPermission() => ensureNotificationPermissions();

  /// Sistem genelinde uygulama bildirimlerinin açık olup olmadığını döner.
  Future<bool> areSystemNotificationsEnabled() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final enabled = await android?.areNotificationsEnabled();
      return enabled ?? true;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final settings = await ios?.checkPermissions();
      return settings?.isEnabled ?? false;
    }
    return true;
  }

  Future<void> showNewsHeadlineUpdate({
    required String title,
    String? trackingKey,
  }) async {
    final payload = (trackingKey != null && trackingKey.trim().isNotEmpty)
        ? trackingKey.trim()
        : title.trim();
    await _notifications.show(
      _newsUpdateNotificationId,
      'Yeni haber',
      title,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'news_updates',
          'Haber güncellemeleri',
          channelDescription: 'Liste yenilendiğinde gösterilen kısa bilgilendirme',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      payload: payload,
    );
  }

  Future<void> showTestNotification() async {
    await _notifications.show(
      91002,
      'Test bildirimi',
      'Bildirimler bu cihazda çalışıyor.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'news_updates',
          'Haber güncellemeleri',
          channelDescription: 'Yeni haber yayınlandığında anında gelen bildirimler',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  static Future<void> persistPendingNewsTap(String? payload) async {
    if (payload == null || payload.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingNewsTapKey, payload.trim());
  }

  /// Arka plan / iOS ön plan: yeni haber varsa sistem bildirimi göster.
  Future<bool> checkAndNotifyNewHeadline() {
    return NewsBackgroundChecker.run(notifications: _notifications);
  }

  Future<String?> consumePendingNewsTap() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = prefs.getString(_pendingNewsTapKey);
    if (payload != null) {
      await prefs.remove(_pendingNewsTapKey);
    }
    return payload;
  }
}
