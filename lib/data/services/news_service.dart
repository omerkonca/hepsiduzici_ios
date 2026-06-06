import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

    // 1. Try Supabase direct read first (Serverless & Instant)
    try {
      final supabase = Supabase.instance.client;
      final res = await supabase
          .from('news_items')
          .select('full_text')
          .eq('source_url', articleUrl)
          .order('created_at', ascending: false)
          .limit(1);
      
      if (res.isNotEmpty && res.first['full_text'] != null) {
        final text = res.first['full_text'] as String?;
        if (text != null && text.trim().isNotEmpty) {
          return text.trim();
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Supabase direct full-text read failed: $e. Falling back to HTTP...');
    }

    // 2. Fallback to HTTP Backend (Render or local backend with fast timeout)
    try {
      final base = AppConfig.backendBaseUrl;
      final res = await _dio.get<Map<String, dynamic>>(
        '$base/api/news/full-text',
        queryParameters: {'url': articleUrl},
        options: Options(
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 6),
        ),
      );
      final data = res.data;
      if (data != null && data['ok'] == true && data['fullText'] != null) {
        final text = data['fullText'] as String?;
        return (text != null && text.trim().isNotEmpty) ? text.trim() : null;
      }
    } catch (_) {
      // If local backend fails (e.g. offline during debug), try production Render directly
      const productionFullTextUrl = 'https://hdbackend-vo99.onrender.com/api/news/full-text';
      if (AppConfig.backendBaseUrl != 'https://hdbackend-vo99.onrender.com') {
        try {
          final res = await _dio.get<Map<String, dynamic>>(
            productionFullTextUrl,
            queryParameters: {'url': articleUrl},
            options: Options(
              connectTimeout: const Duration(seconds: 6),
              receiveTimeout: const Duration(seconds: 8),
            ),
          );
          final data = res.data;
          if (data != null && data['ok'] == true && data['fullText'] != null) {
            final text = data['fullText'] as String?;
            return (text != null && text.trim().isNotEmpty) ? text.trim() : null;
          }
        } catch (_) {}
      }
    }
    return null;
  }

  Future<List<NewsItem>> getNews({int limit = 10}) async =>
      (await getStampedNews(limit: limit)).data;

  Future<Stamped<List<NewsItem>>> getStampedNews({int limit = 10}) async {
    // 1. Try Supabase direct read first (Serverless & Ultra Fast)
    try {
      final supabase = Supabase.instance.client;
      final res = await supabase
          .from('news_items')
          .select()
          .order('created_at', ascending: false)
          .limit(limit * 2); // Fetch extra to account for any duplicates
      
      if (res.isNotEmpty) {
        final seenUrls = <String>{};
        final items = <NewsItem>[];
        for (final row in res) {
          final url = row['source_url'] as String?;
          if (url != null && url.isNotEmpty) {
            if (seenUrls.contains(url)) continue;
            seenUrls.add(url);
          }
          items.add(NewsItem.fromJson({
            'id': row['id'],
            'title': row['title'],
            'summary': row['summary'],
            'imageUrl': row['image_url'],
            'createdAt': row['created_at'],
            'sourceUrl': row['source_url'],
            'sourceName': row['source_name'],
          }));
          if (items.length >= limit) break;
        }
        return Stamped(
          data: items,
          fetchedAt: DateTime.now(),
          source: 'supabase',
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('Supabase direct news read failed: $e. Falling back to HTTP backend...');
    }
    // 1. Try local/configured remoteUrl first with short timeout
    if (remoteUrl.trim().isNotEmpty) {
      try {
        final response = await _dio.get(
          remoteUrl,
          queryParameters: {'max': limit},
          options: Options(
            connectTimeout: const Duration(seconds: 3),
            receiveTimeout: const Duration(seconds: 4),
            sendTimeout: const Duration(seconds: 3),
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
