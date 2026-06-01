import 'package:flutter/material.dart';
import '../models/app_notification.dart';
import '../models/city_content.dart';
import '../models/event_item.dart';
import '../models/news_item.dart';
import '../models/road_closure.dart';
import '../models/stamped_data.dart';

/// Tüm bildirimler için kararlı kimlik üretimi (liste sırası değişse bile aynı kalır).
class AppNotificationsBuilder {
  AppNotificationsBuilder._();

  static String outageId(String title) => 'outage_${_slug(title)}';

  static String roadId(String id) => 'road_$id';

  static String newsId(String id) => 'news_$id';

  static String eventId(String id) => 'event_$id';

  static String _slug(String input) {
    var s = input.toLowerCase().trim();
    const map = {
      'ç': 'c', 'ğ': 'g', 'ı': 'i', 'ö': 'o', 'ş': 's', 'ü': 'u',
      'Ç': 'c', 'Ğ': 'g', 'İ': 'i', 'Ö': 'o', 'Ş': 's', 'Ü': 'u',
    };
    map.forEach((k, v) => s = s.replaceAll(k, v));
    s = s.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    s = s.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
    return s.isEmpty ? 'unknown' : s;
  }

  static List<AppNotification> build({
    required Stamped<List<OutageItem>>? outages,
    required Stamped<List<RoadClosure>>? roadClosures,
    required Stamped<List<NewsItem>>? news,
    required Stamped<List<EventItem>>? events,
    required Set<String> favoriteEventIds,
  }) {
    final list = <AppNotification>[];
    final now = DateTime.now();

    if (outages != null) {
      for (final item in outages.data) {
        final isWater = item.type.toUpperCase() == 'SU';
        list.add(
          AppNotification(
            id: outageId(item.title),
            title: item.title,
            body: item.subtitle,
            dateTime: outages.fetchedAt,
            icon: isWater ? Icons.water_drop_rounded : Icons.bolt_rounded,
            color: isWater ? const Color(0xFF1E88E5) : const Color(0xFFF5A623),
            type: AppNotificationType.outage,
            originalData: item,
          ),
        );
      }
    }

    if (roadClosures != null) {
      for (final item in roadClosures.data) {
        if (!item.isActive) continue;
        final start = DateTime.tryParse(item.startAt ?? '') ?? roadClosures.fetchedAt;
        list.add(
          AppNotification(
            id: roadId(item.id),
            title: item.title,
            body:
                '${item.reason} — ${item.roadCode}. Alternatif: ${item.alternativeRoute}',
            dateTime: start,
            icon: Icons.block_rounded,
            color: const Color(0xFFE53935),
            type: AppNotificationType.roadClosure,
            originalData: item,
          ),
        );
      }
    }

    if (news != null) {
      for (final item in news.data) {
        if (now.difference(item.createdAt).inHours > 48) continue;
        list.add(
          AppNotification(
            id: newsId(item.id),
            title: 'Yeni: ${item.title}',
            body: item.summary ?? 'Detaylar için dokunun.',
            dateTime: item.createdAt,
            icon: Icons.newspaper_rounded,
            color: const Color(0xFF00897B),
            type: AppNotificationType.news,
            originalData: item,
          ),
        );
      }
    }

    if (events != null) {
      for (final item in events.data) {
        if (!favoriteEventIds.contains(item.id)) continue;
        list.add(
          AppNotification(
            id: eventId(item.id),
            title: 'Hatırlatıcı: ${item.title}',
            body:
                '${item.date.day}.${item.date.month}.${item.date.year} ${item.date.hour.toString().padLeft(2, '0')}:${item.date.minute.toString().padLeft(2, '0')} — favori etkinliğiniz.',
            dateTime: item.date.subtract(const Duration(hours: 1)),
            icon: Icons.alarm_on_rounded,
            color: const Color(0xFF5C6BC0),
            type: AppNotificationType.event,
            originalData: item,
          ),
        );
      }
    }

    list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return list;
  }
}
