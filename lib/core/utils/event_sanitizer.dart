import '../../data/models/event_item.dart';

/// Backend'den gelen ham etkinlik listesini kullanıcıya uygun hale getirir.
/// Google Haber kaynaklı sahte "etkinlik"leri ve tekrarları ayıklar.
class EventSanitizer {
  EventSanitizer._();

  static List<EventItem> clean(List<EventItem> raw) {
    if (raw.isEmpty) return raw;

    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(hours: 6));

    final kept = <EventItem>[];
    for (final item in raw) {
      if (_shouldDrop(item, cutoff)) continue;
      kept.add(_normalizeItem(item));
    }

    return _dedupeByTitle(kept)..sort((a, b) => a.date.compareTo(b.date));
  }

  static bool _shouldDrop(EventItem item, DateTime cutoff) {
    if (item.id.startsWith('news-event-')) return true;
    if (item.link.contains('news.google.com')) return true;

    // Küratör placeholder — genel biletix ana sayfasına giden sahte kayıtlar
    if (item.id.startsWith('manual-')) return true;

    if (_isSeoNewsTitle(item.title)) return true;

    // Geçmiş etkinlikleri gösterme
    if (item.date.isBefore(cutoff)) return true;

    // Haber kaynağı + stok görsel kombinasyonu
    final source = item.source.toLowerCase();
    if (source.contains('haber') &&
        item.imageUrl.contains('unsplash.com/photo-1501281668745')) {
      return true;
    }

    return false;
  }

  static bool _isSeoNewsTitle(String title) {
    final t = title.toLowerCase().trim();
    if (t.isEmpty) return true;
    if (t.contains('ne zaman')) return true;
    if (t.contains('işte gün gün') || t.contains('iste gun gun')) return true;
    if (t.contains('kimler, hangi') || t.contains('hangi sanatçılar')) {
      return true;
    }
    if (t.contains('?') && t.length > 55) return true;
    if (t.length > 110) return true;
    return false;
  }

  static EventItem _normalizeItem(EventItem item) {
    final title = _cleanTitle(item.title);
    final district = _normalizeDistrict(item.district, item.city, item.location);
    return EventItem(
      id: item.id,
      title: title,
      category: _normalizeCategory(item.category, item.title),
      city: item.city.trim().isEmpty ? 'Osmaniye' : item.city.trim(),
      district: district,
      location: item.location.trim().isEmpty ? district : item.location.trim(),
      date: item.date.toLocal(),
      imageUrl: item.imageUrl,
      price: item.price.trim().isEmpty ? 'Biletli' : item.price.trim(),
      link: item.link,
      source: item.source,
    );
  }

  static String _cleanTitle(String title) {
    var t = title.trim();
    if (t.contains('?')) {
      t = t.split('?').first.trim();
    }
    t = t.replaceAll(RegExp(r'\s+'), ' ');
    if (t.length > 72) {
      final cut = t.lastIndexOf(' ', 72);
      t = '${t.substring(0, cut > 40 ? cut : 72).trim()}…';
    }
    return t.isEmpty ? 'Etkinlik' : t;
  }

  static String _normalizeDistrict(String district, String city, String location) {
    final d = district.trim();
    final loc = location.toLowerCase();
    if (d.toLowerCase().contains('düziçi') || loc.contains('düziçi')) {
      return 'Düziçi';
    }
    if (d.isNotEmpty) return d;
    if (city == 'Osmaniye') return 'Merkez';
    return 'Merkez';
  }

  static String _normalizeCategory(String category, String title) {
    final c = category.trim();
    final t = title.toLowerCase();
    if (c == 'Konser' && (t.contains('oyunu') || t.contains('tiyatro'))) {
      return 'Tiyatro';
    }
    if (c == 'Konser' && t.contains('festival')) return 'Festival';
    return c.isEmpty ? 'Etkinlik' : c;
  }

  static List<EventItem> _dedupeByTitle(List<EventItem> items) {
    final seen = <String>{};
    final out = <EventItem>[];
    for (final item in items) {
      final key = _dedupeKey(item);
      if (seen.add(key)) out.add(item);
    }
    return out;
  }

  static String _dedupeKey(EventItem item) {
    final base = item.title
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\sğüşıöç]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final day =
        '${item.date.year}-${item.date.month}-${item.date.day}-${item.city}';
    return '$base|$day';
  }
}
