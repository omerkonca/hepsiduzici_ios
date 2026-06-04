class AppConfig {
  AppConfig._();

  /// Canlı backend (Render). Yerel geliştirme için dart-define ile geçersiz kılınabilir.
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'https://hdbackend-vo99.onrender.com',
  );

  static const String baseUrl = '$backendBaseUrl/api';

  static const String cityContentUrl = '$baseUrl/city-content';
  static const String pharmacyUrl = '$baseUrl/pharmacies/duty';
  static const String newsUrl = '$baseUrl/news';
  static const String financeUrl = '$baseUrl/finance';
  static const String fuelUrl = '$baseUrl/fuel';
  static const String eventsUrl = '$baseUrl/events';
  static const String outagesUrl = '$baseUrl/outages';
  static const String roadClosuresUrl = '$baseUrl/road-closures';
  static const String weatherUrl = '$baseUrl/weather';
}
