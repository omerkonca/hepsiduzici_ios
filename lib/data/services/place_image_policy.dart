import '../models/city_content.dart';

/// Görsel kalitesi için onaylı görsel ve alan adı politikası.
class PlaceImagePolicy {
  PlaceImagePolicy._();

  static const Set<String> _trustedHosts = {
    'upload.wikimedia.org',
    'images.unsplash.com',
    'i.ytimg.com',
    'yt3.googleusercontent.com',
  };

  /// Sorunlu veya yanlış eşleşmeye açık yerler için elle onaylı görseller.
  static const Map<String, String> _approvedByPlaceName = {
    'düziçi ulu cami':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9a/Sabanc%C4%B1_Merkez_Camii.jpg/960px-Sabanc%C4%B1_Merkez_Camii.jpg',
    'kurtuluş çarşı ve yeraltı camii':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b1/Osmaniye_Market_in_2010_1919.jpg/960px-Osmaniye_Market_in_2010_1919.jpg',
    'taş köprü (fettahoğluları)':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c2/Stone_Bridge_%28Adana%29.jpg/960px-Stone_Bridge_%28Adana%29.jpg',
    'karasu şelalesi': 'assets/images/karasu_selalesi.jpg',
  };

  static String? approvedImageFor(ExplorePlace place) {
    final key = place.name.trim().toLowerCase();
    return _approvedByPlaceName[key];
  }

  static bool isTrustedNetworkUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return false;
    return _trustedHosts.contains(uri.host.toLowerCase());
  }

  /// İçerikte gelen görseli sadece güvenilir host ise kabul eder.
  static String? safeContentImage(ExplorePlace place) {
    final raw = place.imageUrl?.trim();

    // Web Admin Panelinden yüklenen resimler (Cloudinary veya Yerel Upload) her zaman önceliklidir.
    if (raw != null && raw.isNotEmpty && (raw.contains('cloudinary.com') || raw.contains('/uploads/') || raw.contains(':5050'))) {
      return raw;
    }

    final approved = approvedImageFor(place);
    if (approved != null) return approved;

    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('assets/')) return raw;
    return isTrustedNetworkUrl(raw) ? raw : null;
  }
}
