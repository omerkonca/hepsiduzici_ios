import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../../data/services/notification_service.dart';
import 'firebase_bootstrap.dart';

/// Arka planda gelen FCM mesajları (top-level gerekli).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await FirebaseBootstrap.ensureInitialized();
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  static const _marketingOptInKey = 'push_marketing_opt_in';

  bool _ready = false;
  String? _currentToken;

  bool get isReady => _ready;

  /// Uygulama açılışında veya ön plana dönüşte tekrar dene.
  Future<bool> ensureRegistered(NotificationService localNotifications) async {
    if (_currentToken != null) {
      await _registerToken(_currentToken!);
      return true;
    }
    _ready = false;
    return initialize(localNotifications);
  }

  Future<bool> initialize(NotificationService localNotifications) async {
    if (_ready) return true;
    if (kIsWeb) return false;

    try {
      final firebaseOk = await FirebaseBootstrap.ensureInitialized();
      if (!firebaseOk) {
        if (kDebugMode) {
          debugPrint(
            '[Push] Firebase yok — google-services.json ve '
            'GoogleService-Info.plist ekleyin.',
          );
        }
        return false;
      }
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (Platform.isIOS) {
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      final token = await _resolveFcmToken(messaging);
      if (token != null) {
        await _registerToken(token);
        developer.log('[Push] token kaydedildi', name: 'hepsiduzici.push');
      } else {
        developer.log('[Push] FCM token alınamadı', name: 'hepsiduzici.push');
      }

      messaging.onTokenRefresh.listen(_registerToken);

      FirebaseMessaging.onMessage.listen((message) async {
        final n = message.notification;
        if (n == null) return;
        await localNotifications.showPushBroadcast(
          title: n.title ?? 'Hepsi Düziçi',
          body: n.body ?? '',
          payload: message.data['route'],
        );
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        final route = message.data['route'];
        if (route != null && route.isNotEmpty) {
          NotificationService.persistPendingNewsTap(route);
        }
      });

      _ready = true;
      return true;
    } catch (e, st) {
      developer.log('[Push] init failed: $e', name: 'hepsiduzici.push', error: e, stackTrace: st);
      return false;
    }
  }

  Future<String?> _resolveFcmToken(FirebaseMessaging messaging) async {
    if (Platform.isIOS) {
      for (var attempt = 0; attempt < 3; attempt++) {
        final apns = await messaging.getAPNSToken();
        if (apns != null) break;
        await Future.delayed(Duration(milliseconds: 300 * (attempt + 1)));
      }
    }
    return messaging.getToken();
  }

  Future<bool> getMarketingOptIn() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_marketingOptInKey) ?? true;
  }

  Future<void> setMarketingOptIn(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_marketingOptInKey, value);
    if (_currentToken != null) {
      await _registerToken(_currentToken!);
    }
  }

  Future<void> _registerToken(String token) async {
    _currentToken = token;
    final optIn = await getMarketingOptIn();
    if (!optIn) return;

    final platform = Platform.isIOS
        ? 'ios'
        : Platform.isAndroid
            ? 'android'
            : 'web';

    String? appVersion;
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion = info.version;
    } catch (_) {}

    // 1) Supabase doğrudan kayıt
    try {
      await Supabase.instance.client.from('device_tokens').upsert(
        {
          'token': token,
          'platform': platform,
          'app_version': appVersion,
          'marketing_opt_in': optIn,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'token',
      );
    } catch (e) {
      developer.log('[Push] Supabase upsert: $e', name: 'hepsiduzici.push');
    }

    // 2) Backend yedek kayıt
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
      await dio.post(
        '${AppConfig.backendBaseUrl}/api/push/register',
        data: {
          'token': token,
          'platform': platform,
          'appVersion': appVersion,
          'marketingOptIn': optIn,
        },
      );
    } catch (e) {
      developer.log('[Push] backend register: $e', name: 'hepsiduzici.push');
    }
  }
}
