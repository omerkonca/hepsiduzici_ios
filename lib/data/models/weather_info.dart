class WeatherInfo {
  const WeatherInfo({
    required this.temperature,
    required this.conditionCode,
    this.isDay = true,
    this.windSpeed,
    this.windGust,
    this.relativeHumidity,
    this.conditionText = '',
    this.conditionIcon = '',
  });

  final double temperature;
  final int conditionCode;
  final bool isDay;
  final double? windSpeed;
  final double? windGust;
  final int? relativeHumidity;
  final String conditionText;
  final String conditionIcon;
  
  String get conditionLabel => conditionText;

  factory WeatherInfo.fromBackend(Map<String, dynamic> json) {
    final condition = json['condition'] as Map<String, dynamic>? ?? {};
    return WeatherInfo(
      temperature: (json['temp'] as num?)?.toDouble() ?? 0,
      conditionCode: json['code'] as int? ?? 0,
      isDay: json['isDay'] as bool? ?? true,
      windSpeed: (json['windSpeed'] as num?)?.toDouble(),
      relativeHumidity: json['humidity'] as int?,
      conditionText: condition['text'] as String? ?? '',
      conditionIcon: condition['icon'] as String? ?? '',
    );
  }
}
