/// Akaryakıt fiyatı (Benzin, Motorin, LPG).
class FuelPrice {
  const FuelPrice({
    required this.code,
    required this.name,
    required this.price,
    this.unit = 'TL/L',
    this.change,
    this.previousPrice,
  });

  /// 'GASOLINE', 'DIESEL', 'LPG'
  final String code;
  final String name;
  final double price;
  final String unit;
  final double? change;
  final double? previousPrice;

  bool get hasChange => change != null && change != 0;

  factory FuelPrice.fromJson(Map<String, dynamic> json) {
    return FuelPrice(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      unit: json['unit'] as String? ?? 'TL/L',
      change: (json['change'] as num?)?.toDouble(),
      previousPrice: (json['previousPrice'] as num?)?.toDouble(),
    );
  }
}

/// İlçedeki istasyon rehberi (city_content).
class FuelStationItem {
  const FuelStationItem({
    required this.id,
    required this.name,
    required this.brand,
    required this.address,
    this.lat,
    this.lng,
    this.hours,
    this.note,
  });

  final String id;
  final String name;
  final String brand;
  final String address;
  final double? lat;
  final double? lng;
  final String? hours;
  final String? note;

  bool get hasCoords => lat != null && lng != null && lat != 0 && lng != 0;

  factory FuelStationItem.fromJson(Map<String, dynamic> json) {
    return FuelStationItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      address: json['address'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      hours: json['hours'] as String?,
      note: json['note'] as String?,
    );
  }
}

class FuelInfo {
  const FuelInfo({
    required this.region,
    required this.disclaimer,
    required this.stations,
    required this.tips,
    required this.sourceLinks,
  });

  final String region;
  final String disclaimer;
  final List<FuelStationItem> stations;
  final List<String> tips;
  final List<FuelSourceLink> sourceLinks;

  factory FuelInfo.fromJson(Map<String, dynamic> json) {
    return FuelInfo(
      region: json['region'] as String? ?? 'Osmaniye / Düziçi',
      disclaimer: json['disclaimer'] as String? ?? '',
      stations: (json['stations'] as List<dynamic>? ?? [])
          .map((e) => FuelStationItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      tips: (json['tips'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      sourceLinks: (json['sourceLinks'] as List<dynamic>? ?? [])
          .map((e) => FuelSourceLink.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class FuelSourceLink {
  const FuelSourceLink({required this.name, required this.url});

  final String name;
  final String url;

  factory FuelSourceLink.fromJson(Map<String, dynamic> json) {
    return FuelSourceLink(
      name: json['name'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }
}
