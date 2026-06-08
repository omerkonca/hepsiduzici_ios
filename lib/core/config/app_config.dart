class AppConfig {
  AppConfig._();

  static const String supabaseUrl = 'https://duehxbdlpwvbpqfjyjai.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_k-EcjTqZe_4kmwWLIEJX3Q_3cHt_szO';

  static const String _envBaseUrl = String.fromEnvironment('BACKEND_BASE_URL');

  /// Canlı backend (Render). Yerel geliştirme için --dart-define=BACKEND_BASE_URL=...
  static String get backendBaseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }
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
  static String get prayersUrl => '$baseUrl/prayers';
  static String get obituariesUrl => '$baseUrl/obituaries';

  /// Google Play Haber politikası — yayıncı iletişim bilgileri
  static const String publisherName = 'Ömer Faruk Konca';
  static const String contactEmail = 'hepsiduzici@gmail.com';
  static String get contactPageUrl => '$backendBaseUrl/iletisim.html';
  static String get privacyPolicyUrl => '$backendBaseUrl/gizlilik-politikasi.html';
}
