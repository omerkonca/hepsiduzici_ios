import 'package:dio/dio.dart';
import '../models/finance_quote.dart';
import '../models/stamped_data.dart';

class FinanceService {
  const FinanceService(this._dio, {this.remoteUrl = ''});

  final Dio _dio;
  final String remoteUrl;

  Future<List<FinanceQuote>> getQuotes() async => (await getStampedQuotes()).data;

  Future<Stamped<List<FinanceQuote>>> getStampedQuotes() async {
    if (remoteUrl.trim().isEmpty) {
      return Stamped(data: _mock(), fetchedAt: DateTime.now(), source: 'mock');
    }
    try {
      final res = await _dio.get(
        remoteUrl,
        options: Options(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 12),
        ),
      );
      final data = res.data;
      if (data is Map<String, dynamic>) {
        final list = data['items'] as List<dynamic>? ?? [];
        if (list.isNotEmpty) {
          final items = list
              .map((e) => FinanceQuote.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
          final fetchedAt = _parseDate(data['fetchedAt']) ?? DateTime.now();
          return Stamped(
            data: items,
            fetchedAt: fetchedAt,
            source: data['source'] as String? ?? 'backend',
          );
        }
      }
    } catch (_) {}
    return Stamped(data: _mock(), fetchedAt: DateTime.now(), source: 'mock');
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
    return null;
  }

  static List<FinanceQuote> _mock() {
    return const [
      FinanceQuote(code: 'USD', name: 'Dolar', value: 39.85, changePercent: 0.3),
      FinanceQuote(code: 'EUR', name: 'Euro', value: 43.10, changePercent: -0.2),
      FinanceQuote(code: 'GOLD', name: 'Gram Altın', value: 3050.0, changePercent: 0.8),
      FinanceQuote(code: 'SILVER', name: 'Gram Gümüş', value: 36.5, changePercent: -0.5),
    ];
  }
}
