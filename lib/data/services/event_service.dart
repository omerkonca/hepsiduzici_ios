import 'package:dio/dio.dart';

import '../../core/utils/event_sanitizer.dart';
import '../models/event_item.dart';
import '../models/stamped_data.dart';

class EventService {
  const EventService(this.dio, {required this.remoteUrl});

  final Dio dio;
  final String remoteUrl;

  Future<List<EventItem>> getEvents() async => (await getStampedEvents()).data;

  Future<Stamped<List<EventItem>>> getStampedEvents() async {
    // 1. Try local/configured remoteUrl first with short timeout
    if (remoteUrl.trim().isNotEmpty) {
      try {
        final response = await dio.get(
          remoteUrl,
          options: Options(
            connectTimeout: const Duration(seconds: 3),
            receiveTimeout: const Duration(seconds: 4),
          ),
        );
        if (response.data != null && response.data['ok'] == true) {
          final list = (response.data['items'] as List<dynamic>?) ?? [];
          final data = EventSanitizer.clean(
            list
                .map((e) =>
                    EventItem.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList(),
          );
          return Stamped(
            data: data,
            fetchedAt: response.data['fetchedAt'] != null
                ? DateTime.tryParse(response.data['fetchedAt'] as String) ?? DateTime.now()
                : DateTime.now(),
            source: 'backend',
          );
        }
      } catch (_) {}
    }

    // 2. Fallback: If configured url is not the Render URL, try Render directly
    const productionEventsUrl = 'https://hdbackend-vo99.onrender.com/api/events';
    if (remoteUrl != productionEventsUrl) {
      try {
        final response = await dio.get(
          productionEventsUrl,
          options: Options(
            connectTimeout: const Duration(seconds: 6),
            receiveTimeout: const Duration(seconds: 8),
          ),
        );
        if (response.data != null && response.data['ok'] == true) {
          final list = (response.data['items'] as List<dynamic>?) ?? [];
          final data = EventSanitizer.clean(
            list
                .map((e) =>
                    EventItem.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList(),
          );
          return Stamped(
            data: data,
            fetchedAt: response.data['fetchedAt'] != null
                ? DateTime.tryParse(response.data['fetchedAt'] as String) ?? DateTime.now()
                : DateTime.now(),
            source: 'render-backend',
          );
        }
      } catch (_) {}
    }

    // 3. Last fallback: return empty list instead of throwing exception
    return Stamped(
      data: const <EventItem>[],
      fetchedAt: DateTime.now(),
      source: 'offline',
    );
  }
}
