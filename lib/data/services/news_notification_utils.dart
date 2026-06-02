import '../models/news_item.dart';

class NewsNotificationUtils {
  NewsNotificationUtils._();

  static String headlineTrackingKey(NewsItem item) {
    final id = item.id.trim();
    if (id.isNotEmpty) return id;
    return '${item.title}|${item.createdAt.toIso8601String()}';
  }

  static bool isNewHeadline({
    required String currentKey,
    required String? lastSeenKey,
  }) {
    if (lastSeenKey == null || lastSeenKey.trim().isEmpty) return true;
    return lastSeenKey.trim() != currentKey.trim();
  }
}
