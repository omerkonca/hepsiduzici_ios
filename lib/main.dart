import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/providers.dart';
import 'core/app_bootstrap.dart';
import 'features/splash/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  final container = ProviderContainer();
  unawaited(bootstrapAppServices(container));

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
