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
    
    final lowerTitle = title.toLowerCase();
    final lowerSource = source.toLowerCase();
    
    final matchesOsmaniyeOrDistrict = 
        lowerTitle.contains('osmaniye') || lowerSource.contains('osmaniye') ||
        lowerTitle.contains('kadirli') || lowerSource.contains('kadirli') ||
        lowerTitle.contains('bahçe') || lowerTitle.contains('bahce') || lowerSource.contains('bahçe') || lowerSource.contains('bahce') ||
        lowerTitle.contains('sumbas') || lowerSource.contains('sumbas') ||
        lowerTitle.contains('hasanbeyli') || lowerSource.contains('hasanbeyli') ||
        lowerTitle.contains('toprakkale') || lowerSource.contains('toprakkale');

    final matchesDuzici = lowerTitle.contains('düziçi') || lowerTitle.contains('düzici') || lowerTitle.contains('duzici') ||
                         lowerSource.contains('düziçi') || lowerSource.contains('düzici') || lowerSource.contains('duzici');

    if (matchesOsmaniyeOrDistrict && !matchesDuzici) {
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
