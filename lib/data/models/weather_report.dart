import 'weather_info.dart';

class DailyForecast {
  const DailyForecast({
    required this.date,
    required this.conditionText,
    required this.conditionIcon,
    required this.conditionCode,
    required this.maxTemp,
    required this.minTemp,
  });

  final DateTime date;
  final String conditionText;
  final String conditionIcon;
  final int conditionCode;
  final double maxTemp;
  final double minTemp;

  factory DailyForecast.fromBackend(Map<String, dynamic> json) {
    final condition = json['condition'] as Map<String, dynamic>? ?? {};
    return DailyForecast(
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      conditionText: condition['text'] as String? ?? '',
      conditionIcon: condition['icon'] as String? ?? '',
      conditionCode: json['code'] as int? ?? 0,
      maxTemp: (json['maxTemp'] as num?)?.toDouble() ?? 0,
      minTemp: (json['minTemp'] as num?)?.toDouble() ?? 0,
    );
  }
}

class WeatherReport {
  const WeatherReport({
    required this.current,
    required this.daily,
    required this.location,
  });

  final WeatherInfo current;
  final List<DailyForecast> daily;
  final String location;

  factory WeatherReport.fromBackend(Map<String, dynamic> json) {
    return WeatherReport(
      current: WeatherInfo.fromBackend(json['current'] as Map<String, dynamic>? ?? {}),
      daily: (json['forecast'] as List<dynamic>? ?? [])
          .map((e) => DailyForecast.fromBackend(e as Map<String, dynamic>))
          .toList(),
      location: json['location'] as String? ?? 'Düziçi',
    );
  }
}
