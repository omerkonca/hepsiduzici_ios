import '../json_parse_utils.dart';
import 'fuel_price.dart';
import 'veterinarian.dart';

class CityContent {
  const CityContent({
    required this.serviceTiles,
    required this.healthFacilities,
    required this.veterinarians,
    required this.emergencyContacts,
    required this.municipalityUnits,
    required this.exploreCategories,
    required this.exploreSuggestions,
    required this.mediaSponsors,
    required this.outages,
    required this.transportation,
    this.fuel,
    this.branding,
    List<QuickActionItem>? quickActions,
    List<MoreSectionItem>? moreSections,
    List<NewsSourceItem>? newsSources,
    List<CityServiceItem>? cityServices,
    List<HeaderMediaItem>? headerMedia,
  })  : _quickActions = quickActions,
        _moreSections = moreSections,
        _newsSources = newsSources,
        _cityServices = cityServices,
        _headerMedia = headerMedia;

  final List<ServiceTileItem> serviceTiles;
  final List<HealthFacilityItem> healthFacilities;
  final List<VeterinarianItem> veterinarians;
  final List<EmergencyContactItem> emergencyContacts;
  final List<MunicipalityUnitItem> municipalityUnits;
  final List<ExploreCategoryItem> exploreCategories;
  final List<ExploreSuggestionItem> exploreSuggestions;
  final List<MediaSponsorItem> mediaSponsors;
  final List<OutageItem> outages;
  final TransportationData transportation;
  final FuelInfo? fuel;
  final BrandingInfo? branding;
  final List<QuickActionItem>? _quickActions;
  final List<MoreSectionItem>? _moreSections;
  final List<NewsSourceItem>? _newsSources;
  final List<HeaderMediaItem>? _headerMedia;
  final List<CityServiceItem>? _cityServices;

  // Hot reload sonrasi olusmus eski instance'larda null olabilecegi icin
  // her zaman default bos liste donen getter'lar.
  List<QuickActionItem> get quickActions => _quickActions ?? const [];
  List<MoreSectionItem> get moreSections => _moreSections ?? const [];
  List<NewsSourceItem> get newsSources => _newsSources ?? const [];
  List<CityServiceItem> get cityServices => _cityServices ?? const [];
  List<HeaderMediaItem> get headerMedia => _headerMedia ?? const [];

