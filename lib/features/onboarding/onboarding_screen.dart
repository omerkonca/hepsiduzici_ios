import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/main_nav.dart';
import '../../core/theme/app_colors.dart';
import 'onboarding_controller.dart';

// ──────────────────────────────────────────────
// Data model
// ──────────────────────────────────────────────

class _PageData {
  final String title;
  final String description;
  final List<Color> gradient;
  final Widget illustration;

  const _PageData({
    required this.title,
    required this.description,
    required this.gradient,
    required this.illustration,
  });
}

// ──────────────────────────────────────────────
// Main screen
// ──────────────────────────────────────────────

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late final AnimationController _bgController;
  int _currentPage = 0;

  late final List<_PageData> _pages;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _pages = [
      _PageData(
        title: 'Düziçi\'ne\nHoş Geldiniz',
        description:
            'Şehrimizle ilgili her şey artık elinizin altında. Keşfetmeye hazır mısınız?',
        gradient: const [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
        illustration: const _WelcomeIllustration(),
      ),
      _PageData(
        title: 'Etkinlikleri\nKaçırmayın',
        description:
            'Konserler, festivaller ve kültürel buluşmalardan anında haberdar olun.',
        gradient: const [Color(0xFF1B1033), Color(0xFF2D1B69), Color(0xFF11998E)],
        illustration: const _EventsIllustration(),
      ),
      _PageData(
        title: 'Akıllı\nHizmetler',
        description:
            'Nöbetçi eczaneler, namaz vakitleri ve güncel hava durumu her an yanınızda.',
        gradient: const [Color(0xFF0D1B2A), Color(0xFF1B4332), Color(0xFF40916C)],
        illustration: const _ServicesIllustration(),
      ),
      _PageData(
        title: 'Şehri\nKeşfedin',
        description:
            'En güzel mekânları, lezzet duraklarını ve dinlenme alanlarını keşfedin.',
        gradient: const [Color(0xFF1A0A00), Color(0xFF7B2D00), Color(0xFFD4AF37)],
        illustration: const _ExploreIllustration(),
      ),
    ];
  }

  @override
  void dispose() {
    _bgController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    await ref.read(onboardingCompletedProvider.notifier).completeOnboarding();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainNav(),
        transitionDuration: const Duration(milliseconds: 450),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  void _next() {
    if (_currentPage == _pages.length - 1) {
      _finishOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _skip() {
    _finishOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: page.gradient,
          ),
        ),
        child: Stack(
          children: [
            // Animated background blobs
            _AnimatedBlobs(controller: _bgController, colors: page.gradient),

            // Page content
            PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (context, index) => _OnboardingPage(data: _pages[index]),
            ),

            // Skip button
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 24,
              child: _currentPage < _pages.length - 1
                  ? TextButton(
                      onPressed: _skip,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text(
                        'Geç',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ).animate().fadeIn(delay: 400.ms)
                  : const SizedBox.shrink(),
            ),

            // Bottom navigation area
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 48,
              left: 32,
              right: 32,
              child: Column(
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 4,
                        width: _currentPage == i ? 28 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // CTA Button
                  SizedBox(
                    width: double.infinity,
                    child: _GradientButton(
                      key: ValueKey(_currentPage),
                      label: _currentPage == _pages.length - 1 ? 'Başlayalım 🚀' : 'Devam Et',
                      onTap: _next,
                      colors: page.gradient,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Single onboarding page
// ──────────────────────────────────────────────

class _OnboardingPage extends StatelessWidget {
  final _PageData data;
  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 2),

          // Illustration container
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.06),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1.5,
              ),
            ),
            child: data.illustration,
          )
              .animate()
              .scale(
                begin: const Offset(0.7, 0.7),
                end: const Offset(1, 1),
                curve: Curves.elasticOut,
                duration: 900.ms,
              )
              .fadeIn(duration: 500.ms),

          const Spacer(),

          // Title
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.1,
              letterSpacing: -1.0,
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.15, end: 0, duration: 600.ms),

          const SizedBox(height: 20),

          // Description
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.6,
            ),
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0, duration: 600.ms),

          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Gradient CTA Button
// ──────────────────────────────────────────────

class _GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final List<Color> colors;

  const _GradientButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.colors,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTap: () {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: widget.colors.last,
            ),
          ),
        ),
      ),
    ).animate(key: widget.key).fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0);
  }
}

// ──────────────────────────────────────────────
// Animated background blobs
// ──────────────────────────────────────────────

class _AnimatedBlobs extends StatelessWidget {
  final AnimationController controller;
  final List<Color> colors;

