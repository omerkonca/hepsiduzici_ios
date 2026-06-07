import 'package:dio/dio.dart';
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
    // 1. Try our backend first
    if (remoteUrl.trim().isNotEmpty) {
      try {
        final response = await _dio.get(
          remoteUrl,
          queryParameters: {
            'city': city,
            'district': district,
          },
          options: Options(
            receiveTimeout: const Duration(seconds: 8),
            sendTimeout: const Duration(seconds: 8),
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

    // 2. Fallback: If configured url is not the Render URL, try Render directly
    const productionPharmacyUrl = 'https://hdbackend-vo99.onrender.com/api/pharmacies/duty';
    if (remoteUrl != productionPharmacyUrl) {
      try {
        final response = await _dio.get(
          productionPharmacyUrl,
          queryParameters: {
            'city': city,
            'district': district,
          },
          options: Options(
            receiveTimeout: const Duration(seconds: 10),
            sendTimeout: const Duration(seconds: 10),
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
            return Stamped(data: items, fetchedAt: fetchedAt, source: 'render-backend');
          }
        }
      } catch (_) {}
    }

    // Safety and integrity fallback: do not show non-duty pharmacies if offline
    return Stamped(data: [], fetchedAt: DateTime.now(), source: 'offline');
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
    return null;
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
