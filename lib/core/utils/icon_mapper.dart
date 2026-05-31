import 'package:flutter/material.dart';

class IconMapper {
  IconMapper._();

  /// Hem kisaltilmis ('mosque') hem de Flutter Icons.X_rounded adi ('mosque_rounded')
  /// olarak gelse de calisir. Bilinmeyen adlar fallback ikonu doner.
  static IconData fromName(String name) {
    final key = name.trim().toLowerCase().replaceAll('_rounded', '');
    switch (key) {
      // Mevcut city_content.json kullananlar
      case 'local_pharmacy':
        return Icons.local_pharmacy_rounded;
      case 'mosque':
        return Icons.mosque_rounded;
      case 'newspaper':
        return Icons.newspaper_rounded;
      case 'local_hospital':
        return Icons.local_hospital_rounded;
      case 'emergency':
        return Icons.emergency_rounded;
      case 'account_balance':
        return Icons.account_balance_rounded;
      case 'park':
        return Icons.park_rounded;
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'storefront':
        return Icons.storefront_rounded;
      case 'camera_alt':
        return Icons.camera_alt_rounded;
      case 'route':
        return Icons.route_rounded;
      case 'family_restroom':
        return Icons.family_restroom_rounded;
      case 'medical_services':
        return Icons.medical_services_rounded;
      case 'local_police':
        return Icons.local_police_rounded;
      case 'shield':
        return Icons.shield_rounded;
      case 'local_fire_department':
        return Icons.local_fire_department_rounded;
      case 'warning_amber':
        return Icons.warning_amber_rounded;
      case 'bolt':
        return Icons.bolt_rounded;
      case 'commute':
        return Icons.commute_rounded;

      // Hizli erisim & daha fazla menusu icin yaygin ikonlar
      case 'local_taxi':
        return Icons.local_taxi_rounded;
      case 'bus_alert':
        return Icons.bus_alert_rounded;
      case 'directions_bus':
        return Icons.directions_bus_rounded;
      case 'map':
        return Icons.map_rounded;
      case 'place':
        return Icons.place_rounded;
      case 'navigation':
        return Icons.navigation_rounded;
      case 'article':
        return Icons.article_rounded;
      case 'monetization_on':
        return Icons.monetization_on_rounded;
      case 'support_agent':
        return Icons.support_agent_rounded;
      case 'settings':
        return Icons.settings_rounded;
      case 'tune':
        return Icons.tune_rounded;
      case 'phone':
        return Icons.phone_rounded;
      case 'phone_in_talk':
        return Icons.phone_in_talk_rounded;
      case 'language':
        return Icons.language_rounded;
      case 'public':
        return Icons.public_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'event':
        return Icons.event_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'favorite':
        return Icons.favorite_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'info':
        return Icons.info_rounded;
      case 'menu_book':
        return Icons.menu_book_rounded;
      case 'shopping_bag':
        return Icons.shopping_bag_rounded;
      case 'work':
        return Icons.work_rounded;
      case 'directions_car':
        return Icons.directions_car_rounded;
      case 'flight':
        return Icons.flight_rounded;
      case 'hotel':
        return Icons.hotel_rounded;
      case 'water_drop':
        return Icons.water_drop_rounded;
      case 'cloud':
        return Icons.cloud_rounded;
      case 'wb_sunny':
        return Icons.wb_sunny_rounded;
      case 'qr_code_scanner':
        return Icons.qr_code_scanner_rounded;

      // Keşfet şehir hizmetleri ek ikonları
      case 'block':
        return Icons.block_rounded;
      case 'handyman':
        return Icons.handyman_rounded;
      case 'pets':
        return Icons.pets_rounded;
      case 'sell':
        return Icons.sell_rounded;
      case 'campaign':
        return Icons.campaign_rounded;
      case 'hiking':
        return Icons.hiking_rounded;
      case 'location_city':
        return Icons.location_city_rounded;
      case 'home_work':
        return Icons.home_work_rounded;
      case 'local_gas_station':
        return Icons.local_gas_station_rounded;
      case 'sentiment_very_dissatisfied':
        return Icons.sentiment_very_dissatisfied_rounded;
      case 'dentistry':
        return Icons.medical_services_rounded; // Diş ikonu yok; tıp ikonu
      default:
        return Icons.tune_rounded;
    }
  }
}
