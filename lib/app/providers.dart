import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/app_config.dart';
import '../core/theme/app_theme.dart';
import '../data/models/city_content.dart';
import '../data/models/finance_quote.dart';
import '../data/models/fuel_price.dart';
import '../data/models/news_item.dart';
import '../data/models/pharmacy.dart';
import '../data/models/prayer_times.dart';
import '../data/models/stamped_data.dart';
import '../data/models/weather_info.dart';
import '../data/models/weather_report.dart';
import '../data/models/event_item.dart';
import '../data/services/city_content_service.dart';
import '../data/services/finance_service.dart';
import '../data/services/fuel_service.dart';
import '../data/services/news_service.dart';
import '../data/services/pharmacy_service.dart';
import '../data/services/prayer_service.dart';
import '../data/services/weather_service.dart';
import '../data/services/event_service.dart';
import '../data/services/favorites_service.dart';
import '../data/services/notification_service.dart';
import '../data/services/notification_preferences_service.dart';
import '../data/models/app_notification.dart';
import '../data/models/custom_reminder.dart';
import '../data/services/app_notifications_builder.dart';
import '../data/services/reminder_scheduler_service.dart';
import '../data/services/reminder_storage_service.dart';
import '../data/services/discover_service.dart';
import '../data/services/outage_service.dart';
import '../data/services/road_closure_service.dart';
import '../data/services/obituary_service.dart';
import '../data/models/road_closure.dart';
import '../data/models/obituary_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 10),
  ));
  return dio;
});

final pharmacyServiceProvider = Provider<PharmacyService>((ref) {
  return PharmacyService(
    ref.watch(dioProvider),
    remoteUrl: AppConfig.pharmacyUrl,
  );
});

final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService(ref.watch(dioProvider));
});

final prayerServiceProvider = Provider<PrayerService>((ref) {
  return PrayerService(
    ref.watch(dioProvider),
    remoteUrl: AppConfig.prayersUrl,
  );
});

final newsServiceProvider = Provider<NewsService>((ref) {
  return NewsService(
    ref.watch(dioProvider),
    remoteUrl: AppConfig.newsUrl,
  );
});

final cityContentServiceProvider = Provider<CityContentService>((ref) {
  return CityContentService(
    ref.watch(dioProvider),
    remoteUrl: AppConfig.cityContentUrl,
  );
});

final financeServiceProvider = Provider<FinanceService>((ref) {
  return FinanceService(
    ref.watch(dioProvider),
    remoteUrl: AppConfig.financeUrl,
  );
});

final fuelServiceProvider = Provider<FuelService>((ref) {
  return FuelService(
    ref.watch(dioProvider),
    remoteUrl: AppConfig.fuelUrl,
  );
});

final eventServiceProvider = Provider<EventService>((ref) {
  return EventService(
    ref.watch(dioProvider),
    remoteUrl: AppConfig.eventsUrl,
  );
});

final obituaryServiceProvider = Provider<ObituaryService>((ref) {
  return ObituaryService(ref.watch(dioProvider));
});

