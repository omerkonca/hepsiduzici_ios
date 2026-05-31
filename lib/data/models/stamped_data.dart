/// Bir veri parcasinin yaninda 'cekildigi an' bilgisini de tasiyan sarmalayici.
///
/// Tum veri kaynaklarinda (hava, namaz, finans, akaryakit, haber, eczane)
/// kullanicinin gormesi icin son guncelleme zamani saklamak amacli kullanilir.
class Stamped<T> {
  const Stamped({
    required this.data,
    required this.fetchedAt,
    this.source,
  });

  final T data;
  final DateTime fetchedAt;

  /// Optional - veriyi kim sagladi (or: 'doviz.com', 'admin', 'fallback', 'cache').
  final String? source;

  Stamped<T> copyWith({T? data, DateTime? fetchedAt, String? source}) =>
      Stamped<T>(
        data: data ?? this.data,
        fetchedAt: fetchedAt ?? this.fetchedAt,
        source: source ?? this.source,
      );
}
