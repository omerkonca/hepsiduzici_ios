import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/providers.dart';
import 'core/ads/ad_service.dart';
import 'core/config/ad_config.dart';
import 'core/push/push_notification_service.dart';
import 'core/config/app_config.dart';
import 'data/services/background_fetch_service.dart';
import 'features/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  
  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    );
    // ignore: avoid_print
    print('✅ Supabase initialized successfully');
  } catch (e) {
    // ignore: avoid_print
    print('❌ Supabase initialization failed: $e');
  }
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  final container = ProviderContainer();
  final notificationService = container.read(notificationServiceProvider);
  await notificationService.init();
  // Android + iOS bildirim iznini ilk açılışta iste.
  await notificationService.ensureNotificationPermissions();

  // Arka plan haber kontrol servisini başlat ve kaydet
  try {
    await BackgroundFetchService.init();
    await BackgroundFetchService.registerPeriodicTask();
  } catch (_) {}

  if (AdConfig.adsEnabled) {
    await AdService.instance.initialize();
  }

  await PushNotificationService.instance.initialize(notificationService);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const HepsiDuziciApp(),
    ),
  );
}

class HepsiDuziciApp extends ConsumerWidget {
  const HepsiDuziciApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final branding = ref.watch(brandingProvider);

    return MaterialApp(
      title: branding?.appName ?? 'Hepsi Düziçi',
      theme: theme,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
