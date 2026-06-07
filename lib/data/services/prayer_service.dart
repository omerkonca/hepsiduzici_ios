import 'package:dio/dio.dart';
import '../models/prayer_times.dart';
import '../models/stamped_data.dart';

class PrayerService {
  PrayerService(this._dio, {this.remoteUrl = ''});

  final Dio _dio;
  final String remoteUrl;

  Future<PrayerTimes> getTodayTimings() async =>
      (await getStampedTimings()).data;

  Future<Stamped<PrayerTimes>> getStampedTimings() async {
    // 1. Try backend first
    if (remoteUrl.trim().isNotEmpty) {
      try {
        final response = await _dio.get(
          remoteUrl,
          options: Options(
            connectTimeout: const Duration(seconds: 4),
            receiveTimeout: const Duration(seconds: 5),
          ),
        );
        if (response.data != null && response.data['ok'] == true) {
          final data = response.data['data'] as Map<String, dynamic>?;
          if (data != null) {
            return Stamped(
              data: PrayerTimes.fromJson(data),
              fetchedAt: DateTime.now(),
              source: 'backend',
            );
          }
        }
      } catch (_) {}
    }

    // 2. Fallback to direct Aladhan API
    try {
      final response = await _dio.get(
        'https://api.aladhan.com/v1/timingsByCity',
        queryParameters: {
          'city': 'Duzici',
          'country': 'Turkey',
          'method': 13,
        },
      );
      final data = response.data['data'] as Map<String, dynamic>?;
      if (data != null) {
        return Stamped(
          data: PrayerTimes.fromJson(data),
          fetchedAt: DateTime.now(),
          source: 'aladhan',
        );
      }
    } catch (_) {}

    return Stamped(data: _mockPrayerTimes(), fetchedAt: DateTime.now(), source: 'mock');
  }

  static PrayerTimes _mockPrayerTimes() {
    return const PrayerTimes(
      imsak: '05:45',
      gunes: '07:15',
      ogle: '12:35',
      ikindi: '15:40',
      aksam: '18:15',
      yatsi: '19:45',
    );
  }
}
