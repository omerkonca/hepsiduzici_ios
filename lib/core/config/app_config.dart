import 'package:flutter/foundation.dart';
import 'dart:io';

class AppConfig {
  AppConfig._();

  static const String _envBaseUrl = String.fromEnvironment('BACKEND_BASE_URL');

  /// Canlı backend (Render) veya geliştirme ortamı için yerel sunucu.
  static String get backendBaseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }
    
    // Geliştirme (debug) modunda yerel backend'e otomatik yönlendir
    if (kDebugMode) {
      if (kIsWeb) {
        return 'http://localhost:5050';
      }
      try {
        if (Platform.isAndroid) {
          return 'http://10.0.2.2:5050'; // Android Emulator için local IP
        }
        if (Platform.isIOS || Platform.isMacOS) {
          return 'http://localhost:5050'; // iOS Simulator için local IP
        }
      } catch (_) {
        // Platform tespit hatası (örn. web üzerinde Platform kullanımı)
      }
      return 'http://localhost:5050';
    }

    // Canlı (Production) Render sunucusu adresi
    return 'https://hdbackend-vo99.onrender.com';
  }

  static String get baseUrl => '$backendBaseUrl/api';

  static String get cityContentUrl => '$baseUrl/city-content';
  static String get pharmacyUrl => '$baseUrl/pharmacies/duty';
  static String get newsUrl => '$baseUrl/news';
  static String get financeUrl => '$baseUrl/finance';
  static String get fuelUrl => '$baseUrl/fuel';
  static String get eventsUrl => '$baseUrl/events';
  static String get outagesUrl => '$baseUrl/outages';
  static String get roadClosuresUrl => '$baseUrl/road-closures';
  static String get weatherUrl => '$baseUrl/weather';
}