final favoritesServiceProvider = Provider<FavoritesService>((ref) {
  return FavoritesService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final notificationPreferencesServiceProvider = Provider<NotificationPreferencesService>((ref) {
  return const NotificationPreferencesService();
});

final reminderStorageServiceProvider = Provider<ReminderStorageService>((ref) {
  return const ReminderStorageService();
});

final reminderSchedulerServiceProvider = Provider<ReminderSchedulerService>((ref) {
  return ReminderSchedulerService(
    ref.watch(notificationServiceProvider),
    ref.watch(reminderStorageServiceProvider),
  );
});

final customRemindersProvider = FutureProvider<List<CustomReminder>>((ref) async {
  return ref.watch(reminderStorageServiceProvider).getCustomReminders();
});

final mutedEventIdsProvider =
    StateNotifierProvider<MutedEventIdsNotifier, Set<String>>((ref) {
  return MutedEventIdsNotifier(
    ref.watch(reminderStorageServiceProvider),
    ref.watch(notificationServiceProvider),
    ref,
  );
});

class MutedEventIdsNotifier extends StateNotifier<Set<String>> {
  MutedEventIdsNotifier(this._storage, this._notifications, this._ref)
      : super({}) {
    _load();
  }

  final ReminderStorageService _storage;
  final NotificationService _notifications;
  final Ref _ref;

  Future<void> _load() async {
    state = await _storage.getMutedEventIds();
  }

  bool isMuted(String eventId) => state.contains(eventId);

  Future<void> setMuted(String eventId, bool muted) async {
    await _storage.setEventMuted(eventId, muted);
    if (muted) {
      state = {...state, eventId};
      await _notifications.cancelReminder(_eventNotificationId(eventId));
    } else {
      state = {...state}..remove(eventId);
      final favIds = _ref.read(favoritesProvider)[FavoriteCategory.event] ?? {};
      if (favIds.contains(eventId)) {
        await _ref.read(favoritesProvider.notifier).rescheduleEventReminder(eventId);
      }
    }
  }

  int _eventNotificationId(String eventId) => eventId.hashCode.abs() % 100000;
}

class ReminderPrefsState {
  const ReminderPrefsState({
    required this.prayerReminders,
    required this.pharmacyReminders,
    required this.prayerMinutesBefore,
    this.ready = false,
  });

  final bool prayerReminders;
  final bool pharmacyReminders;
  final int prayerMinutesBefore;
  final bool ready;

  ReminderPrefsState copyWith({
    bool? prayerReminders,
    bool? pharmacyReminders,
    int? prayerMinutesBefore,
    bool? ready,
  }) {
    return ReminderPrefsState(
      prayerReminders: prayerReminders ?? this.prayerReminders,
      pharmacyReminders: pharmacyReminders ?? this.pharmacyReminders,
      prayerMinutesBefore: prayerMinutesBefore ?? this.prayerMinutesBefore,
      ready: ready ?? this.ready,
    );
  }
}

final reminderPrefsProvider =
    StateNotifierProvider<ReminderPrefsNotifier, ReminderPrefsState>((ref) {
  return ReminderPrefsNotifier(
    ref.watch(reminderStorageServiceProvider),
    ref.watch(reminderSchedulerServiceProvider),
    ref.watch(notificationServiceProvider),
    ref,
  );
});

class ReminderPrefsNotifier extends StateNotifier<ReminderPrefsState> {
  ReminderPrefsNotifier(
    this._storage,
    this._scheduler,
    this._notifications,
    this._ref,
  ) : super(const ReminderPrefsState(
          prayerReminders: true,
          pharmacyReminders: true,
          prayerMinutesBefore: 15,
        )) {
    _load();
  }

  final ReminderStorageService _storage;
  final ReminderSchedulerService _scheduler;
  final NotificationService _notifications;
  final Ref _ref;

  Future<void> _load() async {
    state = ReminderPrefsState(
      prayerReminders: await _storage.getPrayerRemindersEnabled(),
      pharmacyReminders: await _storage.getPharmacyRemindersEnabled(),
      prayerMinutesBefore: await _storage.getPrayerMinutesBefore(),
      ready: true,
    );
  }

  Future<void> _resync() async {
    final prayer = _ref.read(stampedPrayerProvider).valueOrNull?.data;
    final pharmacies = _ref.read(stampedPharmacyProvider).valueOrNull?.data;
    await _scheduler.syncAll(prayerTimes: prayer, pharmacies: pharmacies);
  }

  Future<bool> setPrayerReminders(bool value) async {
    if (value) {
      final ok = await _notifications.ensureNotificationPermissions();
      if (ok == false) return false;
    }
    await _storage.setPrayerRemindersEnabled(value);
    state = state.copyWith(prayerReminders: value);
    await _resync();
    return true;
  }

  Future<bool> setPharmacyReminders(bool value) async {
    if (value) {
      final ok = await _notifications.ensureNotificationPermissions();
      if (ok == false) return false;
    }
    await _storage.setPharmacyRemindersEnabled(value);
    state = state.copyWith(pharmacyReminders: value);
    await _resync();
    return true;
  }

  Future<void> setPrayerMinutesBefore(int minutes) async {
    await _storage.setPrayerMinutesBefore(minutes);
    state = state.copyWith(prayerMinutesBefore: minutes);
    await _resync();
  }
}

class NotificationPrefsState {
  const NotificationPrefsState({
    required this.inAppNewNewsBanner,
    required this.systemTrayNewNews,
  });

  final bool inAppNewNewsBanner;
  final bool systemTrayNewNews;

  NotificationPrefsState copyWith({
    bool? inAppNewNewsBanner,
    bool? systemTrayNewNews,
  }) {
    return NotificationPrefsState(
      inAppNewNewsBanner: inAppNewNewsBanner ?? this.inAppNewNewsBanner,
      systemTrayNewNews: systemTrayNewNews ?? this.systemTrayNewNews,
    );
  }
}

final notificationPrefsProvider = StateNotifierProvider<NotificationPrefsNotifier, NotificationPrefsState>((ref) {
  return NotificationPrefsNotifier(
    ref.watch(notificationPreferencesServiceProvider),
    ref.watch(notificationServiceProvider),
  );
});

class NotificationPrefsNotifier extends StateNotifier<NotificationPrefsState> {
  NotificationPrefsNotifier(this._prefs, this._notifications)
      : super(const NotificationPrefsState(inAppNewNewsBanner: true, systemTrayNewNews: true)) {
    _load();
  }

  final NotificationPreferencesService _prefs;
  final NotificationService _notifications;

  Future<void> _load() async {
    state = NotificationPrefsState(
      inAppNewNewsBanner: await _prefs.getInAppNewNewsBanner(),
      systemTrayNewNews: await _prefs.getSystemTrayNewNews(),
    );
  }

  Future<void> setInAppNewNewsBanner(bool value) async {
    await _prefs.setInAppNewNewsBanner(value);
    state = state.copyWith(inAppNewNewsBanner: value);
  }

  /// Yanlış zamanda bildirimi kapatılırsa false döner (ör. Android izin reddi).
  Future<bool> setSystemTrayNewNews(bool value) async {
    if (value) {
      final ok = await _notifications.ensureNotificationPermissions();
      if (ok == false) {
        return false;
      }
    }
    await _prefs.setSystemTrayNewNews(value);
    state = state.copyWith(systemTrayNewNews: value);
    return true;
  }
}

class ReadNotificationsState {
  const ReadNotificationsState({
    this.ids = const {},
    this.ready = false,
  });

  final Set<String> ids;
  final bool ready;

  ReadNotificationsState copyWith({Set<String>? ids, bool? ready}) {
    return ReadNotificationsState(
      ids: ids ?? this.ids,
      ready: ready ?? this.ready,
    );
  }
}

final readNotificationsProvider =
    StateNotifierProvider<ReadNotificationsNotifier, ReadNotificationsState>((ref) {
  return ReadNotificationsNotifier();
});

class ReadNotificationsNotifier extends StateNotifier<ReadNotificationsState> {
  ReadNotificationsNotifier() : super(const ReadNotificationsState()) {
    _load();
  }

  static const _prefsKey = 'read_notification_ids_v2';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ??
        prefs.getStringList('read_notification_ids') ??
        [];
    final migrated = <String>{};
    for (final raw in list) {
      migrated.add(_migrateLegacyId(raw));
    }
    state = ReadNotificationsState(ids: migrated, ready: true);
    await prefs.setStringList(_prefsKey, migrated.toList());
  }

  static String _migrateLegacyId(String id) {
    // Eski: outage_baslik_0 → outage_baslik
    if (RegExp(r'^outage_.*_\d+$').hasMatch(id)) {
      return id.replaceAll(RegExp(r'_\d+$'), '');
    }
    return id;
  }

  Future<void> _persist(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, ids.toList());
  }

  Future<void> markAsRead(String id) async {
    if (!state.ready || state.ids.contains(id)) return;
    final next = {...state.ids, id};
    await _persist(next);
    state = state.copyWith(ids: next);
  }

  Future<void> markAllAsRead(Iterable<String> ids) async {
    if (!state.ready) return;
    final next = {...state.ids, ...ids};
    await _persist(next);
    state = state.copyWith(ids: next);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    await prefs.remove('read_notification_ids');
    state = state.copyWith(ids: {});
  }
}

