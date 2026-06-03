class AppConfig {
  AppConfig._();

  /// Remote icerik endpoint'i.
  static const String cityContentUrl = 'http://192.168.1.104:5050/api/city-content';

  /// Nobetci eczane endpoint'i.
  static const String pharmacyUrl = 'http://192.168.1.104:5050/api/pharmacies/duty';

  /// Haber endpoint'i.
  static const String newsUrl = 'http://192.168.1.104:5050/api/news';

  /// Backend base URL.
  static const String backendBaseUrl = 'http://192.168.1.104:5050';

  /// Finans endpoint'i.
  static const String financeUrl = 'http://192.168.1.104:5050/api/finance';

  /// Akaryakıt fiyatlari endpoint'i.
  static const String fuelUrl = 'http://192.168.1.104:5050/api/fuel';

  /// Etkinlikler endpoint'i.
  static const String eventsUrl = 'http://192.168.1.104:5050/api/events';

  /// Kesintiler endpoint'i.
  static const String outagesUrl = 'http://192.168.1.104:5050/api/outages';

  /// Kapalı yollar endpoint'i.
  static const String roadClosuresUrl = 'http://192.168.1.104:5050/api/road-closures';

  /// Hava durumu endpoint'i.
  static const String weatherUrl = 'http://192.168.1.104:5050/api/weather';

  /// API Base URL
  static const String baseUrl = 'http://192.168.1.104:5050/api';
}
