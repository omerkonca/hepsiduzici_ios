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

  static bool isDuziciRelated({required String title, String? summary}) {
    final text = _normalize('$title ${summary ?? ''}');
    return RegExp(r'duzici|yarbasi|ellek|atalan|duldul').hasMatch(text);
  }

  static String inferCategory({
    required String title,
    String? summary,
    String? sourceName,
  }) {
    if (isDuziciRelated(title: title, summary: summary)) return 'Düziçi';
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
