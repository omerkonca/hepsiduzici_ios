import 'package:flutter_test/flutter_test.dart';
import 'package:hepsi_duzici/data/models/news_item.dart';
import 'package:hepsi_duzici/data/services/news_notification_utils.dart';

void main() {
  group('NewsNotificationUtils', () {
    test('headlineTrackingKey prefers id when exists', () {
      final item = NewsItem(
        id: 'abc-1',
        title: 'Baslik',
        createdAt: DateTime(2026, 1, 1),
      );
      expect(NewsNotificationUtils.headlineTrackingKey(item), 'abc-1');
    });

    test('headlineTrackingKey falls back to title and time', () {
      final item = NewsItem(
        id: '',
        title: 'Baslik',
        createdAt: DateTime.parse('2026-01-01T10:00:00.000Z'),
      );
      expect(
        NewsNotificationUtils.headlineTrackingKey(item),
        'Baslik|2026-01-01T10:00:00.000Z',
      );
    });

    test('isNewHeadline compares against last seen key', () {
      expect(
        NewsNotificationUtils.isNewHeadline(currentKey: 'k1', lastSeenKey: null),
        isTrue,
      );
      expect(
        NewsNotificationUtils.isNewHeadline(currentKey: 'k1', lastSeenKey: 'k1'),
        isFalse,
      );
      expect(
        NewsNotificationUtils.isNewHeadline(currentKey: 'k2', lastSeenKey: 'k1'),
        isTrue,
      );
    });
  });
}
