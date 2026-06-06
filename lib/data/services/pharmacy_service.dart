import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pharmacy.dart';
import '../models/stamped_data.dart';

class PharmacyService {
  const PharmacyService(this._dio, {this.remoteUrl = ''});

  final Dio _dio;
  final String remoteUrl;

  Future<List<Pharmacy>> getDutyPharmacies({
    String city = 'Osmaniye',
    String district = 'Duzici',
  }) async =>
      (await getStampedDutyPharmacies(city: city, district: district)).data;

  Future<Stamped<List<Pharmacy>>> getStampedDutyPharmacies({
    String city = 'Osmaniye',
    String district = 'Duzici',
  }) async {
    // 1. Birincil Yol: Cihazdan doğrudan resmi web sitesini kazıma (Ultra Hızlı ve Canlı)
    final String slugCity = _slugify(city);
    final String slugDistrict = _slugify(district);
    final String sourceUrl = 'https://www.eczaneler.gen.tr/nobetci-$slugCity-$slugDistrict';

    try {
      final response = await _dio.get(
        sourceUrl,
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
            'Accept-Language': 'tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7',
          },
          receiveTimeout: const Duration(seconds: 8),
          sendTimeout: const Duration(seconds: 8),
        ),
      );

      if (response.statusCode == 200 && response.data is String) {
        final List<Pharmacy> scraped = parsePharmaciesFromHtml(response.data as String);
        if (scraped.isNotEmpty) {
          return Stamped(
            data: scraped,
            fetchedAt: DateTime.now(),
            source: 'web_scrape',
          );
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Direct scrape failed, trying backend: $e');
    }

    // 2. İkincil Yol: Supabase Cache (Serverless & Ultra Hızlı)
    try {
      final supabase = Supabase.instance.client;
      final res = await supabase.from('pharmacies').select();
      if (res.isNotEmpty) {
        final items = res.map((row) => Pharmacy.fromJson({
          'name': row['name'],
          'address': row['address'],
          'phone': row['phone'],
        })).toList();
        return Stamped(
          data: items,
          fetchedAt: DateTime.tryParse(res.first['fetched_at'] as String) ?? DateTime.now(),
          source: 'supabase',
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('Supabase direct pharmacy read failed: $e. Falling back to HTTP...');
    }

    // 3. Üçüncül Yol: Kendi Backend Servisimizden Çekim (Yedek HTTP)
    if (remoteUrl.trim().isNotEmpty) {
      try {
        final response = await _dio.get(
          remoteUrl,
          queryParameters: {
            'city': city,
            'district': district,
          },
          options: Options(
            receiveTimeout: const Duration(seconds: 15),
            sendTimeout: const Duration(seconds: 15),
          ),
        );
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final list = data['pharmacies'] as List<dynamic>? ?? [];
          if (list.isNotEmpty) {
            final items = list
                .map((e) => Pharmacy.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList();
            final fetchedAt = _parseDate(data['fetchedAt']) ?? DateTime.now();
            return Stamped(data: items, fetchedAt: fetchedAt, source: 'backend');
          }
        }
      } catch (_) {}
    }

    // 3. Üçüncül Yol: NosyAPI (Eğer varsa)
    try {
      final response = await _dio.get(
        'https://api.nosyapi.com/pharmacies-on-duty',
        queryParameters: {'city': city, 'county': district},
      );
      final list = response.data as List<dynamic>?;
      if (list != null && list.isNotEmpty) {
        final items = list
            .map((e) => Pharmacy.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        return Stamped(data: items, fetchedAt: DateTime.now(), source: 'nosyapi');
      }
    } catch (_) {}

    // Güvenlik ve dürüstlük açısından, nöbetçi olmayan hiçbir eczane listelenmemelidir.
    return Stamped(data: [], fetchedAt: DateTime.now(), source: 'offline');
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
    return null;
  }

  /// Eczaneler sitesinin URL formatı için Türkçe karakterleri temizleme yardımı
  static String _slugify(String input) {
    return input
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(' ', '-')
        .replaceAll(RegExp(r'[^a-z0-9\-]'), '');
  }

  /// Resmi sayfanın HTML içeriğinden nöbetçi eczaneleri ayıklayan robust algoritma
  static List<Pharmacy> parsePharmaciesFromHtml(String html) {
    final List<Pharmacy> pharmacies = [];
    try {
      final int bugunStartIdx = html.indexOf('id="nav-bugun"');
      if (bugunStartIdx == -1) return pharmacies;

      final int tableEndIdx = html.indexOf('</table>', bugunStartIdx);
      if (tableEndIdx == -1) return pharmacies;

      final String bugunHtml = html.substring(bugunStartIdx, tableEndIdx);

      // Eczane isimlerini bul
      final RegExp nameRegExp = RegExp(r'''<span class=["']isim["']>([^<]+)</span>''', caseSensitive: false);
      final Iterable<RegExpMatch> nameMatches = nameRegExp.allMatches(bugunHtml);

      for (final RegExpMatch nameMatch in nameMatches) {
        final String name = nameMatch.group(1)!.trim();
        final int nameIdx = nameMatch.start;

        final String rest = bugunHtml.substring(nameIdx);
        final RegExp detailRegExp = RegExp(
          r'''class=['"]col-lg-6['"]>([\s\S]*?)</div>[\s\S]*?class=['"]col-lg-3[^'"]*['"]>([\s\S]*?)</div>''',
          caseSensitive: false,
        );
        final RegExpMatch? detailMatch = detailRegExp.firstMatch(rest);

        if (detailMatch != null) {
          String address = detailMatch.group(1)!;
          address = address.replaceAll(RegExp(r'<[^>]+>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

          String phone = detailMatch.group(2)!;
          phone = phone.replaceAll(RegExp(r'<[^>]+>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

          pharmacies.add(Pharmacy(
            name: name,
            address: address,
            phone: phone,
          ));
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('HTML Ayrıştırma Hatası: $e');
    }
    return pharmacies;
  }
}
