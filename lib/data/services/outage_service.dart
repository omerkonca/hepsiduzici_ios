import 'package:dio/dio.dart';
import '../models/city_content.dart';
import '../models/stamped_data.dart';

class OutageService {
  final Dio _dio;
  final String remoteUrl;

  OutageService(this._dio, {required this.remoteUrl});

  Future<Stamped<List<OutageItem>>> getStampedOutages() async {
    // 1. Try local/configured remoteUrl first with short timeout
    if (remoteUrl.trim().isNotEmpty) {
      try {
        final response = await _dio.get(
          remoteUrl,
          options: Options(
            connectTimeout: const Duration(seconds: 3),
            receiveTimeout: const Duration(seconds: 4),
          ),
        );
        if (response.data != null && response.data['ok'] == true) {
          final list = (response.data['items'] as List)
              .map((e) => OutageItem.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
          return Stamped(
            data: list,
            fetchedAt: response.data['fetchedAt'] != null
                ? DateTime.tryParse(response.data['fetchedAt'] as String) ?? DateTime.now()
                : DateTime.now(),
            source: 'backend',
          );
        }
      } catch (_) {}
    }

    // 2. Fallback: If configured url is not the Render URL, try Render directly
    const productionOutagesUrl = 'https://hdbackend-vo99.onrender.com/api/outages';
    if (remoteUrl != productionOutagesUrl) {
      try {
        final response = await _dio.get(
          productionOutagesUrl,
          options: Options(
            connectTimeout: const Duration(seconds: 6),
            receiveTimeout: const Duration(seconds: 8),
          ),
        );
        if (response.data != null && response.data['ok'] == true) {
          final list = (response.data['items'] as List)
              .map((e) => OutageItem.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
          return Stamped(
            data: list,
            fetchedAt: response.data['fetchedAt'] != null
                ? DateTime.tryParse(response.data['fetchedAt'] as String) ?? DateTime.now()
                : DateTime.now(),
            source: 'render-backend',
          );
        }
      } catch (_) {}
    }

    // 3. Last fallback: return empty list
    return Stamped(
      data: const <OutageItem>[],
      fetchedAt: DateTime.now(),
      source: 'offline',
    );
  }
}
