import 'package:dio/dio.dart';
import '../models/city_content.dart';
import '../models/stamped_data.dart';

class OutageService {
  final Dio _dio;
  final String remoteUrl;

  OutageService(this._dio, {required this.remoteUrl});

  Future<Stamped<List<OutageItem>>> getStampedOutages() async {
    try {
      final response = await _dio.get(remoteUrl);
      if (response.data['ok'] == true) {
        final list = (response.data['items'] as List)
            .map((e) => OutageItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        return Stamped(
          data: list,
          fetchedAt: DateTime.parse(response.data['fetchedAt']),
        );
      }
      throw Exception(response.data['message'] ?? 'Kesinti verisi alinamadi.');
    } catch (e) {
      rethrow;
    }
  }
}