/// Tüm dinamik bildirimler — rozet ve merkez aynı listeyi kullanır.
final appNotificationsProvider = Provider<List<AppNotification>>((ref) {
  final favorites = ref.watch(favoritesProvider);
  final favEventIds = favorites[FavoriteCategory.event] ?? {};
  final mutedIds = ref.watch(mutedEventIdsProvider);
  final customReminders = ref.watch(customRemindersProvider).valueOrNull ?? [];

  return AppNotificationsBuilder.build(
    outages: ref.watch(stampedOutagesProvider).valueOrNull,
    roadClosures: ref.watch(stampedRoadClosuresProvider).valueOrNull,
    news: ref.watch(stampedNewsProvider).valueOrNull,
    events: ref.watch(stampedEventsProvider).valueOrNull,
    favoriteEventIds: favEventIds,
    mutedEventIds: mutedIds,
    customReminders: customReminders,
    pharmacies: ref.watch(stampedPharmacyProvider).valueOrNull,
  );
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final readState = ref.watch(readNotificationsProvider);
  if (!readState.ready) return 0;

  final notifications = ref.watch(appNotificationsProvider);
  return notifications.where((n) => !readState.ids.contains(n.id)).length;
});

/// Bildirimlerin konumunu ayırt etmek için (ön plan / arka plan).
final appLifecycleStateProvider = StateProvider<AppLifecycleState>((ref) {
  return AppLifecycleState.resumed;
});

