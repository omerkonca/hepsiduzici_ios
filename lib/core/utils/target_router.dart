import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/models/city_content.dart';
import '../../features/events/my_calendar_screen.dart';
import '../../features/explore/city_guide_screen.dart';
import '../../features/explore/trip_planner_screen.dart';
import '../../features/explore/explore_screen.dart';
import '../../features/news/news_screen.dart';
import '../../features/favorites/favorites_screen.dart';
import '../../features/notifications/notification_center_screen.dart';
import '../../features/pharmacy/pharmacy_screen.dart';
import '../../features/search/global_search_screen.dart';
import '../../features/prayer/prayer_screen.dart';
import '../../features/services/emergency_numbers_screen.dart';
import '../../features/services/fuel_prices_screen.dart';
import '../../features/services/health_facilities_screen.dart';
import '../../features/services/municipality_units_screen.dart';
import '../../features/services/outages_screen.dart';
import '../../features/services/closed_roads_screen.dart';
import '../../features/services/taxi_call_screen.dart';
import '../../features/services/transportation_screen.dart';
import '../../features/settings/notification_preferences_screen.dart';
import '../../features/veterinary/veterinary_screen.dart';
import '../../features/weather/weather_screen.dart';
import '../../features/explore/obituary_screen.dart';
import 'app_navigation.dart';
import 'launcher_utils.dart';

/// Backend tarafindan dondurulen "target" stringleri uygular.
/// Ornekler:
///   screen:news, screen:pharmacy, screen:prayer, screen:weather, screen:explore
///   screen:municipality, screen:transport, screen:taxi, screen:emergency
///   phone:0322XXXXXXX
///   url:https://example.com
///   "" / null    -> sessiz uyari (bilgi kartı)
class TargetRouter {
  TargetRouter._();

  static Future<void> handle(BuildContext context, String? target) async {
    final t = (target ?? '').trim();
    if (t.isEmpty) {
      _info(context, 'Bu özellik yakında.');
      return;
    }

    final colonIdx = t.indexOf(':');
    final scheme = colonIdx > 0 ? t.substring(0, colonIdx).toLowerCase() : t.toLowerCase();
    final rest = colonIdx > 0 ? t.substring(colonIdx + 1) : '';

    switch (scheme) {
      case 'screen':
        await _openScreen(context, rest.toLowerCase());
        return;
      case 'phone':
      case 'tel':
        await LauncherUtils.callPhone(context, rest);
        return;
      case 'url':
      case 'http':
      case 'https':
        final url = scheme == 'url' ? rest : t;
        await LauncherUtils.openUrlExternal(context, url);
        return;
      case 'external':
        _info(context, 'Bu özellik yakında.');
        return;
      default:
        _info(context, 'Tanınmayan hedef: $t');
    }
  }

  static Future<void> _openScreen(BuildContext context, String name) async {
    switch (name) {
      case 'municipality':
        await _pushPage(context, const MunicipalityUnitsScreen());
        return;
      case 'transport':
      case 'transportation':
        await _openTransportation(context);
        return;
      case 'taxi':
        await _openTaxi(context);
        return;
      case 'emergency':
        await _pushPage(context, const EmergencyNumbersScreen());
        return;
      case 'news':
        await _pushPage(context, const NewsScreen());
        return;
      case 'pharmacy':
        await _pushPage(context, const PharmacyScreen());
        return;
      case 'prayer':
        await _pushPage(context, const PrayerScreen());
        return;
      case 'weather':
        await _pushPage(context, const WeatherScreen());
        return;
      case 'explore':
        await _pushPage(context, const ExploreScreen());
        return;
      case 'calendar':
        await _pushPage(context, const MyCalendarScreen());
        return;
      case 'favorites':
        await _pushPage(context, const FavoritesScreen());
        return;
      case 'notifications':
        await _pushPage(context, const NotificationCenterScreen());
        return;
      case 'search':
        await _pushPage(context, const GlobalSearchScreen());
        return;
      case 'notification_settings':
        await _pushPage(context, const NotificationPreferencesScreen());
        return;
      case 'outages':
        await _openOutages(context);
        return;
      case 'closed_roads':
        await _pushPage(context, const ClosedRoadsScreen());
        return;
      case 'health':
        await _pushPage(context, const HealthFacilitiesScreen());
        return;
      case 'veterinary':
        await _pushPage(context, const VeterinaryScreen());
        return;
      case 'obituary':
        await _pushPage(context, const ObituaryScreen());
        return;
      case 'fuel':
        await _pushPage(context, const FuelPricesScreen());
        return;
      case 'explore_nature':
        await _openNatureGuide(context);
        return;
      case 'explore_city':
        await _pushPage(context, const CityGuideScreen());
        return;
      default:
        _info(context, 'Bilinmeyen ekran: $name');
        return;
    }
  }

  static Future<void> _openTaxi(BuildContext context) async {
    CityContent? content;
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      content = await container.read(cityContentProvider.future);
    } catch (_) {
      content = null;
    }
    if (!context.mounted) return;
    if (content == null || content.transportation.taxiStands.isEmpty) {
      _info(context, 'Taksi durağı bilgisi yüklenemedi.');
      return;
    }
    await _pushPage(
      context,
      TaxiCallScreen(
        stands: content.transportation.taxiStands,
        fares: content.transportation.taxiFares,
      ),
    );
  }

  static Future<void> _openTransportation(BuildContext context) async {
    CityContent? content;
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      content = await container.read(cityContentProvider.future);
    } catch (_) {
      content = null;
    }
    if (!context.mounted) return;
    if (content == null) {
      _info(context, 'Ulaşım bilgisi yüklenemedi. Daha sonra tekrar deneyin.');
      return;
    }
    final transportationData = content.transportation;
    await _pushPage(context, TransportationScreen(data: transportationData));
  }

  static Future<void> _pushPage(BuildContext context, Widget page) async {
    if (!context.mounted) return;
    await AppNavigation.push<void>(context, page);
  }

  static Future<void> _openOutages(BuildContext context) async {
    CityContent? content;
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      content = await container.read(cityContentProvider.future);
    } catch (_) {
      content = null;
    }
    if (!context.mounted) return;
    if (content == null) {
      _info(context, 'Kesinti bilgisi yüklenemedi.');
      return;
    }
    await _pushPage(context, const OutagesScreen());
  }

  static Future<void> _openNatureGuide(BuildContext context) async {
    CityContent? content;
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      content = await container.read(cityContentProvider.future);
    } catch (_) {
      content = null;
    }
    if (!context.mounted) return;
    if (content == null) {
      _info(context, 'Gezi bilgisi yüklenemedi.');
      return;
    }
    const ids = ['nature', 'castles', 'historical', 'hiking', 'camping', 'parks', 'highlands', 'thermal', 'places', 'heritage'];
    final hasPlaces = content.exploreCategories
        .where((c) => ids.contains(c.id))
        .any((c) => c.places.isNotEmpty);
    if (!hasPlaces) {
      _info(context, 'Gezi Rehberi için henüz içerik yok.');
      return;
    }
    await AppNavigation.push<void>(context, const TripPlannerScreen());
  }

  static void _info(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
