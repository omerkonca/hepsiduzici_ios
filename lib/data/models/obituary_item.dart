enum ObituaryScope {
  duzici,
  osmaniye,
}

class ObituaryItem {
  const ObituaryItem({
    required this.id,
    required this.fullName,
    required this.deathDate,
    required this.scope,
    this.detail = '',
    this.district = '',
    this.neighborhood = '',
    this.condolenceAddress = '',
    this.burialPlace = '',
    this.age,
    this.source = '',
    this.sourceUrl = '',
    this.detailUrl = '',
  });

  final String id;
  final String fullName;
  final DateTime deathDate;
  final ObituaryScope scope;
  final String detail;
  final String district;
  final String neighborhood;
  final String condolenceAddress;
  final String burialPlace;
  final int? age;
  final String source;
  final String sourceUrl;
  final String detailUrl;

  String get scopeLabel =>
      scope == ObituaryScope.duzici ? 'Düziçi' : 'Osmaniye Geneli';

  String get locationLabel {
    final parts = <String>[
      if (district.isNotEmpty) district,
      if (neighborhood.isNotEmpty) neighborhood,
    ];
    if (parts.isEmpty) return scopeLabel;
    return parts.join(' • ');
  }

  String toShareText() {
    final buffer = StringBuffer()
      ..writeln('Vefat Duyurusu — $scopeLabel')
      ..writeln('Ad Soyad: $fullName');
    if (age != null) buffer.writeln('Yaş: $age');
    buffer.writeln(
      'Vefat Tarihi: ${_formatDate(deathDate)}',
    );
    if (condolenceAddress.isNotEmpty) {
      buffer.writeln('Taziye: $condolenceAddress');
    }
    if (burialPlace.isNotEmpty) {
      buffer.writeln('Defin Yeri: $burialPlace');
    }
    if (detail.isNotEmpty) buffer.writeln(detail);
    if (source.isNotEmpty) buffer.writeln('Kaynak: $source');
    return buffer.toString().trim();
  }

  static String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d.$m.${date.year}';
  }
}
