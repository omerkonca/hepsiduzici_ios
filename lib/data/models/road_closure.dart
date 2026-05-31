class RoadClosure {
  const RoadClosure({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.reason,
    required this.roadCode,
    required this.address,
    required this.lat,
    required this.lng,
    required this.alternativeRoute,
    required this.severity,
    this.startAt,
    this.endAt,
    this.source,
    this.announcementUrl,
    this.kind,
  });

  final String id;
  final String title;
  final String subtitle;
  final String status;
  final String reason;
  final String roadCode;
  final String address;
  final double lat;
  final double lng;
  final String alternativeRoute;
  /// full | partial | maintenance
  final String severity;
  final String? startAt;
  final String? endAt;
  final String? source;
  final String? announcementUrl;
  /// municipality | manual
  final String? kind;

  /// Yol hâlâ kapalı / kısıtlı mı (tamamlanan ve süresi dolanlar hariç).
  bool get isActive {
    final s = status.toLowerCase();
    if (s.contains('tamamland') ||
        s.contains('açıld') ||
        s.contains('acildi') ||
        s.contains('bitti') ||
        s.contains('sona erdi')) {
      return false;
    }
    if (_isPastEndDate(endAt)) return false;
    return s.contains('devam') || s.contains('aktif') || s.isEmpty;
  }

  static bool _isPastEndDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return false;
    final end = DateTime.tryParse(isoDate);
    if (end == null) return false;
    final now = DateTime.now();
    final endDay = DateTime(end.year, end.month, end.day);
    final today = DateTime(now.year, now.month, now.day);
    return endDay.isBefore(today);
  }

  bool get isMunicipalityAnnouncement =>
      kind == 'municipality' ||
      (source ?? '').toUpperCase().contains('BELEDİYE DUYURUSU');

  factory RoadClosure.fromJson(Map<String, dynamic> json) {
    return RoadClosure(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      status: json['status'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      roadCode: json['roadCode'] as String? ?? '',
      address: json['address'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      alternativeRoute: json['alternativeRoute'] as String? ?? '',
      severity: json['severity'] as String? ?? 'partial',
      startAt: json['startAt'] as String?,
      endAt: json['endAt'] as String?,
      source: json['source'] as String?,
      announcementUrl: json['announcementUrl'] as String?,
      kind: json['kind'] as String?,
    );
  }
}
