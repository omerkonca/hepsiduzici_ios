import 'package:flutter/material.dart';
import '../models/app_notification.dart';
import '../models/city_content.dart';
import '../models/custom_reminder.dart';
import '../models/event_item.dart';
import '../models/news_item.dart';
import '../models/pharmacy.dart';
import '../models/road_closure.dart';
import '../models/stamped_data.dart';

/// Tüm bildirimler için kararlı kimlik üretimi (liste sırası değişse bile aynı kalır).
class AppNotificationsBuilder {
  AppNotificationsBuilder._();

  static String outageId(String title) => 'outage_${_slug(title)}';
  static String roadId(String id) => 'road_$id';
  static String newsId(String id) => 'news_$id';
  static String eventId(String id) => 'event_$id';
  static String customId(String id) => 'custom_$id';
  static String pharmacyId() => 'pharmacy_today';

  /// Bildirim merkezinde gösterilecek en yeni haber sayısı.
  static const int _newsInboxLimit = 25;

  /// Çok eski haberler listeden çıkarılır (feed'deki en yeniler her zaman dahil).
  static const Duration _newsMaxAge = Duration(days: 30);

  /// Yaklaşan etkinlik bildirimi penceresi (gün).
  static const int _upcomingEventDays = 7;

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
    required Set<String> mutedEventIds,
    required List<CustomReminder> customReminders,
    required Stamped<List<Pharmacy>>? pharmacies,
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
            dateTime: item.date ?? outages.fetchedAt,
            icon: isWater ? Icons.water_drop_rounded : Icons.bolt_rounded,
            color: isWater ? const Color(0xFF1E88E5) : const Color(0xFFF5A623),
            type: AppNotificationType.outage,
            originalData: item,
            categoryLabel: 'Belediye',
          ),
        );
      }
    }

    if (roadClosures != null) {
      for (final item in roadClosures.data) {
        if (!item.isActive) continue;
        final start =
            DateTime.tryParse(item.startAt ?? '') ?? roadClosures.fetchedAt;
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
            categoryLabel: 'Belediye',
          ),
        );
      }
    }

    if (news != null) {
      final recentNews = [...news.data]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      for (var i = 0; i < recentNews.length && i < _newsInboxLimit; i++) {
        final item = recentNews[i];
        final age = now.difference(item.createdAt);
        if (age > _newsMaxAge) continue;

        final source = item.sourceName?.trim();
        final summary = item.summary?.trim();
        final body = [
          if (source != null && source.isNotEmpty) source,
          if (summary != null && summary.isNotEmpty) summary,
        ].join(' · ');

        list.add(
          AppNotification(
            id: newsId(item.id),
            title: age.inHours < 24 ? 'Yeni haber: ${item.title}' : item.title,
            body: body.isNotEmpty ? body : 'Detaylar için dokunun.',
            dateTime: item.createdAt,
            icon: Icons.newspaper_rounded,
            color: const Color(0xFF00897B),
            type: AppNotificationType.news,
            originalData: item,
            categoryLabel: 'Haber',
          ),
        );
      }
    }

    if (pharmacies != null && pharmacies.data.isNotEmpty) {
      final p = pharmacies.data.first;
      list.add(
        AppNotification(
          id: pharmacyId(),
          title: 'Bugünün nöbetçi eczanesi',
          body: '${p.name} — ${p.address}',
          dateTime: pharmacies.fetchedAt,
          icon: Icons.local_pharmacy_rounded,
          color: const Color(0xFF00897B),
          type: AppNotificationType.pharmacy,
          originalData: p,
          categoryLabel: 'Sağlık',
        ),
      );
    }

    if (events != null) {
      for (final item in events.data) {
        if (item.date.isBefore(now.subtract(const Duration(hours: 2)))) continue;
        if (mutedEventIds.contains(item.id)) continue;

        if (favoriteEventIds.contains(item.id)) {
          list.add(
            AppNotification(
              id: eventId(item.id),
              title: 'Hatırlatıcı: ${item.title}',
              body:
                  '${item.date.day}.${item.date.month}.${item.date.year} '
                  '${item.date.hour.toString().padLeft(2, '0')}:'
                  '${item.date.minute.toString().padLeft(2, '0')} — favori etkinliğiniz. '
                  'Etkinlikten 1 saat önce bildirim alırsınız.',
              dateTime: item.date,
              icon: Icons.alarm_on_rounded,
              color: const Color(0xFF5C6BC0),
              type: AppNotificationType.event,
              originalData: item,
              categoryLabel: 'Etkinlik',
            ),
          );
          continue;
        }

        final daysUntil = item.date.difference(now).inDays;
        if (daysUntil >= 0 && daysUntil <= _upcomingEventDays) {
          list.add(
            AppNotification(
              id: 'upcoming_${eventId(item.id)}',
              title: 'Yaklaşan: ${item.title}',
              body:
                  '${item.date.day}.${item.date.month}.${item.date.year} '
                  '${item.date.hour.toString().padLeft(2, '0')}:'
                  '${item.date.minute.toString().padLeft(2, '0')} — '
                  '${item.location.isNotEmpty ? item.location : item.district}',
              dateTime: item.date,
              icon: Icons.event_rounded,
              color: const Color(0xFF7E57C2),
              type: AppNotificationType.event,
              originalData: item,
              categoryLabel: 'Etkinlik',
            ),
          );
        }
      }
    }

    for (final item in customReminders) {
      if (item.scheduledAt.isBefore(now.subtract(const Duration(minutes: 30)))) {
        continue;
      }
      list.add(
        AppNotification(
          id: customId(item.id),
          title: item.title,
          body: item.body.isNotEmpty ? item.body : 'Özel hatırlatıcınız.',
          dateTime: item.scheduledAt,
          icon: Icons.notifications_active_rounded,
          color: const Color(0xFFEF6C00),
          type: AppNotificationType.custom,
          originalData: item,
          categoryLabel: 'Özel',
        ),
      );
    }

    list.sort((a, b) => _compareForInbox(a, b));
    return list;
  }

  /// Haberler ve duyurular üstte; gelecek etkinlik tarihi listeyi domine etmez.
  static int _compareForInbox(AppNotification a, AppNotification b) {
    final tierA = _inboxTier(a);
    final tierB = _inboxTier(b);
    if (tierA != tierB) return tierA.compareTo(tierB);

    if (a.type == AppNotificationType.event && b.type == AppNotificationType.event) {
      return a.dateTime.compareTo(b.dateTime);
    }
    return b.dateTime.compareTo(a.dateTime);
  }

  static int _inboxTier(AppNotification n) {
    switch (n.type) {
      case AppNotificationType.news:
        return 0;
      case AppNotificationType.outage:
      case AppNotificationType.roadClosure:
        return 1;
      case AppNotificationType.pharmacy:
        return 2;
      case AppNotificationType.custom:
        return 3;
      case AppNotificationType.event:
        return n.id.startsWith('upcoming_') ? 5 : 4;
    }
  }
}
