import 'dart:async';
import 'dart:math' as math;
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
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _loopController;

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
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat();
    _bootstrap();
  }

  @override
  void dispose() {
    _controller.dispose();
    _loopController.dispose();
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
    final eased = Curves.easeOutCubic.transform(_controller.value);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF050815), Color(0xFF030514), Color(0xFF02030E)],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: Listenable.merge([_controller, _loopController]),
            builder: (context, _) {
              final orbitAngle = _loopController.value * math.pi * 2;
              final pulse = 0.92 + (0.08 * (0.5 + 0.5 * math.sin(orbitAngle)));
              return Stack(
                children: [
                  Positioned(
                    top: -120,
                    right: -60,
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.18),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -180,
                    left: -100,
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF1F2A44).withValues(alpha: 0.55),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 34),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(flex: 3),
                        Center(
                          child: Transform.scale(
                            scale: (0.94 + (0.06 * eased)) * pulse,
                            child: SizedBox(
                              width: 146,
                              height: 146,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Transform.rotate(
                                    angle: orbitAngle,
                                    child: Container(
                                      width: 142,
                                      height: 142,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.primary.withValues(alpha: 0.26),
                                        ),
                                      ),
                                      child: Stack(
                                        children: [
                                          Align(
                                            alignment: Alignment.topCenter,
                                            child: SizedBox(
                                              width: 24,
                                              height: 40,
                                              child: Stack(
                                                alignment: Alignment.topCenter,
                                                children: [
                                                  Positioned(
                                                    top: 10,
                                                    child: Container(
                                                      width: 6,
                                                      height: 6,
                                                      decoration: BoxDecoration(
                                                        color: AppColors.primary.withValues(alpha: 0.24),
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    top: 16,
                                                    child: Container(
                                                      width: 4.5,
                                                      height: 4.5,
                                                      decoration: BoxDecoration(
                                                        color: AppColors.primary.withValues(alpha: 0.14),
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    top: 22,
                                                    child: Container(
                                                      width: 3,
                                                      height: 3,
                                                      decoration: BoxDecoration(
                                                        color: AppColors.primary.withValues(alpha: 0.08),
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    margin: const EdgeInsets.only(top: 2),
                                                    width: 10,
                                                    height: 10,
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primary,
                                                      shape: BoxShape.circle,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: AppColors.primary.withValues(alpha: 0.8),
                                                          blurRadius: 12,
                                                          spreadRadius: 1,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 118,
                                    height: 118,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(34),
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [Color(0xFF111C33), Color(0xFF091225)],
                                      ),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.13),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.28),
                                          blurRadius: 38,
                                          spreadRadius: -10,
                                          offset: const Offset(0, 12),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.travel_explore_rounded,
                                      size: 62,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
                        const Text(
                          'HEPSİ DÜZİÇİ',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 29,
                            letterSpacing: 2.4,
                            shadows: [
                              Shadow(
                                color: Color(0x66000000),
                                offset: Offset(0, 4),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          'Akıllı Şehir Rehberi',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFFA8B1C4).withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                            fontSize: 13.2,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const Spacer(flex: 2),
                        Text(
                          'Yükleniyor',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF8A94AB).withValues(alpha: 0.78),
                            fontSize: 11.2,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.9,
                          ),
                        ),
                        const SizedBox(height: 6),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) => FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.18),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          ),
                          child: Text(
                            _statusText,
                            key: ValueKey(_statusText),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFFBAC4D7).withValues(alpha: 0.95),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 13),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (i) {
                            final raw = ((_controller.value * 6) + (i * 0.22)) % 1;
                            final pulse = raw < 0.5 ? raw * 2 : (1 - raw) * 2;
                            final t = Curves.easeInOut.transform(pulse);
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: Container(
                                width: 6.5 + (2.2 * t),
                                height: 6.5 + (2.2 * t),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary.withValues(alpha: 0.42 + (0.45 * t)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.35 * t),
                                      blurRadius: 10,
                                      spreadRadius: 1.5,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 15),
                        Container(
                          height: 10,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: Colors.white.withValues(alpha: 0.06),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final dotLeft = ((constraints.maxWidth * _controller.value) - 7)
                                  .clamp(0.0, constraints.maxWidth - 14);
                              return Stack(
                                children: [
                                  FractionallySizedBox(
                                    widthFactor: _controller.value,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(999),
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFD4AF37), Color(0xFFB9891B)],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: (constraints.maxWidth * _controller.value - 52)
                                        .clamp(-52.0, constraints.maxWidth),
                                    top: 0,
                                    bottom: 0,
                                    child: IgnorePointer(
                                      child: Container(
                                        width: 52,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                            colors: [
                                              Colors.white.withValues(alpha: 0),
                                              Colors.white.withValues(alpha: 0.42),
                                              Colors.white.withValues(alpha: 0),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: (dotLeft as num).toDouble(),
                                    top: 1,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withValues(alpha: 0.95),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary.withValues(alpha: 0.75),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
