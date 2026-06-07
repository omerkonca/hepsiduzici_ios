class ObituaryUrlBuilder {
  ObituaryUrlBuilder._();

  static const _months = [
    '',
    'ocak',
    'subat',
    'mart',
    'nisan',
    'mayis',
    'haziran',
    'temmuz',
    'agustos',
    'eylul',
    'ekim',
    'kasim',
    'aralik',
  ];

  static const _weekdays = [
    '',
    'pazartesi',
    'sali',
    'carsamba',
    'persembe',
    'cuma',
    'cumartesi',
    'pazar',
  ];

  /// Osmaniye Belediyesi günlük vefat sayfası URL'leri.
  static List<String> osmaniyeDailyUrls({int days = 21, DateTime? from}) {
    final base = from ?? DateTime.now();
    final urls = <String>[];
    for (var i = 0; i < days; i++) {
      final date = DateTime(base.year, base.month, base.day).subtract(
        Duration(days: i),
      );
      final month = _months[date.month];
      final weekday = _weekdays[date.weekday];
      final slug = '${date.day}-$month-${date.year}-$weekday';
      urls.add('https://osmaniye-bld.gov.tr/$slug.html');
    }
    return urls;
  }
}
