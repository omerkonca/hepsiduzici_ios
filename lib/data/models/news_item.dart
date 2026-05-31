class NewsItem {
  const NewsItem({
    required this.id,
    required this.title,
    this.summary,
    this.imageUrl,
    required this.createdAt,
    this.sourceUrl,
    this.sourceName,
    this.category = 'Düziçi',
  });

  final String id;
  final String title;
  final String? summary;
  final String? imageUrl;
  final DateTime createdAt;
  final String? sourceUrl;
  final String? sourceName;
  final String category;

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    final title = json['title'] as String? ?? '';
    final source = json['sourceName'] as String? ?? '';
    
    // Basit bir kategorizasyon mantığı (Backend'den gelmiyorsa)
    String category = json['category'] as String? ?? 'Düziçi';
    if (title.contains('Osmaniye') || source.contains('Osmaniye')) {
      category = 'Osmaniye';
    }

    return NewsItem(
      id: json['id'] as String? ?? '',
      title: title,
      summary: json['summary'] as String?,
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
