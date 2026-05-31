import '../../core/config/app_config.dart';
import '../models/city_content.dart';

class PlacePhotoService {
  PlacePhotoService._();

  static const String _fallback =
      'https://images.unsplash.com/photo-1501785888041-af3ef285b470?q=80&w=800';

  /// Backend: OpenStreetMap + Wikipedia/Wikimedia (ücretsiz, API anahtarı yok).
  static String heroUrl(ExplorePlace place, {int maxHeight = 800}) {
    final q = Uri.encodeComponent(place.name);
    if (place.lat != null && place.lng != null) {
      return '${AppConfig.backendBaseUrl}/api/places/photo?query=$q&lat=${place.lat}&lng=${place.lng}';
    }
    return '${AppConfig.backendBaseUrl}/api/places/photo?query=$q';
  }

  static String metaUrl(ExplorePlace place) {
    final q = Uri.encodeComponent(place.name);
    if (place.lat != null && place.lng != null) {
      return '${AppConfig.baseUrl}/places/meta?query=$q&lat=${place.lat}&lng=${place.lng}';
    }
    return '${AppConfig.baseUrl}/places/meta?query=$q';
  }

  static String mapsUrl(ExplorePlace place) {
    if (place.lat != null && place.lng != null) {
      return 'https://www.openstreetmap.org/#map=17/${place.lat}/${place.lng}';
    }
    final q = Uri.encodeComponent('${place.name} Düziçi Osmaniye');
    return 'https://www.openstreetmap.org/search?query=$q';
  }

  static String fallbackImage(ExplorePlace place) {
    final local = place.imageUrl?.trim();
    if (local != null && local.isNotEmpty) return local;
    return _fallback;
  }
}
