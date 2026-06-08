class Pharmacy {
  const Pharmacy({
    required this.name,
    required this.address,
    required this.phone,
    this.lat,
    this.lng,
    this.dateLabel,
    this.dateRange,
  });

  final String name;
  final String address;
  final String phone;
  final double? lat;
  final double? lng;
  final String? dateLabel;
  final String? dateRange;

  factory Pharmacy.fromJson(Map<String, dynamic> json) {
    return Pharmacy(
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      dateLabel: json['dateLabel'] as String? ?? json['date_label'] as String?,
      dateRange: json['dateRange'] as String? ?? json['date_range'] as String?,
    );
  }
}
