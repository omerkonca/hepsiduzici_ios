import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  NotificationService.persistPendingNewsTap(response.payload);
}

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static const int _newsUpdateNotificationId = 91001;
  static const String _pendingNewsTapKey = 'notif_pending_news_tap_key';

  Future<void> init() async {
    tz_data.initializeTimeZones();
    const AndroidInitializationSettings android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings ios = DarwinInitializationSettings();
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

  /// Android 13+ için isteğe bağlı izin; diğer platformlarda true döner.
  Future<bool> ensureAndroidNotificationPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    final android = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? true;
  }

  /// Sistem genelinde uygulama bildirimlerinin açık olup olmadığını döner.
  Future<bool> areSystemNotificationsEnabled() async {
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    final android =
        _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final enabled = await android?.areNotificationsEnabled();
    return enabled ?? true;
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
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: false),
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

  Future<String?> consumePendingNewsTap() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = prefs.getString(_pendingNewsTapKey);
    if (payload != null) {
      await prefs.remove(_pendingNewsTapKey);
    }
    return payload;
  }
}
