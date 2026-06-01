class VeterinarianItem {
  const VeterinarianItem({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.neighborhood,
    this.phone,
    this.lat,
    this.lng,
    this.workingHours,
    this.services = const [],
    this.isEmergency = false,
    this.note,
  });

  final String id;
  final String name;
  final String type;
  final String address;
  final String neighborhood;
  final String? phone;
  final double? lat;
  final double? lng;
  final String? workingHours;
  final List<String> services;
  final bool isEmergency;
  final String? note;

  bool get hasPhone => phone != null && phone!.trim().isNotEmpty;
  bool get hasCoords => lat != null && lng != null;

  factory VeterinarianItem.fromJson(Map<String, dynamic> json) {
    return VeterinarianItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'Klinik',
      address: json['address'] as String? ?? '',
      neighborhood: json['neighborhood'] as String? ?? 'MERKEZ',
      phone: json['phone'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      workingHours: json['workingHours'] as String?,
      services: (json['services'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isEmergency: json['isEmergency'] as bool? ?? false,
      note: json['note'] as String?,
    );
  }
}
