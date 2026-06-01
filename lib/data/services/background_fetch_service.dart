import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';

class BackgroundFetchService {
  BackgroundFetchService._();

  static const String newsFetchTask = 'com.hepsiduzici.news_fetch_task';

  /// Arka plan görevini başlatır.
  static Future<void> init() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  /// Periyodik arka plan görevini kaydeder (Her 15 dakikada bir çalışır).
  static Future<void> registerPeriodicTask() async {
    await Workmanager().registerPeriodicTask(
      '1', // Benzersiz görev kimliği
      newsFetchTask,
      frequency: const Duration(minutes: 15), // İşletim sisteminin izin verdiği minimum süre
      existingWorkPolicy: ExistingWorkPolicy.update,
      constraints: Constraints(
        networkType: NetworkType.connected, // Sadece internete bağlıyken çalışsın
      ),
    );
  }
}

/// Arka planda çalışan isolate'in giriş noktası.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Kullanıcının "Sistem Bildirimi" ayarını kontrol et (Varsayılan: true)
      // Preferences key is 'notif_system_tray_new_news'
      final systemTrayEnabled = prefs.getBool('notif_system_tray_new_news') ?? true;
      if (!systemTrayEnabled) {
        return true;
      }

      // Dio ile haberleri çek (Backend Base URL'inden veya doğrudan haber endpoint'inden)
      final dio = Dio();
      final response = await dio.get(
        'https://hdbackend-vo99.onrender.com/api/news',
        queryParameters: {'max': 5},
      );

      if (response.statusCode != 200 || response.data == null) {
        return true;
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        return true;
      }

      final items = data['items'] as List<dynamic>?;
      if (items == null || items.isEmpty) {
        return true;
      }

      final latestNews = items.first;
      if (latestNews is! Map) {
        return true;
      }

      final String title = latestNews['title']?.toString() ?? '';
      
      // Benzersiz haber kimliği belirleme (ID veya başlık+tarih)
      final String latestId = latestNews['id']?.toString() ?? '';
      final String createdAt = latestNews['createdAt']?.toString() ?? '';
      final String trackingKey = latestId.isNotEmpty ? latestId.trim() : '${title.trim()}|$createdAt';

      if (trackingKey.isEmpty) {
        return true;
      }

      // En son görülen haberi kontrol et
      final lastSeen = prefs.getString('news_last_seen_headline_key');
      
      // Eğer ilk kez çalışıyorsa veya lastSeen boşsa, mevcut haberi kaydet ve bildirim atla
      if (lastSeen == null) {
        await prefs.setString('news_last_seen_headline_key', trackingKey);
        return true;
      }

      // Eğer en son görülen haber ile güncel haber aynıysa, yeni haber yoktur
      if (lastSeen == trackingKey) {
        return true;
      }

      // Yeni haber var! Yerel bildirim gönder
      final localNotifications = FlutterLocalNotificationsPlugin();
      
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      await localNotifications.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
      );

      await localNotifications.show(
        91001, // News notification ID
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
          ),
        ),
      );

      // En son görülen haberi güncelle
      await prefs.setString('news_last_seen_headline_key', trackingKey);
    } catch (_) {
      // Arka plan işlerinde hata oluşursa sistemi patlatmamak için sessizce yut
    }
    return true;
  });
}
