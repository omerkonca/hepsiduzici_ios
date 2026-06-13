import '../../core/utils/media_url_resolver.dart';
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

  static const Map<String, String> _approvedByPlaceName = {
    'düziçi ulu cami':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9a/Sabanc%C4%B1_Merkez_Camii.jpg/960px-Sabanc%C4%B1_Merkez_Camii.jpg',
    'kurtuluş çarşı ve yeraltı camii':
        'https://images.unsplash.com/photo-1542810634-71277d95dcbb?w=960',
    'taş köprü (fettahoğluları)':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c2/Stone_Bridge_%28Adana%29.jpg/960px-Stone_Bridge_%28Adana%29.jpg',
    'karasu şelalesi': 'assets/images/karasu_selalesi.jpg',
    'yeşil şelalesi': 'assets/images/yesil_selalesi.jpg',
    'kocakesme şelalesi': 'assets/images/kocakesme_selalesi.jpg',
    'delioğlan şelalesi': 'assets/images/delioglan_selalesi.jpg',
    'uyuz pınarı': 'assets/images/uyuz_pinari.jpg',
    'harun reşit kalesi': 'assets/images/harun_resit.jpg',
    'karatepe-aslantaş açık hava müzesi': 'assets/images/karatepe.jpg',
    'karatepe-aslantaş açık hava müzesi ve milli parkı': 'assets/images/karatepe.jpg',
    'kastabala (hierapolis) antik kenti': 'assets/images/kastabala.jpg',
    'toprakkale kalesi': 'assets/images/toprakkale.jpg',
    "deve mağarası, deve kanyonu ve adem'in şelalesi (kısık kanyonu rotası)": 'assets/images/deve_kanyonu.jpg',
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
      return MediaUrlResolver.resolve(raw);
    }

    if (raw == null || raw.isEmpty) {
      return approvedImageFor(place);
    }

    // Admin panelinden yüklenen görseller her zaman öncelikli.
    if (raw.contains('cloudinary.com') ||
        raw.contains('/uploads/') ||
        raw.contains('/uploads') ||
        raw.startsWith('uploads/')) {
      return MediaUrlResolver.resolve(raw);
    }

    final approved = approvedImageFor(place);
    if (approved != null) return approved;

    if (raw.startsWith('assets/')) return raw;
    return isTrustedNetworkUrl(raw) ? raw : null;
  }
}
