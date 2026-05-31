import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import '../models/city_content.dart';

class CityContentService {
  const CityContentService(this._dio, {this.remoteUrl = ''});

  final Dio _dio;
  final String remoteUrl;

  Future<CityContent> loadContent() async {
    if (remoteUrl.trim().isNotEmpty) {
      try {
        final response = await _dio.get(
          remoteUrl,
          options: Options(
            receiveTimeout: const Duration(seconds: 8),
            sendTimeout: const Duration(seconds: 8),
          ),
        );
        if (response.data is Map<String, dynamic>) {
          return CityContent.fromJson(response.data as Map<String, dynamic>);
        }
        if (response.data is String) {
          final decoded = jsonDecode(response.data as String) as Map<String, dynamic>;
          return CityContent.fromJson(decoded);
        }
      } catch (_) {
        // Sessizce local fallback'e düş.
      }
    }

    final jsonString = await rootBundle.loadString('assets/data/city_content.json');
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    return CityContent.fromJson(decoded);
  }
}
