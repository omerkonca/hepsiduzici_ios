class EventItem {
  const EventItem({
    required this.id,
    required this.title,
    required this.category,
    required this.city,
    required this.district,
    required this.location,
    required this.date,
    required this.imageUrl,
    required this.price,
    required this.link,
  });

  final String id;
  final String title;
  final String category;
  final String city;
  final String district;
  final String location;
  final DateTime date;
  final String imageUrl;
  final String price;
  final String link;

  factory EventItem.fromJson(Map<String, dynamic> json) {
    return EventItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? '',
      city: json['city'] as String? ?? '',
      district: json['district'] as String? ?? '',
      location: json['location'] as String? ?? '',
      date: DateTime.parse(json['date'] as String? ?? DateTime.now().toIso8601String()),
      imageUrl: json['imageUrl'] as String? ?? '',
      price: json['price'] as String? ?? '',
      link: json['link'] as String? ?? '',
    );
  }
}
