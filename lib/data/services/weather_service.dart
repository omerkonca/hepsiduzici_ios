import 'package:dio/dio.dart';
import '../../core/config/app_config.dart';
import '../models/stamped_data.dart';
import '../models/weather_info.dart';
import '../models/weather_report.dart';

class WeatherService {
  WeatherService(this._dio);

  final Dio _dio;

  Future<Stamped<WeatherReport>> getStampedWeatherReport() async {
    // 1. Try local/configured url first with short timeout
    try {
      final response = await _dio.get(
        AppConfig.weatherUrl,
        options: Options(
          connectTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );
      
      if (response.data != null && response.data['ok'] == true) {
        final data = response.data as Map<String, dynamic>;
        final report = WeatherReport.fromBackend(data);
        return Stamped(
          data: report,
          fetchedAt: DateTime.now(),
          source: 'backend-meteo',
        );
      }
    } catch (_) {}

    // 2. Fallback: If configured url is not Render, try Render directly
    const productionWeatherUrl = 'https://hdbackend-vo99.onrender.com/api/weather';
    if (AppConfig.weatherUrl != productionWeatherUrl) {
      try {
        final response = await _dio.get(
          productionWeatherUrl,
          options: Options(
            connectTimeout: const Duration(seconds: 6),
            receiveTimeout: const Duration(seconds: 8),
          ),
        );
        if (response.data != null && response.data['ok'] == true) {
          final data = response.data as Map<String, dynamic>;
          final report = WeatherReport.fromBackend(data);
          return Stamped(
            data: report,
            fetchedAt: DateTime.now(),
            source: 'render-meteo',
          );
        }
      } catch (_) {}
    }

    // 3. Last fallback: return mock weather data instead of throwing exception
    return Stamped(
      data: _mockWeatherReport(),
      fetchedAt: DateTime.now(),
      source: 'mock',
    );
  }

  static WeatherReport _mockWeatherReport() {
    return WeatherReport(
      current: const WeatherInfo(
        temperature: 24.0,
        conditionCode: 3,
        isDay: true,
        windSpeed: 10.0,
        relativeHumidity: 60,
        conditionText: 'Bulutlu',
        conditionIcon: 'cloud',
      ),
      daily: [
        DailyForecast(
          date: DateTime.now(),
          conditionText: 'Bulutlu',
          conditionIcon: 'cloud',
          conditionCode: 3,
          maxTemp: 26.0,
          minTemp: 16.0,
        ),
        DailyForecast(
          date: DateTime.now().add(const Duration(days: 1)),
          conditionText: 'Güneşli',
          conditionIcon: 'clear',
          conditionCode: 0,
          maxTemp: 28.0,
          minTemp: 18.0,
        ),
        DailyForecast(
          date: DateTime.now().add(const Duration(days: 2)),
          conditionText: 'Parçalı Bulutlu',
          conditionIcon: 'partly_cloudy',
          conditionCode: 2,
          maxTemp: 27.0,
          minTemp: 17.0,
        ),
      ],
      location: 'Düziçi',
    );
  }
}
