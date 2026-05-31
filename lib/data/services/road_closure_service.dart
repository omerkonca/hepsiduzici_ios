import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

import '../models/road_closure.dart';
import '../models/stamped_data.dart';

class RoadClosureService {
  RoadClosureService(this._dio, {required this.remoteUrl});

  final Dio _dio;
  final String remoteUrl;

  Future<Stamped<List<RoadClosure>>> getStampedRoadClosures({bool forceRefresh = false}) async {
    try {
      final response = await _dio.get(
        remoteUrl,
        queryParameters: forceRefresh ? {'refresh': '1'} : null,
      );
      if (response.data['ok'] == true) {
        final list = (response.data['items'] as List)
            .map((e) => RoadClosure.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        return Stamped(
          data: _normalizeList(list),
          fetchedAt: DateTime.parse(response.data['fetchedAt'] as String),
        );
      }
      throw Exception(response.data['message'] ?? 'Kapalı yol verisi alınamadı.');
    } catch (_) {
      return _loadLocalFallback();
    }
  }

  Future<Stamped<List<RoadClosure>>> _loadLocalFallback() async {
    final raw = await rootBundle.loadString('assets/data/city_content.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final services = json['services'] as Map<String, dynamic>? ?? {};
    final items = (services['roadClosures'] as List<dynamic>? ?? [])
        .map((e) => RoadClosure.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return Stamped(data: _normalizeList(items), fetchedAt: DateTime.now());
  }

  /// Bitiş tarihi geçmiş "Devam Ediyor" kayıtlarını tamamlandı say.
  static List<RoadClosure> _normalizeList(List<RoadClosure> items) {
    return items.map((c) {
      if (!c.isActive && c.status.toLowerCase().contains('devam')) {
        return RoadClosure(
          id: c.id,
          title: c.title,
          subtitle: c.subtitle,
          status: 'Tamamlandı',
          reason: c.reason,
          roadCode: c.roadCode,
          address: c.address,
          lat: c.lat,
          lng: c.lng,
          alternativeRoute: c.alternativeRoute,
          severity: c.severity,
          startAt: c.startAt,
          endAt: c.endAt,
          source: c.source,
          announcementUrl: c.announcementUrl,
          kind: c.kind,
        );
      }
      return c;
    }).toList();
  }
}
