import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../models/obituary_item.dart';
import '../models/stamped_data.dart';

class ObituaryService {
  const ObituaryService(this._dio);

  final Dio _dio;

  Future<List<ObituaryItem>> getObituaries({bool forceRefresh = false}) async =>
      (await getStampedObituaries(forceRefresh: forceRefresh)).data;

  Future<Stamped<List<ObituaryItem>>> getStampedObituaries({
    bool forceRefresh = false,
  }) async {
    const productionUrl = 'https://hdbackend-vo99.onrender.com/api/obituaries';
    final urls = <String>{
      AppConfig.obituariesUrl,
      if (AppConfig.backendBaseUrl != 'https://hdbackend-vo99.onrender.com')
        productionUrl,
    };

    for (final url in urls) {
      try {
        final response = await _dio.get<Map<String, dynamic>>(
          url,
          queryParameters: forceRefresh ? {'refresh': '1'} : null,
          options: Options(
            connectTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 20),
          ),
        );
        final data = response.data;
        if (data == null || data['ok'] != true) continue;
        final list = data['items'] as List<dynamic>? ?? [];
        final items = list
            .map((e) => _itemFromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        return Stamped(
          data: items,
          fetchedAt: DateTime.tryParse(data['fetchedAt'] as String? ?? '') ??
              DateTime.now(),
          source: 'backend',
        );
      } catch (_) {}
    }

    return Stamped(
      data: const <ObituaryItem>[],
      fetchedAt: DateTime.now(),
      source: 'offline',
    );
  }

  ObituaryItem _itemFromJson(Map<String, dynamic> json) {
    final scopeRaw = (json['scope'] as String? ?? '').toLowerCase();
    return ObituaryItem(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? json['full_name'] as String? ?? '',
      deathDate: DateTime.tryParse(
            json['deathDate'] as String? ?? json['death_date'] as String? ?? '',
          ) ??
          DateTime.now(),
      scope: scopeRaw.contains('duzici')
          ? ObituaryScope.duzici
          : ObituaryScope.osmaniye,
      detail: json['detail'] as String? ?? '',
      district: json['district'] as String? ?? '',
      neighborhood: json['neighborhood'] as String? ?? '',
      condolenceAddress: json['condolenceAddress'] as String? ??
          json['condolence_address'] as String? ??
          '',
      burialPlace: json['burialPlace'] as String? ??
          json['burial_place'] as String? ??
          '',
      age: json['age'] is int ? json['age'] as int : int.tryParse('${json['age']}'),
      source: json['source'] as String? ?? '',
      sourceUrl: json['sourceUrl'] as String? ?? json['source_url'] as String? ?? '',
      detailUrl: json['detailUrl'] as String? ?? json['detail_url'] as String? ?? '',
    );
  }
}
