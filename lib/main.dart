import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/main_nav.dart';
import 'app/providers.dart';
import 'features/onboarding/onboarding_controller.dart';
import 'features/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  final container = ProviderContainer();
  await container.read(notificationServiceProvider).init();

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
    final onboardingCompleted = ref.watch(onboardingCompletedProvider);

    return MaterialApp(
      title: branding?.appName ?? 'Hepsi Düziçi',
      theme: theme,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: onboardingCompleted ? const MainNav() : const OnboardingScreen(),
    );
  }
}
