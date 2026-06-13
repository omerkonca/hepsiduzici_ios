import 'package:dio/dio.dart';
import '../models/pharmacy.dart';
import '../models/stamped_data.dart';

class PharmacyService {
  const PharmacyService(this._dio, {this.remoteUrl = ''});

  final Dio _dio;
  final String remoteUrl;

  static const String sourceUrl =
      'https://www.eczaneler.gen.tr/nobetci-osmaniye-duzici';

  Future<List<Pharmacy>> getDutyPharmacies({
    String city = 'Osmaniye',
    String district = 'Duzici',
    bool forceRefresh = false,
  }) async =>
      (await getStampedDutyPharmacies(
        city: city,
        district: district,
        forceRefresh: forceRefresh,
      ))
          .data;

  Future<Stamped<List<Pharmacy>>> getStampedDutyPharmacies({
    String city = 'Osmaniye',
    String district = 'Duzici',
    bool forceRefresh = false,
  }) async {
    final refreshParams =
        forceRefresh ? {'refresh': '1'} : <String, dynamic>{};

    // 1. Backend API
    if (remoteUrl.trim().isNotEmpty) {
      try {
        final response = await _dio.get(
          remoteUrl,
          queryParameters: {
            'city': city,
            'district': district,
            ...refreshParams,
          },
          options: Options(
            receiveTimeout: const Duration(seconds: 12),
            sendTimeout: const Duration(seconds: 12),
          ),
        );
        final parsed = _parseBackendResponse(response.data);
        if (parsed != null) return parsed;
      } catch (_) {}
    }

    // 2. Kaynak siteden doğrudan çek (Render 403 aldığında mobil cihaz yedek yolu)
    try {
      final direct = await _scrapeFromSource();
      if (direct.data.isNotEmpty) return direct;
    } catch (_) {}

    return Stamped(data: [], fetchedAt: DateTime.now(), source: 'offline');
  }

  Stamped<List<Pharmacy>>? _parseBackendResponse(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    if (raw['ok'] == false) return null;
    final list = raw['pharmacies'] as List<dynamic>? ?? [];
    if (list.isEmpty) return null;
    final items = list
        .map((e) => Pharmacy.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final fetchedAt = _parseDate(raw['fetchedAt']) ?? DateTime.now();
    return Stamped(data: items, fetchedAt: fetchedAt, source: 'backend');
  }

  Future<Stamped<List<Pharmacy>>> _scrapeFromSource() async {
    final response = await _dio.get<String>(
      sourceUrl,
      options: Options(
        responseType: ResponseType.plain,
        headers: const {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123 Mobile Safari/537.36',
          'Accept-Language': 'tr-TR,tr;q=0.9',
          'Accept': 'text/html,application/xhtml+xml',
        },
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
      ),
    );
    final html = response.data ?? '';
    final items = parsePharmaciesFromHtml(html);
    return Stamped(
      data: items,
      fetchedAt: DateTime.now(),
      source: 'eczaneler-gen-tr',
    );
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
    return null;
  }

  static List<Pharmacy> _parseTab(String html, String tabId, String dateLabel) {
    final List<Pharmacy> pharmacies = [];
    final int startIdx = html.indexOf('id="$tabId"');
    if (startIdx == -1) return pharmacies;

    final int tableEndIdx = html.indexOf('</table>', startIdx);
    if (tableEndIdx == -1) return pharmacies;

    final String tabHtml = html.substring(startIdx, tableEndIdx);

    final rangeMatch = RegExp(
      r'''class=["']d-flex alert alert-warning[^>]*>([\s\S]*?)</div>''',
      caseSensitive: false,
    ).firstMatch(tabHtml);
    final dateRange = rangeMatch != null
        ? rangeMatch.group(1)!.replaceAll(RegExp(r'<[^>]+>'), ' ').trim()
        : '';

    final RegExp nameRegExp = RegExp(
      r'''<span class=["']isim["']>([^<]+)</span>''',
      caseSensitive: false,
    );
    final Iterable<RegExpMatch> nameMatches = nameRegExp.allMatches(tabHtml);

    for (final RegExpMatch nameMatch in nameMatches) {
      final String name = nameMatch.group(1)!.trim();
      final int nameIdx = nameMatch.start;

      final String rest = tabHtml.substring(nameIdx);
      final RegExp detailRegExp = RegExp(
        r'''class=['"]col-lg-6['"]>([\s\S]*?)</div>[\s\S]*?class=['"]col-lg-3[^'"]*['"]>([\s\S]*?)</div>''',
        caseSensitive: false,
      );
      final RegExpMatch? detailMatch = detailRegExp.firstMatch(rest);

      if (detailMatch != null) {
        String address = detailMatch.group(1)!;
        address = address
            .replaceAll(RegExp(r'<[^>]+>'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();

        String phone = detailMatch.group(2)!;
        phone = phone
            .replaceAll(RegExp(r'<[^>]+>'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();

        pharmacies.add(Pharmacy(
          name: name,
          address: address,
          phone: phone,
          dateLabel: dateLabel,
          dateRange: dateRange.isNotEmpty ? dateRange : null,
        ));
      }
    }
    return pharmacies;
  }

  /// Resmi sayfanın HTML içeriğinden nöbetçi eczaneleri ayıklayan robust algoritma
  static List<Pharmacy> parsePharmaciesFromHtml(String html) {
    final List<Pharmacy> pharmacies = [];
    try {
      pharmacies.addAll(_parseTab(html, 'nav-bugun', 'Bugün'));
      pharmacies.addAll(_parseTab(html, 'nav-yarin', 'Yarın'));
    } catch (e) {
      // ignore: avoid_print
      print('HTML Ayrıştırma Hatası: $e');
    }
    return pharmacies;
  }
}
