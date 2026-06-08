import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/custom_reminder.dart';

class ReminderStorageKeys {
  static const customReminders = 'custom_reminders_v1';
  static const mutedEventIds = 'muted_event_ids_v1';
  static const prayerReminders = 'reminder_prayer_enabled';
  static const pharmacyReminders = 'reminder_pharmacy_enabled';
  static const prayerMinutesBefore = 'reminder_prayer_minutes_before';
}

class ReminderStorageService {
  const ReminderStorageService();

  Future<List<CustomReminder>> getCustomReminders() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(ReminderStorageKeys.customReminders);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map>()
          .map((e) => CustomReminder.fromJson(Map<String, dynamic>.from(e)))
          .where((r) => r.scheduledAt.isAfter(DateTime.now().subtract(const Duration(hours: 1))))
          .toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCustomReminders(List<CustomReminder> items) async {
    final p = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await p.setString(ReminderStorageKeys.customReminders, encoded);
  }

  Future<CustomReminder> addCustomReminder({
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {
    final items = await getCustomReminders();
    final reminder = CustomReminder(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      scheduledAt: scheduledAt,
      createdAt: DateTime.now(),
    );
    items.add(reminder);
    await saveCustomReminders(items);
    return reminder;
  }

  Future<void> removeCustomReminder(String id) async {
    final items = await getCustomReminders();
    items.removeWhere((r) => r.id == id);
    await saveCustomReminders(items);
  }

  Future<Set<String>> getMutedEventIds() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(ReminderStorageKeys.mutedEventIds) ?? []).toSet();
  }

  Future<void> setEventMuted(String eventId, bool muted) async {
    final p = await SharedPreferences.getInstance();
    final ids = await getMutedEventIds();
    if (muted) {
      ids.add(eventId);
    } else {
      ids.remove(eventId);
    }
    await p.setStringList(ReminderStorageKeys.mutedEventIds, ids.toList());
  }

  Future<bool> isEventMuted(String eventId) async {
    final ids = await getMutedEventIds();
    return ids.contains(eventId);
  }

  Future<bool> getPrayerRemindersEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(ReminderStorageKeys.prayerReminders) ?? true;
  }

  Future<void> setPrayerRemindersEnabled(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(ReminderStorageKeys.prayerReminders, value);
  }

  Future<bool> getPharmacyRemindersEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(ReminderStorageKeys.pharmacyReminders) ?? true;
  }

  Future<void> setPharmacyRemindersEnabled(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(ReminderStorageKeys.pharmacyReminders, value);
  }

  Future<int> getPrayerMinutesBefore() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(ReminderStorageKeys.prayerMinutesBefore) ?? 15;
  }

  Future<void> setPrayerMinutesBefore(int minutes) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(ReminderStorageKeys.prayerMinutesBefore, minutes);
  }
}
