import 'package:dio/dio.dart';
import '../models/city_content.dart';

class DiscoverService {
  final Dio _dio;
  final String remoteUrl;

  DiscoverService(this._dio, {required this.remoteUrl});

  Future<Map<String, dynamic>> getDiscoverData() async {
    try {
      final response = await _dio.get('$remoteUrl/discover');
      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Failed to load discover data');
    } catch (e) {
      // Fallback or rethrow
      rethrow;
    }
  }

  Future<List<ExplorePlace>> searchPlaces(String query) async {
    try {
      final response = await _dio.get('$remoteUrl/discover/search', queryParameters: {'q': query});
      if (response.statusCode == 200) {
        final list = response.data as List;
        return list.map((json) => ExplorePlace.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
