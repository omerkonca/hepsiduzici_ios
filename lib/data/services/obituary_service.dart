import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../../core/utils/obituary_html_parser.dart';
import '../../core/utils/obituary_url_builder.dart';
import '../models/obituary_item.dart';
import '../models/stamped_data.dart';

class ObituaryService {
  const ObituaryService(this._dio);

  final Dio _dio;

  /// Daha eski kayıtlar kullanıcıya gösterilmez.
  static const maxRecordAge = Duration(days: 45);

  static const _duziciUrl = 'https://duzici.bel.tr/vefat-edenler';
  static const _osmaniyeCategoryUrl = 'https://osmaniye-bld.gov.tr/kategori/vefaat';

  Future<List<ObituaryItem>> getObituaries() async =>
      (await getStampedObituaries()).data;

  Future<Stamped<List<ObituaryItem>>> getStampedObituaries() async {
    final backend = await _fetchFromBackend();
    if (backend != null && backend.data.isNotEmpty) {
      return backend;
    }

    final duzici = await _fetchDuziciOfficial();
    final osmaniye = await _fetchOsmaniyeOfficial();
    final merged = _mergeAndSort([...duzici, ...osmaniye]);

    return Stamped(
      data: merged,
      fetchedAt: DateTime.now(),
      source: merged.isEmpty ? 'offline' : 'live',
    );
  }

  Future<Stamped<List<ObituaryItem>>?> _fetchFromBackend() async {
    const productionUrl = 'https://hdbackend-vo99.onrender.com/api/obituaries';
    final urls = <String>{
      if (AppConfig.backendBaseUrl.isNotEmpty)
        '${AppConfig.backendBaseUrl}/api/obituaries',
      productionUrl,
    };

    for (final url in urls) {
      try {
        final response = await _dio.get<Map<String, dynamic>>(
          url,
          options: Options(
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 8),
          ),
        );
        final data = response.data;
        if (data == null || data['ok'] != true) continue;
        final list = data['items'] as List<dynamic>? ?? [];
        if (list.isEmpty) continue;
        final items = list
            .map((e) => _itemFromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        return Stamped(
          data: _mergeAndSort(items),
          fetchedAt: DateTime.tryParse(data['fetchedAt'] as String? ?? '') ??
              DateTime.now(),
          source: 'backend',
        );
      } catch (_) {}
    }
    return null;
  }

  Future<List<ObituaryItem>> _fetchDuziciOfficial() async {
    final html = await _fetchHtml(_duziciUrl);
    if (html == null) return const [];
    return ObituaryHtmlParser.parseDuziciBelTr(html);
  }

  Future<List<ObituaryItem>> _fetchOsmaniyeOfficial() async {
    final links = <String>{
      ...ObituaryUrlBuilder.osmaniyeDailyUrls(days: 21),
    };

    final categoryHtml = await _fetchHtml(_osmaniyeCategoryUrl);
    if (categoryHtml != null) {
      links.addAll(ObituaryHtmlParser.extractOsmaniyeDailyLinks(categoryHtml));
    }

    final items = <ObituaryItem>[];
    for (final link in links) {
      final html = await _fetchHtml(link);
      if (html == null) continue;
      items.addAll(
        ObituaryHtmlParser.parseOsmaniyeBelDaily(html, pageUrl: link),
      );
    }
    return items;
  }

  Future<String?> _fetchHtml(String url) async {
    try {
      final response = await _dio.get<String>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 12),
          headers: const {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/120.0.0.0 Mobile Safari/537.36',
            'Accept-Language': 'tr-TR,tr;q=0.9',
          },
        ),
      );
      final html = response.data;
      if (html == null || html.trim().isEmpty) return null;
      return html;
    } catch (_) {
      return null;
    }
  }

  List<ObituaryItem> _mergeAndSort(List<ObituaryItem> items) {
    final cutoff = DateTime.now().subtract(maxRecordAge);
    final seen = <String>{};
    final out = <ObituaryItem>[];
    for (final item in items) {
      if (!_isTrustedSource(item)) continue;
      if (item.deathDate.isBefore(cutoff)) continue;

      final key =
          '${item.fullName.toLowerCase()}|${item.deathDate.toIso8601String().substring(0, 10)}|${item.scope.name}';
      if (seen.add(key)) out.add(item);
    }
    out.sort((a, b) => b.deathDate.compareTo(a.deathDate));
    return out;
  }

  bool _isTrustedSource(ObituaryItem item) {
    final source = item.source.toLowerCase();
    if (source.contains('cenazeilanlari')) return false;
    return source.contains('belediye') ||
        source.contains('belediyesi') ||
        source == 'backend' ||
        source.isEmpty;
  }

  ObituaryItem _itemFromJson(Map<String, dynamic> json) {
    final scopeRaw = (json['scope'] as String? ?? '').toLowerCase();
    return ObituaryItem(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? json['name'] as String? ?? '',
      deathDate: DateTime.tryParse(json['deathDate'] as String? ?? '') ??
          DateTime.now(),
      scope: scopeRaw.contains('duzici')
          ? ObituaryScope.duzici
          : ObituaryScope.osmaniye,
      detail: json['detail'] as String? ?? '',
      district: json['district'] as String? ?? '',
      neighborhood: json['neighborhood'] as String? ?? '',
      condolenceAddress:
          json['condolenceAddress'] as String? ?? json['condolence'] as String? ?? '',
      burialPlace: json['burialPlace'] as String? ?? json['burial'] as String? ?? '',
      age: json['age'] is int ? json['age'] as int : int.tryParse('${json['age']}'),
      source: json['source'] as String? ?? '',
      sourceUrl: json['sourceUrl'] as String? ?? '',
      detailUrl: json['detailUrl'] as String? ?? '',
    );
  }
}
