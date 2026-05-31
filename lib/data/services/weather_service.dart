import 'package:dio/dio.dart';
import '../../core/config/app_config.dart';
import '../models/stamped_data.dart';
import '../models/weather_report.dart';

class WeatherService {
  WeatherService(this._dio);

  final Dio _dio;

  Future<Stamped<WeatherReport>> getStampedWeatherReport() async {
    try {
      final response = await _dio.get(AppConfig.weatherUrl);
      
      if (response.data == null || response.data['ok'] != true) {
        throw Exception('Backend weather error');
      }

      final data = response.data as Map<String, dynamic>;
      final report = WeatherReport.fromBackend(data);

      return Stamped(
        data: report,
        fetchedAt: DateTime.now(),
        source: 'backend-meteo',
      );
    } catch (e) {
      // Fallback or rethrow
      rethrow;
    }
  }
}