final currentIndexProvider = StateProvider<int>((ref) => 0);

final exploreSearchQueryProvider = StateProvider<String>((ref) => '');

final discoverServiceProvider = Provider<DiscoverService>((ref) {
  return DiscoverService(
    ref.watch(dioProvider),
    remoteUrl: AppConfig.baseUrl, // discoverRoutes is relative to baseUrl
  );
});

final outageServiceProvider = Provider<OutageService>((ref) {
  return OutageService(
    ref.watch(dioProvider),
    remoteUrl: AppConfig.outagesUrl,
  );
});

final roadClosureServiceProvider = Provider<RoadClosureService>((ref) {
  return RoadClosureService(
    ref.watch(dioProvider),
    remoteUrl: AppConfig.roadClosuresUrl,
  );
});

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Map<FavoriteCategory, Set<String>>>((ref) {
  return FavoritesNotifier(
    ref.watch(favoritesServiceProvider),
    ref.watch(notificationServiceProvider),
    ref,
  );
});

class FavoritesNotifier extends StateNotifier<Map<FavoriteCategory, Set<String>>> {
  FavoritesNotifier(this._service, this._notifications, this._ref) : super({}) {
    _load();
  }

  final FavoritesService _service;
  final NotificationService _notifications;
  final Ref _ref;

  Future<void> _load() async {
    state = await _service.getAllFavorites();
    await _rescheduleEventReminders();
  }

  Future<void> toggle(FavoriteCategory category, String id) async {
    final wasFavorite = state[category]?.contains(id) ?? false;
    await _service.toggleFavorite(category, id);
    final currentSet = {...(state[category] ?? <String>{})};
    if (wasFavorite) {
      currentSet.remove(id);
    } else {
      currentSet.add(id);
    }
    state = {...state, category: currentSet};

    if (category == FavoriteCategory.event) {
      if (wasFavorite) {
        await _notifications.cancelReminder(_eventNotificationId(id));
      } else {
        await _scheduleEventReminder(id);
      }
    }
  }

  int _eventNotificationId(String eventId) => eventId.hashCode.abs() % 100000;

  Future<void> _scheduleEventReminder(String eventId) async {
    if (_ref.read(mutedEventIdsProvider).contains(eventId)) return;
    try {
      final stamped = await _ref.read(stampedEventsProvider.future);
      final event = stamped.data.where((e) => e.id == eventId).firstOrNull;
      if (event == null) return;
      await _notifications.scheduleEventReminder(
        id: _eventNotificationId(eventId),
        title: 'Etkinlik yaklaşıyor',
        body: '${event.title} — 1 saat içinde başlıyor.',
        scheduledDate: event.date,
      );
    } catch (_) {}
  }

  Future<void> rescheduleEventReminder(String eventId) =>
      _scheduleEventReminder(eventId);

  Future<void> _rescheduleEventReminders() async {
    final eventIds = state[FavoriteCategory.event] ?? {};
    for (final id in eventIds) {
      await _scheduleEventReminder(id);
    }
  }

  bool isFavorite(FavoriteCategory category, String id) {
    return state[category]?.contains(id) ?? false;
  }
}

