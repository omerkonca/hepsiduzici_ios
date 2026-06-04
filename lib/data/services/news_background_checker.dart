import 'package:dio/dio.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_config.dart';
import 'notification_preferences_service.dart';
import 'notification_service.dart';

/// Arka plan / ön plan haber kontrolü (Android Workmanager + iOS fallback).
class NewsBackgroundChecker {
  NewsBackgroundChecker._();

  static const String lastRunAtKey = 'news_bg_last_run_at';
  static const String lastStatusKey = 'news_bg_last_status';
  static const String lastErrorKey = 'news_bg_last_error';
  static const String lastNotifiedTitleKey = 'news_bg_last_notified_title';

  static Future<bool> run({FlutterLocalNotificationsPlugin? notifications}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(lastRunAtKey, DateTime.now().toIso8601String());
    await prefs.setString(lastStatusKey, 'running');
    await prefs.remove(lastErrorKey);

    try {
      final systemTrayEnabled =
          prefs.getBool(NotificationPreferencesKeys.systemTrayNewNews) ?? true;
      if (!systemTrayEnabled) {
        await prefs.setString(lastStatusKey, 'skipped_disabled');
        return true;
      }

      final dio = Dio();
      final response = await dio.get(
        AppConfig.newsUrl,
        queryParameters: {'max': 5},
        options: Options(
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 25),
        ),
      );

      if (response.statusCode != 200 || response.data == null) {
        await prefs.setString(lastStatusKey, 'skipped_bad_response');
        return false;
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        await prefs.setString(lastStatusKey, 'skipped_bad_payload');
        return false;
      }

      final items = data['items'] as List<dynamic>?;
      if (items == null || items.isEmpty) {
        await prefs.setString(lastStatusKey, 'skipped_empty');
        return false;
      }

      final latestNews = items.first;
      if (latestNews is! Map) {
        await prefs.setString(lastStatusKey, 'skipped_item_type');
        return false;
      }

      final title = latestNews['title']?.toString() ?? '';
      final latestId = latestNews['id']?.toString() ?? '';
      final createdAt = latestNews['createdAt']?.toString() ?? '';
      final trackingKey =
          latestId.isNotEmpty ? latestId.trim() : '${title.trim()}|$createdAt';

      if (trackingKey.isEmpty) {
        await prefs.setString(lastStatusKey, 'skipped_tracking_key');
        return false;
      }

      final lastSeen = prefs.getString(NotificationPreferencesKeys.lastSeenNewsHeadlineKey);
      if (lastSeen == null) {
        await prefs.setString(NotificationPreferencesKeys.lastSeenNewsHeadlineKey, trackingKey);
        await prefs.setString(lastStatusKey, 'initialized');
        return true;
      }

      if (lastSeen == trackingKey) {
        await prefs.setString(lastStatusKey, 'no_change');
        return true;
      }

      final plugin = notifications ?? FlutterLocalNotificationsPlugin();
      if (notifications == null) {
        const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
        const iosInit = DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );
        await plugin.initialize(
          const InitializationSettings(android: androidInit, iOS: iosInit),
          onDidReceiveNotificationResponse: (response) {
            NotificationService.persistPendingNewsTap(response.payload);
          },
          onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
        );
      }

      final payload = latestId.isNotEmpty ? latestId.trim() : title.trim();
      await plugin.show(
        NotificationService.newsNotificationId,
        'Yeni Haber Yayınlandı 📰',
        title,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'news_updates',
            'Haber Güncellemeleri',
            channelDescription: 'Yeni haber yayınlandığında anında gelen bildirimler',
            importance: Importance.max,
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

      await prefs.setString(NotificationPreferencesKeys.lastSeenNewsHeadlineKey, trackingKey);
      await prefs.setString(lastNotifiedTitleKey, title);
      await prefs.setString(lastStatusKey, 'notified');
      return true;
    } catch (e) {
      await prefs.setString(lastStatusKey, 'error');
      await prefs.setString(lastErrorKey, e.toString());
      return false;
    }
  }
}
