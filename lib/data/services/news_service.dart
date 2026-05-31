import 'package:dio/dio.dart';
import '../../core/config/app_config.dart';
import '../models/news_item.dart';
import '../models/stamped_data.dart';

class NewsService {
  const NewsService(this._dio, {this.remoteUrl = ''});

  final Dio _dio;
  final String remoteUrl;

  /// Haber sayfasi URL'inden tam metin ceker (backend full-text endpoint).
  Future<String?> getFullText(String articleUrl) async {
    if (articleUrl.trim().isEmpty) return null;
    try {
      final base = AppConfig.backendBaseUrl;
      final res = await _dio.get<Map<String, dynamic>>(
        '$base/api/news/full-text',
        queryParameters: {'url': articleUrl},
        options: Options(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
        ),
      );
      final data = res.data;
      if (data != null && data['ok'] == true && data['fullText'] != null) {
        final text = data['fullText'] as String?;
        return (text != null && text.trim().isNotEmpty) ? text.trim() : null;
      }
    } catch (_) {}
    return null;
  }

  Future<List<NewsItem>> getNews({int limit = 10}) async =>
      (await getStampedNews(limit: limit)).data;

  Future<Stamped<List<NewsItem>>> getStampedNews({int limit = 10}) async {
    if (remoteUrl.trim().isNotEmpty) {
      for (int attempt = 0; attempt < 2; attempt++) {
        try {
          final response = await _dio.get(
            remoteUrl,
            queryParameters: {'max': limit},
            options: Options(
              connectTimeout: const Duration(seconds: 12),
              receiveTimeout: const Duration(seconds: 15),
              sendTimeout: const Duration(seconds: 12),
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
    }

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
