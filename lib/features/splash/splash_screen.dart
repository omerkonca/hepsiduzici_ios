import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/main_nav.dart';
import '../../core/ads/ad_service.dart';
import '../../core/config/ad_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/premium_city_theme.dart';
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
    'Şehir deneyimi hazırlanıyor',
    'Düziçi verileri eşitleniyor',
    'Hava, haber ve etkinlikler bağlanıyor',
    'Premium şehir arayüzü açılıyor',
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
      duration: const Duration(milliseconds: 900),
    )..forward();
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
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
    final prefsFuture = SharedPreferences.getInstance();
    final minWait = Future<void>.delayed(const Duration(milliseconds: 450));
    final adsFuture = AdConfig.adsEnabled
        ? AdService.instance.ensureInitialized()
        : Future<void>.value();
    final prefs = await prefsFuture;
    final onboardingCompleted = prefs.getBool('has_seen_onboarding') ?? false;
    await Future.wait([minWait, adsFuture]);
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
      body: AnimatedBuilder(
        animation: Listenable.merge([_controller, _loopController]),
        builder: (context, _) {
          final progress = Curves.easeOutCubic.transform(_controller.value);
          final loop = _loopController.value;

          return DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF020412),
                  Color(0xFF050A1F),
                  Color(0xFF02030D),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _SplashAtmospherePainter(loop: loop),
                  ),
                ),
                Positioned(
                  top: -82,
                  right: -72,
                  child: _GlowOrb(
                    size: 240,
                    color: AppColors.primary,
                    opacity: 0.24 + (0.05 * math.sin(loop * math.pi * 2)),
                  ),
                ),
                Positioned(
                  bottom: -120,
                  left: -92,
                  child: _GlowOrb(
                    size: 260,
                    color: const Color(0xFF0E7CFF),
                    opacity: 0.16,
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
                    child: Column(
                      children: [
                        const Spacer(flex: 3),
                        _PremiumLogoMark(loop: loop, progress: progress),
                        const SizedBox(height: 28),
                        ShaderMask(
                          shaderCallback: (rect) {
                            return const LinearGradient(
                              colors: [
                                Color(0xFFFFE8A3),
                                AppColors.primary,
                                Color(0xFFFFC857),
                              ],
                            ).createShader(rect);
                          },
                          child: const Text(
                            'HEPSİ DÜZİÇİ',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 30,
                              letterSpacing: 1.9,
                              height: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Akıllı Şehir Rehberi',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.62),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _SignalChips(loop: loop),
                        const Spacer(flex: 2),
                        _LoadingConsole(
                          progress: progress,
                          loop: loop,
                          statusText: _statusText,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PremiumLogoMark extends StatelessWidget {
  const _PremiumLogoMark({required this.loop, required this.progress});

  final double loop;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final angle = loop * math.pi * 2;
    final pulse = 0.96 + (0.04 * math.sin(angle));

    return Transform.scale(
      scale: (0.92 + (0.08 * progress)) * pulse,
      child: SizedBox(
        width: 168,
        height: 168,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: angle,
              child: CustomPaint(
                size: const Size(168, 168),
                painter: _OrbitPainter(progress: loop),
              ),
            ),
            Transform.rotate(
              angle: -angle * 0.42,
              child: Container(
                width: 122,
                height: 122,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(36),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.22),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  ),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.18)),
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(35),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF102E50), Color(0xFF061325)],
                    ),
                    borderRadius: BorderRadius.circular(35),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.34),
                        blurRadius: 40,
                        spreadRadius: -12,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/app_icon.png',
                        width: 74,
                        height: 74,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 20 + (math.cos(angle) * 5),
              top: 26 + (math.sin(angle) * 5),
              child: _SparkDot(size: 8, opacity: 0.85),
            ),
            Positioned(
              left: 28 + (math.sin(angle) * 4),
              bottom: 25 + (math.cos(angle) * 4),
              child: _SparkDot(size: 5, opacity: 0.55),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignalChips extends StatelessWidget {
  const _SignalChips({required this.loop});

  final double loop;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        _StatusChip(
          icon: Icons.cloud_done_rounded,
          label: 'Canlı Veri',
          active: loop < 0.34,
        ),
        _StatusChip(
          icon: Icons.location_on_rounded,
          label: 'Düziçi',
          active: loop >= 0.34 && loop < 0.67,
        ),
        _StatusChip(
          icon: Icons.auto_awesome_rounded,
          label: 'Premium UI',
          active: loop >= 0.67,
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.active,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: active
            ? AppColors.primary.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active
              ? AppColors.primary.withValues(alpha: 0.34)
              : Colors.white.withValues(alpha: 0.09),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: active
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.50),
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color:
                  active ? Colors.white : Colors.white.withValues(alpha: 0.54),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingConsole extends StatelessWidget {
  const _LoadingConsole({
    required this.progress,
    required this.loop,
    required this.statusText,
  });

  final double progress;
  final double loop;
  final String statusText;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).clamp(0, 100).round();

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.075),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: PremiumCityTheme.goldGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Yükleniyor',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          child: Text(
                            statusText,
                            key: ValueKey(statusText),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.62),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$percent%',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              _PremiumProgressBar(progress: progress, loop: loop),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final wave = math.sin((loop * math.pi * 2) + index);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 6 + (wave > 0 ? wave * 6 : 0),
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: AppColors.primary.withValues(
                        alpha: 0.35 + (0.45 * wave.abs()),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumProgressBar extends StatelessWidget {
  const _PremiumProgressBar({required this.progress, required this.loop});

  final double progress;
  final double loop;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 11,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final filled = width * progress;
          final shineLeft = (width * loop) - 70;

          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.34),
                  borderRadius: BorderRadius.circular(999),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.10)),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: filled,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFE38A),
                      AppColors.primary,
                      Color(0xFFB98719),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.42),
                      blurRadius: 16,
                      spreadRadius: -4,
                    ),
                  ],
                ),
              ),
              Positioned(
                left: shineLeft,
                top: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Container(
                    width: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0),
                          Colors.white.withValues(alpha: 0.62),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: opacity * 0.24),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _SparkDot extends StatelessWidget {
  const _SparkDot({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: opacity),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: opacity),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = Colors.white.withValues(alpha: 0.12);
    final gold = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [
          Colors.transparent,
          AppColors.primary,
          Color(0xFFFFE38A),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);

    canvas.drawCircle(center, 74, base);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 74),
      -math.pi / 2,
      math.pi * 1.2,
      false,
      gold,
    );
    canvas.drawCircle(
        center, 61, base..color = Colors.white.withValues(alpha: 0.07));
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _SplashAtmospherePainter extends CustomPainter {
  const _SplashAtmospherePainter({required this.loop});

  final double loop;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 0.8;

    for (var y = size.height * 0.58; y < size.height; y += 26) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AppColors.primary.withValues(alpha: 0.07);

    for (var i = 0; i < 4; i++) {
      final path = Path();
      final baseY = size.height * (0.70 + i * 0.045);
      path.moveTo(0, baseY);
      for (var x = 0.0; x <= size.width; x += 8) {
        final y =
            baseY + math.sin((x / 42) + (loop * math.pi * 2) + i) * (8 + i * 2);
        path.lineTo(x, y);
      }
      canvas.drawPath(path, wavePaint);
    }

    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.18);
    for (var i = 0; i < 24; i++) {
      final x = (math.sin(i * 12.989 + loop) * 43758.5453).abs() % size.width;
      final y = (math.sin(i * 78.233 + loop) * 12345.678).abs() %
          (size.height * 0.58);
      final opacity = 0.05 + ((math.sin(loop * math.pi * 2 + i) + 1) * 0.06);
      starPaint.color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), 1.1 + (i % 3) * 0.45, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SplashAtmospherePainter oldDelegate) {
    return oldDelegate.loop != loop;
  }
}