  const _AnimatedBlobs({required this.controller, required this.colors});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        return Stack(
          children: [
            Positioned(
              top: -80 + 40 * math.sin(t * math.pi),
              left: -60 + 30 * math.cos(t * math.pi),
              child: _Blob(
                size: 300,
                color: colors.last.withValues(alpha: 0.15),
              ),
            ),
            Positioned(
              bottom: -100 + 50 * math.cos(t * math.pi),
              right: -80 + 40 * math.sin(t * math.pi * 1.3),
              child: _Blob(
                size: 350,
                color: colors.first.withValues(alpha: 0.2),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.4 + 20 * math.sin(t * math.pi * 0.7),
              left: MediaQuery.of(context).size.width * 0.5 - 100,
              child: _Blob(
                size: 200,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;

  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Illustrations (pure Flutter widgets – no images)
// ──────────────────────────────────────────────

/// Page 1 – Welcome: Şehir silüeti + el sallayan figür
class _WelcomeIllustration extends StatefulWidget {
  const _WelcomeIllustration();

  @override
  State<_WelcomeIllustration> createState() => _WelcomeIllustrationState();
}

class _WelcomeIllustrationState extends State<_WelcomeIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final wave = math.sin(_ctrl.value * math.pi);
        return CustomPaint(
          painter: _WelcomePainter(wave: wave),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                // House / city icon cluster
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    // Big building
                    _RoundedRect(
                      width: 50, height: 80,
                      color: Colors.white.withValues(alpha: 0.9),
                      radius: 6,
                    ),
                    // Left building
                    Positioned(
                      left: 10, bottom: 0,
                      child: _RoundedRect(
                        width: 30, height: 55,
                        color: Colors.white.withValues(alpha: 0.6),
                        radius: 4,
                      ),
                    ),
                    // Right building
                    Positioned(
                      right: 10, bottom: 0,
                      child: _RoundedRect(
                        width: 35, height: 65,
                        color: Colors.white.withValues(alpha: 0.7),
                        radius: 4,
                      ),
                    ),
                    // Windows on big building
                    Positioned(
                      top: 12,
                      child: Column(
                        children: [
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            _Window(), const SizedBox(width: 8), _Window(),
                          ]),
                          const SizedBox(height: 8),
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            _Window(), const SizedBox(width: 8), _Window(),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Waving hand with gentle animation
                Transform.rotate(
                  angle: wave * 0.3,
                  alignment: Alignment.bottomCenter,
                  child: const Text('👋', style: TextStyle(fontSize: 40)),
                ),
                const SizedBox(height: 8),
                // Stars
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final delay = i * 0.33;
                    final starWave = math.sin((_ctrl.value + delay) * math.pi * 2);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Transform.translate(
                        offset: Offset(0, -4 * starWave),
                        child: Icon(
                          Icons.star_rounded,
                          color: AppColors.primaryLight.withValues(alpha: 0.85),
                          size: 18,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WelcomePainter extends CustomPainter {
  final double wave;
  _WelcomePainter({required this.wave});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawCircle(Offset(cx, cy), 100 + 5 * wave, paint);
    canvas.drawCircle(
      Offset(cx, cy),
      70 + 3 * wave,
      paint..color = Colors.white.withValues(alpha: 0.07),
    );
  }

  @override
  bool shouldRepaint(_WelcomePainter old) => old.wave != wave;
}

/// Page 2 – Events: Takvim + konfeti + müzik notaları
class _EventsIllustration extends StatefulWidget {
  const _EventsIllustration();

  @override
  State<_EventsIllustration> createState() => _EventsIllustrationState();
}

class _EventsIllustrationState extends State<_EventsIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Orbiting confetti dots
            ...List.generate(8, (i) {
              final angle = (i / 8) * 2 * math.pi + t * 2 * math.pi;
              final r = 95.0;
              final x = math.cos(angle) * r;
              final y = math.sin(angle) * r;
              final colors = [
                Colors.pink, Colors.yellow, Colors.cyan,
                Colors.green, Colors.orange, Colors.purple,
                Colors.red, Colors.teal,
              ];
              return Positioned(
                left: 130 + x - 5,
                top: 130 + y - 5,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colors[i].withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),

            // Calendar card
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 70,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('🎉', style: TextStyle(fontSize: 38)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (_) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    )),
                  ),
                ],
              ),
            ),

            // Floating music notes
            ..._buildNotes(t),
          ],
        );
      },
    );
  }

  List<Widget> _buildNotes(double t) {
    final notes = ['♪', '♫', '♩'];
    return List.generate(3, (i) {
      final progress = (t + i / 3) % 1.0;
      final opacity = progress < 0.8 ? progress / 0.8 * 0.9 : (1 - progress) / 0.2 * 0.9;
      final x = 50.0 + i * 50.0;
      final y = 180.0 - progress * 120;
      return Positioned(
        left: x,
        top: y,
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Text(
            notes[i],
            style: const TextStyle(fontSize: 20, color: Colors.white),
          ),
        ),
      );
    });
  }
}

