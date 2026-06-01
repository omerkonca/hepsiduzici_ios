import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreferencesKeys {
  static const inAppNewNewsBanner = 'notif_in_app_new_news_banner';
  static const systemTrayNewNews = 'notif_system_tray_new_news';
  static const lastSeenNewsHeadlineKey = 'news_last_seen_headline_key';
}

class NotificationPreferencesService {
  const NotificationPreferencesService();

  Future<bool> getInAppNewNewsBanner() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(NotificationPreferencesKeys.inAppNewNewsBanner) ?? true;
  }

  Future<void> setInAppNewNewsBanner(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(NotificationPreferencesKeys.inAppNewNewsBanner, value);
  }

  Future<bool> getSystemTrayNewNews() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(NotificationPreferencesKeys.systemTrayNewNews) ?? true;
  }

  Future<void> setSystemTrayNewNews(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(NotificationPreferencesKeys.systemTrayNewNews, value);
  }

  Future<String?> getLastSeenNewsHeadlineKey() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getString(NotificationPreferencesKeys.lastSeenNewsHeadlineKey);
    return (v != null && v.isNotEmpty) ? v : null;
  }

  Future<void> setLastSeenNewsHeadlineKey(String key) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(NotificationPreferencesKeys.lastSeenNewsHeadlineKey, key);
  }
}