// =====================================================================
// STAMPED PROVIDERS
// Her veri kaynagi icin "veri + cekildigi an" tasiyan paralel provider'lar.
// Asagidaki klasik "list/info" provider'lar bu stamped olanlardan beslenir
// (geriye donuk uyumluluk icin).
// =====================================================================

final stampedFinanceProvider =
    FutureProvider<Stamped<List<FinanceQuote>>>((ref) {
  return ref.watch(financeServiceProvider).getStampedQuotes();
});

final stampedFuelProvider = FutureProvider<Stamped<List<FuelPrice>>>((ref) {
  return ref.watch(fuelServiceProvider).getStampedPrices();
});

final pharmacyForceRefreshProvider = StateProvider<int>((ref) => 0);

final stampedPharmacyProvider =
    FutureProvider<Stamped<List<Pharmacy>>>((ref) {
  final forceRefresh = ref.watch(pharmacyForceRefreshProvider) > 0;
  return ref
      .watch(pharmacyServiceProvider)
      .getStampedDutyPharmacies(forceRefresh: forceRefresh);
});

final stampedWeatherProvider = FutureProvider<Stamped<WeatherReport>>((ref) {
  return ref.watch(weatherServiceProvider).getStampedWeatherReport();
});

final stampedPrayerProvider = FutureProvider<Stamped<PrayerTimes>>((ref) {
  return ref.watch(prayerServiceProvider).getStampedTimings();
});

final stampedNewsProvider = FutureProvider<Stamped<List<NewsItem>>>((ref) {
  return ref.watch(newsServiceProvider).getStampedNews(limit: 150);
});

final stampedEventsProvider = FutureProvider<Stamped<List<EventItem>>>((ref) {
  return ref.watch(eventServiceProvider).getStampedEvents();
});

final stampedDiscoverProvider = FutureProvider<Stamped<Map<String, dynamic>>>((ref) async {
  final data = await ref.watch(discoverServiceProvider).getDiscoverData();
  return Stamped(data: data, fetchedAt: DateTime.now());
});

final stampedOutagesProvider = FutureProvider<Stamped<List<OutageItem>>>((ref) async {
  return await ref.watch(outageServiceProvider).getStampedOutages();
});

final stampedRoadClosuresProvider = FutureProvider<Stamped<List<RoadClosure>>>((ref) async {
  return ref.watch(roadClosureServiceProvider).getStampedRoadClosures();
});

// =====================================================================
// CLASSIC PROVIDERS (geriye donuk uyumluluk - sadece data kismi)
// =====================================================================

final financeQuotesProvider = FutureProvider<List<FinanceQuote>>((ref) async {
  final s = await ref.watch(stampedFinanceProvider.future);
  return s.data;
});

final fuelPricesProvider = FutureProvider<List<FuelPrice>>((ref) async {
  final s = await ref.watch(stampedFuelProvider.future);
  return s.data;
});

final pharmacyListProvider = FutureProvider<List<Pharmacy>>((ref) async {
  final s = await ref.watch(stampedPharmacyProvider.future);
  return s.data;
});

final weatherProvider = FutureProvider<WeatherInfo>((ref) async {
  final s = await ref.watch(stampedWeatherProvider.future);
  return s.data.current;
});

final prayerTimesProvider = FutureProvider<PrayerTimes>((ref) async {
  final s = await ref.watch(stampedPrayerProvider.future);
  return s.data;
});

final newsListProvider = FutureProvider<List<NewsItem>>((ref) async {
  final s = await ref.watch(stampedNewsProvider.future);
  return s.data;
});

final eventListProvider = FutureProvider<List<EventItem>>((ref) async {
  final s = await ref.watch(stampedEventsProvider.future);
  return s.data;
});

final obituaryRefreshTickProvider = StateProvider<int>((ref) => 0);

final obituaryListProvider = FutureProvider<List<ObituaryItem>>((ref) async {
  final forceRefresh = ref.watch(obituaryRefreshTickProvider) > 0;
  final items = await ref
      .watch(obituaryServiceProvider)
      .getObituaries(forceRefresh: forceRefresh);
  if (forceRefresh) {
    ref.read(obituaryRefreshTickProvider.notifier).state = 0;
  }
  return items;
});

// =====================================================================
// LIVE TICKER + AUTO REFRESH
// =====================================================================

