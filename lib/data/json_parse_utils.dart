/// API / veritabanından gelen bozuk JSON alanlarını güvenle ayrıştırır.
class JsonParseUtils {
  JsonParseUtils._();

  static List<T> mapList<T>(
    Object? raw,
    T Function(Map<String, dynamic> json) parse,
  ) {
    if (raw is! List) return [];
    final out = <T>[];
    for (final item in raw) {
      if (item is! Map) continue;
      try {
        out.add(parse(Map<String, dynamic>.from(item)));
      } catch (_) {
        // Tek kayıt bozuksa tüm listeyi düşürme.
      }
    }
    return out;
  }
}
