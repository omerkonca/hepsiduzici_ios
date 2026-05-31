/// Finansal araç fiyat kotasyonu (USD, EUR, gram altın, gram gümüş vb.).
class FinanceQuote {
  const FinanceQuote({
    required this.code,
    required this.name,
    required this.value,
    required this.changePercent,
    this.unit = 'TRY',
  });

  /// 'USD', 'EUR', 'GOLD', 'SILVER', vb.
  final String code;

  /// Görüntü adı: 'Dolar', 'Euro', 'Gram Altın', 'Gram Gümüş'
  final String name;

  /// TRY karşılığı.
  final double value;

  /// Günlük değişim yüzdesi. + yükseliş, - düşüş.
  final double changePercent;

  /// Birim (varsayılan TRY).
  final String unit;

  bool get isUp => changePercent >= 0;

  factory FinanceQuote.fromJson(Map<String, dynamic> json) {
    return FinanceQuote(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0,
      changePercent: (json['changePercent'] as num?)?.toDouble() ?? 0,
      unit: json['unit'] as String? ?? 'TRY',
    );
  }
}