/// Saniyelik 'simdi' yayini. UI'da 'X dk once' gibi goreceli zaman
/// gosterimleri icin kullanilir. 30 saniyede bir yeni deger uretir.
final nowTickerProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  while (true) {
    await Future<void>.delayed(const Duration(seconds: 30));
    yield DateTime.now();
  }
});

/// Belirli aralarla provider'lari otomatik tazeler.
/// HepsiDuziciApp veya HomeScreen tarafindan watch edildiginde devreye girer.
/// - Hava : 10 dk
/// - Finans : 5 dk
/// - Akaryakit : 30 dk
/// - Haber : 5 dk
/// - Eczane : 60 dk
/// - Namaz : 6 saat (gunde 1-2 kez yeter)
final autoRefreshProvider = Provider<void>((ref) {
  final timers = <Timer>[];
  void schedule(Duration interval, void Function() onTick) {
    timers.add(Timer.periodic(interval, (_) => onTick()));
  }

  schedule(const Duration(minutes: 10), () {
    ref.invalidate(stampedWeatherProvider);
  });
  schedule(const Duration(minutes: 5), () {
    ref.invalidate(stampedFinanceProvider);
    ref.invalidate(stampedNewsProvider);
  });
  schedule(const Duration(minutes: 30), () {
    ref.invalidate(stampedFuelProvider);
  });
  schedule(const Duration(minutes: 60), () {
    ref.invalidate(stampedPharmacyProvider);
  });
  schedule(const Duration(hours: 6), () {
    ref.invalidate(stampedPrayerProvider);
  });
  schedule(const Duration(minutes: 15), () {
    ref.invalidate(stampedEventsProvider);
  });
  schedule(const Duration(minutes: 5), () {
    ref.invalidate(stampedRoadClosuresProvider);
  });

  ref.onDispose(() {
    for (final t in timers) {
      t.cancel();
    }
  });
});

/// Haber detay sayfasinda tam metin ve gorsel icin (kaynak URL'den cekilir).
final newsArticleDetailsProvider =
    FutureProvider.family<NewsArticleDetails, String?>((ref, url) async {
  if (url == null || url.isEmpty) return const NewsArticleDetails();
  final service = ref.read(newsServiceProvider);
  return service.getArticleDetails(url);
});

/// Geriye donuk uyumluluk.
final newsFullTextProvider = FutureProvider.family<String?, String?>((ref, url) async {
  final details = await ref.watch(newsArticleDetailsProvider(url).future);
  return details.fullText;
});

/// Haber listesinde secili kategori (kaynak adi). null = Tumu.
final selectedNewsCategoryProvider = StateProvider<String?>((ref) => null);

class CityContentNotifier extends AsyncNotifier<CityContent> {
  @override
  FutureOr<CityContent> build() async {
    final service = ref.watch(cityContentServiceProvider);
    
    // 1. Yerel veriyi hemen yükle ve ilk durum olarak ata
    final bundled = await service.loadBundledOnly();
    
    // 2. Uzak veriyi arka planda yüklemeyi başlat
    _loadRemoteInBackground(service, bundled);
    
    return bundled;
  }
  
  Future<void> _loadRemoteInBackground(CityContentService service, CityContent bundled) async {
    try {
      final remote = await service.loadRemoteOnly();
      if (remote != null) {
        state = AsyncValue.data(service.reconcileOnly(remote, bundled));
      }
    } catch (_) {
      // Arka plandaki ağ hatalarını yut ve yerel veriyle devam et
    }
  }
}

final cityContentProvider = AsyncNotifierProvider<CityContentNotifier, CityContent>(
  CityContentNotifier.new,
);

/// Backend'den gelen branding bilgisi (yoksa null).
final brandingProvider = Provider<BrandingInfo?>((ref) {
  final async = ref.watch(cityContentProvider);
  return async.maybeWhen(data: (c) => c.branding, orElse: () => null);
});

/// Branding'den uretilen aktif tema. Yoksa default AppTheme.
final themeProvider = Provider<ThemeData>((ref) {
  final branding = ref.watch(brandingProvider);
  return AppTheme.fromBranding(branding, Brightness.light);
});

final darkThemeProvider = Provider<ThemeData>((ref) {
  final branding = ref.watch(brandingProvider);
  return AppTheme.fromBranding(branding, Brightness.dark);
});

/// Tema modu (Sadece Aydınlık).
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);
