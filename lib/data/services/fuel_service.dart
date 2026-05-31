import 'package:dio/dio.dart';

import '../models/fuel_price.dart';
import '../models/stamped_data.dart';

class FuelService {
  const FuelService(this._dio, {this.remoteUrl = ''});

  final Dio _dio;
  final String remoteUrl;

  Future<List<FuelPrice>> getPrices({bool forceRefresh = false}) async =>
      (await getStampedPrices(forceRefresh: forceRefresh)).data;

  Future<Stamped<List<FuelPrice>>> getStampedPrices({bool forceRefresh = false}) async {
    if (remoteUrl.trim().isEmpty) {
      return Stamped(data: _mock(), fetchedAt: DateTime.now(), source: 'mock');
    }
    try {
      final res = await _dio.get(
        remoteUrl,
        queryParameters: forceRefresh ? {'refresh': '1'} : null,
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
              .map((e) => FuelPrice.fromJson(Map<String, dynamic>.from(e as Map)))
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

  static List<FuelPrice> _mock() {
    return const [
      FuelPrice(code: 'GASOLINE', name: 'Benzin', price: 65.40),
      FuelPrice(code: 'DIESEL', name: 'Motorin', price: 73.47),
      FuelPrice(code: 'LPG', name: 'LPG', price: 35.94),
    ];
  }
}
