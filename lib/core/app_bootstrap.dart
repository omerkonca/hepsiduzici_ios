import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app/providers.dart';
import '../data/services/background_fetch_service.dart';
import '../data/services/notification_service.dart';
import 'ads/ad_service.dart';
import 'config/ad_config.dart';
import 'config/app_config.dart';
import 'push/push_notification_service.dart';

/// Ağır başlatma işleri UI gösterildikten sonra çalışır.
Future<void> bootstrapAppServices(ProviderContainer container) async {
  try {
    await Future.wait([
      initializeDateFormatting('tr_TR', null),
      Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabaseAnonKey,
      ),
    ]);
  } catch (e, st) {
    developer.log('Bootstrap core failed: $e', error: e, stackTrace: st);
  }

  final notificationService = container.read(notificationServiceProvider);
  try {
    await notificationService.init();
  } catch (e, st) {
    developer.log('Notification init failed: $e', error: e, stackTrace: st);
  }

  unawaited(_initBackgroundServices(notificationService));
}

Future<void> _initBackgroundServices(NotificationService notificationService) async {
  try {
    await BackgroundFetchService.init();
    await BackgroundFetchService.registerPeriodicTask();
  } catch (_) {}

  if (AdConfig.adsEnabled) {
    unawaited(AdService.instance.initialize());
  }

  unawaited(PushNotificationService.instance.initialize(notificationService));
}
