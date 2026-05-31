import 'package:dio/dio.dart';
import '../models/event_item.dart';
import '../models/stamped_data.dart';

class EventService {
  const EventService(this.dio, {required this.remoteUrl});

  final Dio dio;
  final String remoteUrl;

  Future<List<EventItem>> getEvents() async {
    final response = await dio.get(remoteUrl);
    if (response.data['ok'] == true) {
      final list = (response.data['items'] as List<dynamic>?) ?? [];
      return list.map((e) => EventItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    }
    throw Exception('Etkinlikler alinamadi: ${response.data['message']}');
  }

  Future<Stamped<List<EventItem>>> getStampedEvents() async {
    final response = await dio.get(remoteUrl);
    if (response.data['ok'] == true) {
      final list = (response.data['items'] as List<dynamic>?) ?? [];
      final data = list.map((e) => EventItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      return Stamped(
        data: data,
        fetchedAt: DateTime.parse(response.data['fetchedAt'] as String),
      );
    }
    throw Exception('Etkinlikler alinamadi: ${response.data['message']}');
  }
}
