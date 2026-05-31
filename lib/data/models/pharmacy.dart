class Pharmacy {
  const Pharmacy({
    required this.name,
    required this.address,
    required this.phone,
    this.lat,
    this.lng,
  });

  final String name;
  final String address;
  final String phone;
  final double? lat;
  final double? lng;

  factory Pharmacy.fromJson(Map<String, dynamic> json) {
    return Pharmacy(
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
    );
  }
}
