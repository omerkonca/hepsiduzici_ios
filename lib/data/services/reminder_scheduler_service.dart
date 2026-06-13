import '../models/custom_reminder.dart';
import '../models/pharmacy.dart';
import '../models/prayer_times.dart';
import 'notification_service.dart';
import 'reminder_storage_service.dart';

/// Namaz, eczane ve özel hatırlatıcıları planlar.
class ReminderSchedulerService {
  ReminderSchedulerService(this._notifications, this._storage);

  final NotificationService _notifications;
  final ReminderStorageService _storage;

  static const int _prayerIdBase = 20000;
  static const int _customIdBase = 40000;

  Future<void> syncAll({
    PrayerTimes? prayerTimes,
    List<Pharmacy>? pharmacies,
  }) async {
    await syncPrayerReminders(prayerTimes);
    await syncPharmacyReminders(pharmacies);
    await syncCustomReminders();
  }

  Future<void> syncPrayerReminders(PrayerTimes? times) async {
    await _notifications.cancelRemindersInRange(_prayerIdBase, _prayerIdBase + 20);
    if (times == null) return;
    if (!await _storage.getPrayerRemindersEnabled()) return;

    final minutesBefore = await _storage.getPrayerMinutesBefore();
    final now = DateTime.now();
    var index = 0;

    for (final prayer in times.allTimes) {
      final scheduled = _todayAt(prayer.time);
      if (scheduled == null) continue;
      final reminderAt = scheduled.subtract(Duration(minutes: minutesBefore));
      if (reminderAt.isBefore(now)) continue;

      await _notifications.scheduleZonedReminder(
        id: _prayerIdBase + index,
        title: '${prayer.name} vakti yaklaşıyor',
        body: '$minutesBefore dk sonra ${prayer.name} vakti (${prayer.time}).',
        scheduledAt: reminderAt,
        channelId: 'prayer_reminders',
        channelName: 'Namaz Vakti Hatırlatıcıları',
        channelDescription: 'Namaz vakitlerinden önce bildirim',
      );
      index++;
    }
  }

  Future<void> syncPharmacyReminders(List<Pharmacy>? pharmacies) async {
    for (var id = 30001; id <= 30010; id++) {
      await _notifications.cancelReminder(id);
    }
    if (!await _storage.getPharmacyRemindersEnabled()) return;

    final now = DateTime.now();

    for (var weekOffset = 0; weekOffset < 4; weekOffset++) {
      final satTarget = _getUpcomingWeekday(DateTime.saturday, now, weekOffset);
      final satBody = _getPharmacyBody(
        targetDate: satTarget,
        pharmacies: pharmacies,
        now: now,
      );
      await _notifications.scheduleZonedReminder(
        id: 30001 + (weekOffset * 2),
        title: 'Hafta sonu nöbetçi eczane',
        body: satBody,
        scheduledAt: satTarget,
        channelId: 'pharmacy_reminders',
        channelName: 'Nöbetçi Eczane Hatırlatıcıları',
        channelDescription: 'Hafta sonu nöbetçi eczane bildirimleri',
      );

      final sunTarget = _getUpcomingWeekday(DateTime.sunday, now, weekOffset);
      final sunBody = _getPharmacyBody(
        targetDate: sunTarget,
        pharmacies: pharmacies,
        now: now,
      );
      await _notifications.scheduleZonedReminder(
        id: 30002 + (weekOffset * 2),
        title: 'Pazar nöbetçi eczane',
        body: sunBody,
        scheduledAt: sunTarget,
        channelId: 'pharmacy_reminders',
        channelName: 'Nöbetçi Eczane Hatırlatıcıları',
        channelDescription: 'Hafta sonu nöbetçi eczane bildirimleri',
      );
    }
  }

  DateTime _getUpcomingWeekday(int weekday, DateTime now, int weekOffset) {
    var target = DateTime(now.year, now.month, now.day, 9, 0);
    while (target.weekday != weekday) {
      target = target.add(const Duration(days: 1));
    }
    if (target.isBefore(now)) {
      target = target.add(const Duration(days: 7));
    }
    if (weekOffset > 0) {
      target = target.add(Duration(days: 7 * weekOffset));
    }
    return target;
  }

  String _getPharmacyBody({
    required DateTime targetDate,
    required List<Pharmacy>? pharmacies,
    required DateTime now,
  }) {
    final targetDateOnly = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final nowDateOnly = DateTime(now.year, now.month, now.day);
    final tomorrowDateOnly = nowDateOnly.add(const Duration(days: 1));

    if (pharmacies != null && pharmacies.isNotEmpty) {
      if (targetDateOnly == nowDateOnly) {
        final todayPharmacy = pharmacies.firstWhere(
          (p) => p.dateLabel == 'Bugün',
          orElse: () => pharmacies.first,
        );
        return 'Bugün nöbetçi: ${todayPharmacy.name}';
      } else if (targetDateOnly == tomorrowDateOnly) {
        final hasTomorrow = pharmacies.any((p) => p.dateLabel == 'Yarın');
        if (hasTomorrow) {
          final tomorrowPharmacy = pharmacies.firstWhere((p) => p.dateLabel == 'Yarın');
          return 'Bugün nöbetçi: ${tomorrowPharmacy.name}';
        }
      }
    }

    return 'Bugünün nöbetçi eczanesini uygulamadan kontrol edin.';
  }

  Future<void> syncCustomReminders() async {
    final items = await _storage.getCustomReminders();
    for (var i = 0; i < items.length && i < 50; i++) {
      final item = items[i];
      await _notifications.scheduleZonedReminder(
        id: _customIdBase + i,
        title: item.title,
        body: item.body.isNotEmpty ? item.body : 'Hatırlatıcınız var.',
        scheduledAt: item.scheduledAt,
        channelId: 'custom_reminders',
        channelName: 'Özel Hatırlatıcılar',
        channelDescription: 'Sizin oluşturduğunuz hatırlatıcılar',
      );
    }
  }

  Future<CustomReminder> addCustomReminder({
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {
    final reminder = await _storage.addCustomReminder(
      title: title,
      body: body,
      scheduledAt: scheduledAt,
    );
    await syncCustomReminders();
    return reminder;
  }

  Future<void> removeCustomReminder(String id) async {
    await _storage.removeCustomReminder(id);
    await syncCustomReminders();
  }

  DateTime? _todayAt(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }
}
