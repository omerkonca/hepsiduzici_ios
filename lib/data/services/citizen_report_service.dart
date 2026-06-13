import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/config/app_config.dart';

enum CitizenReportCategory {
  problem('problem', 'Sorun / Arıza', 'Yol, altyapı, çevre vb.'),
  suggestion('suggestion', 'Öneri', 'Uygulama veya şehir için fikir'),
  tip('tip', 'Tavsiye', 'Faydalı bilgi paylaşımı'),
  other('other', 'Diğer', 'Genel bildirim');

  const CitizenReportCategory(this.apiValue, this.title, this.subtitle);

  final String apiValue;
  final String title;
  final String subtitle;
}

class CitizenReportService {
  CitizenReportService(this._dio);

  final Dio _dio;

  Future<String> submit({
    required CitizenReportCategory category,
    required String message,
    String? contactName,
    String? contactEmail,
    List<File> photos = const [],
  }) async {
    final info = await PackageInfo.fromPlatform();
    final formData = FormData.fromMap({
      'category': category.apiValue,
      'message': message.trim(),
      if (contactName != null && contactName.trim().isNotEmpty)
        'contactName': contactName.trim(),
      if (contactEmail != null && contactEmail.trim().isNotEmpty)
        'contactEmail': contactEmail.trim(),
      'platform': defaultTargetPlatform.name,
      'appVersion': info.version,
    });

    for (var i = 0; i < photos.length; i++) {
      final file = photos[i];
      final name = file.path.split(Platform.pathSeparator).last;
      formData.files.add(
        MapEntry(
          'photos',
          await MultipartFile.fromFile(file.path, filename: name),
        ),
      );
    }

    final endpoints = <String>[
      '${AppConfig.backendBaseUrl}/api/citizen-reports',
      if (AppConfig.backendBaseUrl != 'https://hdbackend-vo99.onrender.com')
        'https://hdbackend-vo99.onrender.com/api/citizen-reports',
    ];

    Object? lastError;
    for (final url in endpoints) {
      try {
        final res = await _dio.post<Map<String, dynamic>>(
          url,
          data: formData,
          options: Options(
            contentType: 'multipart/form-data',
            sendTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(seconds: 30),
            validateStatus: (s) => true,
          ),
        );
        final data = res.data;
        if (res.statusCode == 200 && data?['ok'] == true) {
          return data?['message'] as String? ?? 'Bildiriminiz alındı.';
        }
        lastError = data?['message'] ?? 'Gönderilemedi (${res.statusCode})';
      } catch (e) {
        lastError = e;
      }
    }

    throw Exception(lastError?.toString() ?? 'Bildirim gönderilemedi.');
  }
}
