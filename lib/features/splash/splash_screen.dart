import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/main_nav.dart';
import '../../core/theme/app_colors.dart';
import '../onboarding/onboarding_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  final List<String> _statusTexts = const [
    'Hazırlanıyor...',
    'Şehir verileri yükleniyor...',
    'Servisler eşitleniyor...',
    'Son kontroller yapılıyor...',
  ];

  String get _statusText {
    final idx = (_controller.value * _statusTexts.length).floor();
    return _statusTexts[idx.clamp(0, _statusTexts.length - 1)];
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    )..forward();
    _bootstrap();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final minWait = Future<void>.delayed(const Duration(milliseconds: 1700));
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool('has_seen_onboarding') ?? false;
    await minWait;
    await _controller.animateTo(1, duration: const Duration(milliseconds: 250));
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            onboardingCompleted ? const MainNav() : const OnboardingScreen(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060914),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 3),
                  const Icon(
                    Icons.travel_explore_rounded,
                    size: 74,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'HEPSİ DÜZİÇİ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                      letterSpacing: 2.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Akıllı Şehir Rehberi',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF98A1B2),
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                  const Spacer(flex: 2),
                  Text(
                    _statusText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF7E899D),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      value: _controller.value,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
