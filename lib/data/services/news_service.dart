import 'package:dio/dio.dart';
import '../../core/config/app_config.dart';
import '../models/news_item.dart';
import '../models/stamped_data.dart';

class NewsArticleDetails {
  const NewsArticleDetails({this.fullText, this.imageUrl});

  final String? fullText;
  final String? imageUrl;
}

class NewsService {
  const NewsService(this._dio, {this.remoteUrl = ''});

  final Dio _dio;
  final String remoteUrl;

  /// Haber sayfasi URL'inden tam metin ve gorsel ceker (backend full-text endpoint).
  Future<NewsArticleDetails> getArticleDetails(String articleUrl) async {
    if (articleUrl.trim().isEmpty) {
      return const NewsArticleDetails();
    }

    final endpoints = <String>[
      '${AppConfig.backendBaseUrl}/api/news/full-text',
      if (AppConfig.backendBaseUrl != 'https://hdbackend-vo99.onrender.com')
        'https://hdbackend-vo99.onrender.com/api/news/full-text',
    ];

    for (final endpoint in endpoints) {
      try {
        final res = await _dio.get<Map<String, dynamic>>(
          endpoint,
          queryParameters: {'url': articleUrl},
          options: Options(
            connectTimeout: const Duration(seconds: 6),
            receiveTimeout: const Duration(seconds: 12),
          ),
        );
        final data = res.data;
        if (data != null && data['ok'] == true) {
          final text = data['fullText'] as String?;
          final image = data['imageUrl'] as String?;
          return NewsArticleDetails(
            fullText: (text != null && text.trim().isNotEmpty) ? text.trim() : null,
            imageUrl: (image != null && image.trim().isNotEmpty) ? image.trim() : null,
          );
        }
      } catch (_) {}
    }

    return const NewsArticleDetails();
  }

  Future<String?> getFullText(String articleUrl) async {
    final details = await getArticleDetails(articleUrl);
    return details.fullText;
  }

  Future<List<NewsItem>> getNews({int limit = 10}) async =>
      (await getStampedNews(limit: limit)).data;

  Future<Stamped<List<NewsItem>>> getStampedNews({int limit = 10}) async {
    // 1. Try local/configured remoteUrl first with short timeout
    if (remoteUrl.trim().isNotEmpty) {
      try {
        final response = await _dio.get(
          remoteUrl,
          queryParameters: {'max': limit},
          options: Options(
            connectTimeout: const Duration(seconds: 4),
            receiveTimeout: const Duration(seconds: 5),
            sendTimeout: const Duration(seconds: 4),
          ),
        );
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final list = data['items'] as List<dynamic>? ?? [];
          if (list.isNotEmpty) {
            final items = list
                .map((e) => NewsItem.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList();
            final fetchedAt = _parseDate(data['fetchedAt']) ?? DateTime.now();
            return Stamped(data: items, fetchedAt: fetchedAt, source: 'backend');
          }
        }
      } catch (_) {}
    }

    // 2. Fallback: If configured url is not the Render URL, try Render directly
    const productionNewsUrl = 'https://hdbackend-vo99.onrender.com/api/news';
    if (remoteUrl != productionNewsUrl) {
      try {
        final response = await _dio.get(
          productionNewsUrl,
          queryParameters: {'max': limit},
          options: Options(
            connectTimeout: const Duration(seconds: 6),
            receiveTimeout: const Duration(seconds: 8),
            sendTimeout: const Duration(seconds: 6),
          ),
        );
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final list = data['items'] as List<dynamic>? ?? [];
          if (list.isNotEmpty) {
            final items = list
                .map((e) => NewsItem.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList();
            final fetchedAt = _parseDate(data['fetchedAt']) ?? DateTime.now();
            return Stamped(data: items, fetchedAt: fetchedAt, source: 'render-backend');
          }
        }
      } catch (_) {}
    }

    // 3. Last fallback: Return mock news
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return Stamped(data: _mockNews(), fetchedAt: DateTime.now(), source: 'mock');
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
    return null;
  }

  static List<NewsItem> _mockNews() {
    final now = DateTime.now();
    return [
      NewsItem(
        id: '1',
        title: 'Düziçi\'de yeni sosyal tesis açıldı',
        summary: 'İlçe belediyesi tarafından yapılan tesis vatandaşların hizmetine sunuldu.',
        imageUrl: null,
        createdAt: now.subtract(const Duration(hours: 2)),
        sourceUrl: null,
      ),
      NewsItem(
        id: '2',
        title: 'Tarım destekleri başvuruları devam ediyor',
        summary: 'Çiftçilerimiz için destek programı son başvuru tarihi yaklaşıyor.',
        imageUrl: null,
        createdAt: now.subtract(const Duration(days: 1)),
        sourceUrl: null,
      ),
      NewsItem(
        id: '3',
        title: 'Hepsi Düziçi artık mobil uygulamada',
        summary: 'Nöbetçi eczane, hava durumu, namaz vakitleri ve haberler tek uygulamada.',
        imageUrl: null,
        createdAt: now.subtract(const Duration(days: 2)),
        sourceUrl: null,
      ),
    ];
  }
}
