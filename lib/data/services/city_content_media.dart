import '../../core/utils/media_url_resolver.dart';
import '../models/city_content.dart';

/// City content içindeki medya yollarını backend taban URL'si ile tamamlar.
CityContent normalizeCityContentMedia(CityContent content) {
  return CityContent(
    serviceTiles: content.serviceTiles,
    healthFacilities: content.healthFacilities,
    veterinarians: content.veterinarians,
    emergencyContacts: content.emergencyContacts,
    municipalityUnits: content.municipalityUnits,
    exploreCategories: content.exploreCategories
        .map((c) => ExploreCategoryItem(
              id: c.id,
              icon: c.icon,
              title: c.title,
              subtitle: c.subtitle,
              badge: c.badge,
              places: c.places.map(_normalizePlace).toList(),
            ))
        .toList(),
    exploreSuggestions: content.exploreSuggestions,
    mediaSponsors: content.mediaSponsors,
    outages: content.outages,
    transportation: content.transportation,
    fuel: content.fuel,
    branding: content.branding,
    quickActions: content.quickActions,
    moreSections: content.moreSections,
    newsSources: content.newsSources,
    cityServices: content.cityServices,
    headerMedia: content.headerMedia
        .map(
          (m) => HeaderMediaItem(
            type: m.type,
            url: MediaUrlResolver.resolve(m.url),
            title: m.title,
            isActive: m.isActive,
          ),
        )
        .toList(),
  );
}

ExplorePlace _normalizePlace(ExplorePlace place) {
  return ExplorePlace(
    name: place.name,
    shortDescription: place.shortDescription,
    detail: place.detail,
    address: place.address,
    tag: place.tag,
    imageUrl: place.imageUrl != null && place.imageUrl!.trim().isNotEmpty
        ? MediaUrlResolver.resolve(place.imageUrl!)
        : null,
    videoUrl: place.videoUrl != null && place.videoUrl!.trim().isNotEmpty
        ? MediaUrlResolver.resolve(place.videoUrl!)
        : null,
    gallery: place.gallery?.map((g) => MediaUrlResolver.resolve(g)).toList(),
    lat: place.lat,
    lng: place.lng,
    googlePlaceId: place.googlePlaceId,
    googleMapsUrl: place.googleMapsUrl,
    parking: place.parking,
    restroom: place.restroom,
    entryFee: place.entryFee,
    entryFeeNote: place.entryFeeNote,
  );
}