/// Page 3 – Services: Saat + eczane haçı + güneş/ay
class _ServicesIllustration extends StatefulWidget {
  const _ServicesIllustration();

  @override
  State<_ServicesIllustration> createState() => _ServicesIllustrationState();
}

class _ServicesIllustrationState extends State<_ServicesIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        // Clock hand angle
        final hourAngle = t * 2 * math.pi;
        final minAngle = t * 12 * math.pi;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Clock face
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Hour markers
                  ...List.generate(12, (i) {
                    final a = i / 12 * 2 * math.pi - math.pi / 2;
                    final r = 48.0;
                    return Positioned(
                      left: 60 + r * math.cos(a) - 2,
                      top: 60 + r * math.sin(a) - 2,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Colors.white70,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }),
                  // Hour hand
                  Transform.rotate(
                    angle: hourAngle,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: 3,
                        height: 32,
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  // Minute hand
                  Transform.rotate(
                    angle: minAngle,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: 2,
                        height: 44,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: Colors.white70,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),
                  // Center dot
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),

            // Pharmacy cross – top right
            Positioned(
              top: 30,
              right: 20,
              child: _PlusIcon(size: 36, color: Colors.greenAccent.withValues(alpha: 0.9)),
            ),

            // Crescent moon – top left
            Positioned(
              top: 28,
              left: 22,
              child: Transform.rotate(
                angle: -0.3,
                child: Icon(
                  Icons.nightlight_round,
                  color: Colors.amber.shade200,
                  size: 34,
                ),
              ),
            ),

            // Sun rays – bottom center
            Positioned(
              bottom: 22,
              child: _SunWidget(t: t),
            ),
          ],
        );
      },
    );
  }
}

class _SunWidget extends StatelessWidget {
  final double t;
  const _SunWidget({required this.t});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Rays
        Transform.rotate(
          angle: t * math.pi,
          child: Icon(
            Icons.wb_sunny_outlined,
            color: Colors.orange.shade200,
            size: 32,
          ),
        ),
        Icon(
          Icons.circle,
          color: Colors.orange.shade100,
          size: 18,
        ),
      ],
    );
  }
}

class _PlusIcon extends StatelessWidget {
  final double size;
  final Color color;
  const _PlusIcon({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    final thick = size * 0.22;
    final long = size * 0.75;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: long,
            height: thick,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(thick / 2),
            ),
          ),
          Container(
            width: thick,
            height: long,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(thick / 2),
            ),
          ),
        ],
      ),
    );
  }
}

/// Page 4 – Explore: Harita + pin + pusula
class _ExploreIllustration extends StatefulWidget {
  const _ExploreIllustration();

  @override
  State<_ExploreIllustration> createState() => _ExploreIllustrationState();
}

class _ExploreIllustrationState extends State<_ExploreIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        final bounce = math.sin(t * math.pi);

        return Stack(
          alignment: Alignment.center,
          children: [
            // Map card
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white.withValues(alpha: 0.12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
              ),
              child: CustomPaint(painter: _MapGridPainter()),
            ),

            // Bouncing location pin
            Positioned(
              top: 38 - bounce * 10,
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: const Icon(Icons.place_rounded, color: Colors.white, size: 22),
                  ),
                  // Pin tail
                  Container(
                    width: 2,
                    height: 8,
                    color: AppColors.primary,
                  ),
                  // Shadow
                  Opacity(
                    opacity: 0.3 + bounce * 0.2,
                    child: Container(
                      width: 16 - bounce * 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Compass rose – bottom right
            Positioned(
              bottom: 20,
              right: 22,
              child: Transform.rotate(
                angle: t * math.pi * 0.5,
                child: Icon(
                  Icons.explore_rounded,
                  color: Colors.white.withValues(alpha: 0.85),
                  size: 36,
                ),
              ),
            ),

            // Road lines top left
            Positioned(
              top: 26,
              left: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: 18,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Simulated roads
    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0, size.height * 0.6),
      Offset(size.width, size.height * 0.6),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.4, 0),
      Offset(size.width * 0.55, size.height),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(_MapGridPainter _) => false;
}

// ──────────────────────────────────────────────
// Tiny helpers
// ──────────────────────────────────────────────

class _RoundedRect extends StatelessWidget {
  final double width, height;
  final Color color;
  final double radius;

  const _RoundedRect({
    required this.width,
    required this.height,
    required this.color,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _Window extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
