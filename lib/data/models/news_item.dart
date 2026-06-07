class NewsItem {
  const NewsItem({
    required this.id,
    required this.title,
    this.summary,
    this.imageUrl,
    required this.createdAt,
    this.sourceUrl,
    this.sourceName,
    this.category = 'Osmaniye',
  });

  final String id;
  final String title;
  final String? summary;
  final String? imageUrl;
  final DateTime createdAt;
  final String? sourceUrl;
  final String? sourceName;
  final String category;

  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ş', 's')
        .replaceAll('ı', 'i')
        .replaceAll('â', 'a')
        .replaceAll('î', 'i');
  }

  static String inferCategory({
    required String title,
    String? summary,
    String? sourceName,
  }) {
    final text = _normalize('$title ${summary ?? ''}');
    final source = _normalize(sourceName ?? '');

    final hasDuzici = RegExp(r'\b(duzici|yarbasi|ellek|atalan|duldul)\b').hasMatch(text);
    final hasOtherDistrict = RegExp(
      r'\b(osmaniye|kadirli|bahce|sumbas|hasanbeyli|toprakkale|karacay|ceylan|duzgun|duzgunbel|duzkoy)\b',
    ).hasMatch(text);
    final hasOku = RegExp(r'\b(oku|korkut ata|osmaniye korkut)\b').hasMatch(text);

    if (hasDuzici) return 'Düziçi';
    if (hasOtherDistrict || hasOku) return 'Osmaniye';

    if (source.contains('google news osmaniye')) return 'Osmaniye';
    if (source.contains('hasret') || source.contains('sabir')) return 'Düziçi';
    if (source.contains('google news')) return 'Osmaniye';

    return 'Osmaniye';
  }

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    final title = json['title'] as String? ?? '';
    final summary = json['summary'] as String?;
    final source = json['sourceName'] as String? ?? '';
    final backendCategory = json['category'] as String?;

    final category = (backendCategory != null && backendCategory.isNotEmpty)
        ? backendCategory
        : inferCategory(title: title, summary: summary, sourceName: source);

    return NewsItem(
      id: json['id'] as String? ?? '',
      title: title,
      summary: summary,
      imageUrl: json['imageUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      sourceUrl: json['sourceUrl'] as String?,
      sourceName: source,
      category: category,
    );
  }
}
