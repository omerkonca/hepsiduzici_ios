import 'package:dio/dio.dart';
import '../models/city_content.dart';
import 'place_photo_service.dart';

class PlaceMeta {
  const PlaceMeta({
    required this.parking,
    required this.restroom,
    required this.entryFee,
    this.entryFeeNote,
    this.mapUrl,
    this.lat,
    this.lng,
    this.source,
  });

  final String parking;
  final String restroom;
  final String entryFee;
  final String? entryFeeNote;
  final String? mapUrl;
  final double? lat;
  final double? lng;
  final String? source;

  factory PlaceMeta.fromJson(Map<String, dynamic> json) {
    return PlaceMeta(
      parking: json['parking'] as String? ?? 'bilinmiyor',
      restroom: json['restroom'] as String? ?? 'bilinmiyor',
      entryFee: json['entryFee'] as String? ?? 'bilinmiyor',
      entryFeeNote: json['entryFeeNote'] as String?,
      mapUrl: json['mapUrl'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      source: json['source'] as String?,
    );
  }
}

class PlaceMetaService {
  PlaceMetaService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<PlaceMeta?> fetch(ExplorePlace place) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        PlacePhotoService.metaUrl(place),
        options: Options(
          receiveTimeout: const Duration(seconds: 25),
          sendTimeout: const Duration(seconds: 15),
        ),
      );
      if (res.data?['ok'] != true) return null;
      final data = res.data!['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      return PlaceMeta.fromJson(data);
    } catch (_) {
      return null;
    }
  }
}