  factory CityContent.fromJson(Map<String, dynamic> json) {
    final services = (json['services'] as Map<String, dynamic>? ?? {});
    final explore = (json['explore'] as Map<String, dynamic>? ?? {});
    final media = (json['media'] as Map<String, dynamic>? ?? {});
    final brandingJson = json['branding'] as Map<String, dynamic>?;
    final home = (json['home'] as Map<String, dynamic>? ?? {});
    final more = (json['more'] as Map<String, dynamic>? ?? {});
    final news = (json['news'] as Map<String, dynamic>? ?? {});

    return CityContent(
      serviceTiles: (services['tiles'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => ServiceTileItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      healthFacilities: (services['healthFacilities'] as List<dynamic>? ?? [])
          .map((e) => HealthFacilityItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      veterinarians: (services['veterinarians'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => VeterinarianItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      emergencyContacts: (services['emergencyContacts'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => EmergencyContactItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      municipalityUnits: (services['municipalityUnits'] as List<dynamic>? ?? [])
          .map((e) => MunicipalityUnitItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      exploreCategories: JsonParseUtils.mapList(
        explore['categories'],
        (e) => ExploreCategoryItem.fromJson(e),
      ),
      exploreSuggestions: JsonParseUtils.mapList(
        explore['suggestions'],
        (e) => ExploreSuggestionItem.fromJson(e),
      ),
      mediaSponsors: (media['sponsors'] as List<dynamic>? ?? [])
          .map((e) => MediaSponsorItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      outages: (services['outages'] as List<dynamic>? ?? [])
          .map((e) => OutageItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      transportation: TransportationData.fromJson(Map<String, dynamic>.from(services['transportation'] as Map? ?? {})),
      fuel: services['fuel'] != null
          ? FuelInfo.fromJson(Map<String, dynamic>.from(services['fuel'] as Map))
          : null,
      branding: brandingJson != null ? BrandingInfo.fromJson(brandingJson) : null,
      quickActions: (home['quickActions'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => QuickActionItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      moreSections: (more['sections'] as List<dynamic>? ?? [])
          .map((e) => MoreSectionItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      newsSources: (news['sources'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => NewsSourceItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      cityServices: (explore['cityServices'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => CityServiceItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      headerMedia: (home['headerMedia'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => HeaderMediaItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class BrandingInfo {
  const BrandingInfo({
    this.appName,
    this.tagline,
    this.logoUrl,
    this.primaryColor,
    this.primaryDarkColor,
    this.accentBlueColor,
    this.splashBackgroundColor,
    this.heroCardBg,
    this.exploreHeaderBg,
  });

  final String? appName;
  final String? tagline;
  final String? logoUrl;
  final String? primaryColor;
  final String? primaryDarkColor;
  final String? accentBlueColor;
  final String? splashBackgroundColor;
  final String? heroCardBg;
  final String? exploreHeaderBg;

  factory BrandingInfo.fromJson(Map<String, dynamic> json) {
    String? str(String key) {
      final v = json[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
      return null;
    }

    return BrandingInfo(
      appName: str('appName'),
      tagline: str('tagline'),
      logoUrl: str('logoUrl'),
      primaryColor: str('primaryColor'),
      primaryDarkColor: str('primaryDarkColor'),
      accentBlueColor: str('accentBlueColor'),
      splashBackgroundColor: str('splashBackgroundColor'),
      heroCardBg: str('heroCardBg'),
      exploreHeaderBg: str('exploreHeaderBg'),
    );
  }
}

class QuickActionItem {
  const QuickActionItem({
    required this.id,
    required this.icon,
    required this.label,
    required this.color,
    required this.target,
    this.subtitle,
    this.isActive = true,
  });

  final String id;
  final String icon;
  final String label;
  final String color;
  final String target;
  final String? subtitle;
  final bool isActive;

  factory QuickActionItem.fromJson(Map<String, dynamic> json) {
    final target = (json['target'] as String?) ?? '';
    final id = (json['id'] as String?)?.trim();
    return QuickActionItem(
      id: (id != null && id.isNotEmpty) ? id : _quickActionIdFromTarget(target),
      icon: (json['icon'] as String?) ?? '',
      label: ((json['label'] as String?) ?? (json['title'] as String?))?.trim() ?? '',
      color: (json['color'] as String?) ?? '',
      target: target,
      subtitle: (json['subtitle'] as String?)?.trim(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  static String _quickActionIdFromTarget(String target) {
    if (target.isEmpty) return '';
    final key = target.contains(':') ? target.split(':').last : target;
    return key.replaceAll('_', '-');
  }
}

class MoreSectionItem {
  const MoreSectionItem({required this.title, required this.tiles});

  final String title;
  final List<MoreTileItem> tiles;

  factory MoreSectionItem.fromJson(Map<String, dynamic> json) {
    return MoreSectionItem(
      title: json['title'] as String? ?? '',
      tiles: (json['tiles'] as List<dynamic>? ?? [])
          .map((e) => MoreTileItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class MoreTileItem {
  const MoreTileItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.target,
  });

  final String icon;
  final String title;
  final String subtitle;
  final String color;
  final String target;

  factory MoreTileItem.fromJson(Map<String, dynamic> json) {
    return MoreTileItem(
      icon: json['icon'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      color: json['color'] as String? ?? '',
      target: json['target'] as String? ?? '',
    );
  }
}

class NewsSourceItem {
  const NewsSourceItem({
    required this.name,
    required this.url,
    required this.filterDuzici,
    required this.isActive,
  });

  final String name;
  final String url;
  final bool filterDuzici;
  final bool isActive;

  factory NewsSourceItem.fromJson(Map<String, dynamic> json) {
    return NewsSourceItem(
      name: json['name'] as String? ?? '',
      url: json['url'] as String? ?? '',
      filterDuzici: json['filterDuzici'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class MediaSponsorItem {
  const MediaSponsorItem({
    required this.id,
    required this.title,
    required this.badge,
    required this.imageUrl,
    required this.targetUrl,
    this.isActive = true,
  });

  final String id;
  final String title;
  final String badge;
  final String imageUrl;
  final String targetUrl;
  final bool isActive;

  factory MediaSponsorItem.fromJson(Map<String, dynamic> json) {
    return MediaSponsorItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      badge: json['badge'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      targetUrl: json['targetUrl'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class ServiceTileItem {
  const ServiceTileItem({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.target,
    this.isActive = true,
  });

  final String id;
  final String icon;
  final String title;
  final String subtitle;
  final String target;
  final bool isActive;

  factory ServiceTileItem.fromJson(Map<String, dynamic> json) {
    return ServiceTileItem(
      id: json['id'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      target: json['target'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class HealthFacilityItem {
  const HealthFacilityItem({
    required this.name,
    required this.type,
    required this.address,
    required this.phone,
    this.lat,
    this.lng,
    this.workingHours,
    this.isEmergency,
  });

  final String name;
  final String type;
  final String address;
  final String phone;
  final double? lat;
  final double? lng;
  final String? workingHours;
  final bool? isEmergency;

  factory HealthFacilityItem.fromJson(Map<String, dynamic> json) {
    return HealthFacilityItem(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      workingHours: json['workingHours'] as String?,
      isEmergency: json['isEmergency'] as bool?,
    );
  }
}

class EmergencyContactItem {
  const EmergencyContactItem({
    required this.name,
    required this.number,
    required this.icon,
  });

  final String name;
  final String number;
  final String icon;

  factory EmergencyContactItem.fromJson(Map<String, dynamic> json) {
    return EmergencyContactItem(
      name: json['name'] as String? ?? '',
      number: json['number'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
    );
  }
}

class MunicipalityUnitItem {
  const MunicipalityUnitItem({
    required this.title,
    required this.subtitle,
    required this.phone,
  });

  final String title;
  final String subtitle;
  final String phone;

  factory MunicipalityUnitItem.fromJson(Map<String, dynamic> json) {
    return MunicipalityUnitItem(
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
    );
  }
}

class ExploreCategoryItem {
  const ExploreCategoryItem({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.places,
  });

  final String id;
  final String icon;
  final String title;
  final String subtitle;
  final String badge;
  final List<ExplorePlace> places;

  factory ExploreCategoryItem.fromJson(Map<String, dynamic> json) {
    return ExploreCategoryItem(
      id: json['id'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      badge: json['badge'] as String? ?? '',
      places: JsonParseUtils.mapList(
        json['places'],
        (e) => ExplorePlace.fromJson(e),
      ),
    );
  }
}

class ExploreSuggestionItem {
  const ExploreSuggestionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.places,
  });

  final String title;
  final String subtitle;
  final String icon;
  final List<ExplorePlace> places;

  factory ExploreSuggestionItem.fromJson(Map<String, dynamic> json) {
    return ExploreSuggestionItem(
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      places: JsonParseUtils.mapList(
        json['places'],
        (e) => ExplorePlace.fromJson(e),
      ),
    );
  }
}

class ExplorePlace {
  const ExplorePlace({
    required this.name,
    required this.shortDescription,
    required this.detail,
    required this.address,
    required this.tag,
    this.imageUrl,
    this.videoUrl,
    this.gallery,
    this.lat,
    this.lng,
    this.googlePlaceId,
    this.googleMapsUrl,
    this.parking,
    this.restroom,
    this.entryFee,
    this.entryFeeNote,
  });

  final String name;
  final String shortDescription;
  final String detail;
  final String address;
  final String tag;
  final String? imageUrl;
  final String? videoUrl;
  final List<String>? gallery;
  final double? lat;
  final double? lng;
  final String? googlePlaceId;
  final String? googleMapsUrl;
  /// var | yok | sinirli | ucretli | bilinmiyor
  final String? parking;
  /// var | yok | bilinmiyor
  final String? restroom;
  /// ucretsiz | ucretli | bilinmiyor
  final String? entryFee;
  final String? entryFeeNote;

  factory ExplorePlace.fromJson(Map<String, dynamic> json) {
    return ExplorePlace(
      name: json['name'] as String? ?? '',
      shortDescription: json['shortDescription'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
      address: json['address'] as String? ?? '',
      tag: json['tag'] as String? ?? '',
      imageUrl: json['image'] as String? ?? json['imageUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      gallery: (json['gallery'] as List<dynamic>?)?.map((e) => e as String).toList(),
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      googlePlaceId: json['googlePlaceId'] as String?,
      googleMapsUrl: json['googleMapsUrl'] as String?,
      parking: json['parking'] as String?,
      restroom: json['restroom'] as String?,
      entryFee: json['entryFee'] as String?,
      entryFeeNote: json['entryFeeNote'] as String?,
    );
  }
}

class OutageItem {
  const OutageItem({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.status,
    this.source,
    this.url,
    this.date,
  });

  final String title;
  final String subtitle;
  final String type;
  final String status;
  final String? source;
  final String? url;
  final DateTime? date;

  factory OutageItem.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date'] as String?;
    return OutageItem(
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      type: json['type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      source: json['source'] as String?,
      url: json['url'] as String?,
      date: rawDate != null && rawDate.isNotEmpty ? DateTime.tryParse(rawDate) : null,
    );
  }
}

class TransportationData {
  const TransportationData({
    required this.taxiStands,
    required this.dolmus,
    this.taxiFares,
  });

  final List<TaxiStandItem> taxiStands;
  final List<DolmusItem> dolmus;
  final TaxiFareGuide? taxiFares;

  factory TransportationData.fromJson(Map<String, dynamic> json) {
    return TransportationData(
      taxiStands: (json['taxiStands'] as List<dynamic>? ?? [])
          .map((e) => TaxiStandItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      dolmus: (json['dolmus'] as List<dynamic>? ?? [])
          .map((e) => DolmusItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      taxiFares: json['taxiFares'] != null
          ? TaxiFareGuide.fromJson(Map<String, dynamic>.from(json['taxiFares'] as Map))
          : null,
    );
  }
}

/// İlçe taksi ücret rehberi (tahmini — güncel tarife sürücü/taksimetre esas).
class TaxiFareGuide {
  const TaxiFareGuide({
    required this.openingFee,
    required this.dayPerKm,
    required this.nightPerKm,
    required this.nightHours,
    required this.minimumFare,
    required this.bayramNote,
    required this.disclaimer,
    required this.tips,
  });

  final String openingFee;
  final String dayPerKm;
  final String nightPerKm;
  final String nightHours;
  final String minimumFare;
  final String bayramNote;
  final String disclaimer;
  final List<String> tips;

  factory TaxiFareGuide.fromJson(Map<String, dynamic> json) {
    return TaxiFareGuide(
      openingFee: json['openingFee'] as String? ?? '',
      dayPerKm: json['dayPerKm'] as String? ?? '',
      nightPerKm: json['nightPerKm'] as String? ?? '',
      nightHours: json['nightHours'] as String? ?? '',
      minimumFare: json['minimumFare'] as String? ?? '',
      bayramNote: json['bayramNote'] as String? ?? '',
      disclaimer: json['disclaimer'] as String? ?? '',
      tips: (json['tips'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
    );
  }
}

class TaxiStandItem {
  const TaxiStandItem({
    required this.id,
    required this.name,
    required this.phone,
    required this.location,
    this.lat,
    this.lng,
    this.hours,
    this.tag,
  });

  final String id;
  final String name;
  final String phone;
  final String location;
  final double? lat;
  final double? lng;
  final String? hours;
  final String? tag;

  bool get hasCoords => lat != null && lng != null && lat != 0 && lng != 0;

  bool get isMobileLine {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.startsWith('05') && digits.length >= 10;
  }

  factory TaxiStandItem.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    return TaxiStandItem(
      id: json['id'] as String? ?? name,
      name: name,
      phone: json['phone'] as String? ?? '',
      location: (json['address'] ?? json['location']) as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      hours: json['hours'] as String?,
      tag: json['tag'] as String?,
    );
  }
}

class DolmusItem {
  const DolmusItem({
    required this.route,
    required this.schedule,
    required this.firstBus,
    required this.lastBus,
    this.id,
    this.category = 'local',
    this.fareFull,
    this.fareStudent,
    this.fareNote,
    this.operator,
  });

  final String route;
  final String schedule;
  final String firstBus;
  final String lastBus;
  final String? id;
  /// local | intercity
  final String category;
  final String? fareFull;
  final String? fareStudent;
  final String? fareNote;
  final String? operator;

  bool get isIntercity => category == 'intercity';

  String? get fareSummary {
    if (fareFull == null && fareStudent == null) return null;
    final parts = <String>[];
    if (fareFull != null) parts.add('Tam $fareFull');
    if (fareStudent != null) parts.add('Öğrenci $fareStudent');
    return parts.join(' · ');
  }

  factory DolmusItem.fromJson(Map<String, dynamic> json) {
    return DolmusItem(
      id: json['id'] as String?,
      route: json['route'] as String? ?? '',
      schedule: (json['times'] ?? json['schedule']) as String? ?? '',
      firstBus: (json['stops'] ?? json['firstBus']) as String? ?? '',
      lastBus: json['lastBus'] as String? ?? '',
      category: json['category'] as String? ?? 'local',
      fareFull: json['fareFull'] as String?,
      fareStudent: json['fareStudent'] as String?,
      fareNote: json['fareNote'] as String?,
      operator: json['operator'] as String?,
    );
  }
}

/// Keşfet ekranındaki şehir hizmeti kartlarını temsil eder.
class CityServiceItem {
  const CityServiceItem({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.target,
    this.directoryData,
  });

  final String id;
  final String icon;
  final String title;
  final String subtitle;
  final String color;
  final String target;
  final List<DirectoryEntry>? directoryData;

  factory CityServiceItem.fromJson(Map<String, dynamic> json) {
    return CityServiceItem(
      id: json['id'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      color: json['color'] as String? ?? '',
      target: json['target'] as String? ?? '',
      directoryData: _parseDirectoryData(json['directoryData']),
    );
  }

  static List<DirectoryEntry>? _parseDirectoryData(Object? raw) {
    final list = JsonParseUtils.mapList(
      raw,
      (e) => DirectoryEntry.fromJson(e),
    );
    return list.isEmpty ? null : list;
  }
}

/// Bir rehber kaydı: isim, telefon, adres.
class DirectoryEntry {
  const DirectoryEntry({
    required this.name,
    required this.phone,
    required this.address,
  });

  final String name;
  final String phone;
  final String address;

  factory DirectoryEntry.fromJson(Map<String, dynamic> json) {
    return DirectoryEntry(
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
    );
  }
}

class HeaderMediaItem {
  const HeaderMediaItem({
    required this.url,
    required this.type, // 'image' or 'video'
    this.title,
    this.isActive = true,
    this.id,
    this.bubbleId,
  });

  final String url;
  final String type;
  final String? title;
  final bool isActive;
  final String? id;
  final String? bubbleId;

  factory HeaderMediaItem.fromJson(Map<String, dynamic> json) {
    return HeaderMediaItem(
      url: json['url'] as String? ?? '',
      type: json['type'] as String? ?? 'image',
      title: json['title'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      id: json['id'] as String?,
      bubbleId: json['bubbleId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'type': type,
      if (title != null) 'title': title,
      'isActive': isActive,
      if (id != null) 'id': id,
      if (bubbleId != null) 'bubbleId': bubbleId,
    };
  }
}
