class CustomReminder {
  const CustomReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledAt,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final DateTime scheduledAt;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'scheduledAt': scheduledAt.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory CustomReminder.fromJson(Map<String, dynamic> json) {
    return CustomReminder(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      scheduledAt: DateTime.tryParse(json['scheduledAt'] as String? ?? '') ??
          DateTime.now(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
