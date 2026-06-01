import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  String _statusText = 'Sistem yükleniyor...';
  late Timer _progressTimer;
  late Timer _textTimer;
  
  final List<String> _statusTexts = [
    'Sistem yükleniyor...',
    'Şehir asistanı hazırlanıyor...',
    'Veriler eşitleniyor...',
    'Hava durumu ve kesintiler güncelleniyor...',
    'Haberler alınıyor...',
    'Kusursuz deneyim için optimize ediliyor...',
    'Hoş geldiniz!',
  ];
  int _textIndex = 0;

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  @override
  void dispose() {
    _progressTimer.cancel();
    _textTimer.cancel();
    super.dispose();
  }

  void _startLoading() {
    // 2.5 saniyede loading barı doldur
    const duration = Duration(milliseconds: 2500);
    const interval = Duration(milliseconds: 30);
    final totalSteps = duration.inMilliseconds / interval.inMilliseconds;
    int currentStep = 0;

    _progressTimer = Timer.periodic(interval, (timer) {
      currentStep++;
      setState(() {
        _progress = currentStep / totalSteps;
        if (_progress >= 1.0) {
          _progress = 1.0;
          timer.cancel();
          _navigateToNextScreen();
        }
      });
    });

    // Metinleri periyodik olarak değiştir
    _textTimer = Timer.periodic(const Duration(milliseconds: 350), (timer) {
      if (_textIndex < _statusTexts.length - 1) {
        setState(() {
          _textIndex++;
          _statusText = _statusTexts[_textIndex];
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _navigateToNextScreen() async {
    if (!mounted) return;
    
    // SharedPreferences üzerinden onboarding durumunu oku
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool('has_seen_onboarding') ?? false;

    if (!mounted) return;

    // Premium yumuşak geçiş efektiyle yeni ekrana yönlendir
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return onboardingCompleted ? const MainNav() : const OnboardingScreen();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: animation.drive(
                Tween<double>(begin: 1.04, end: 1.0).chain(
                  CurveTween(curve: Curves.easeOutCubic),
                ),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 650),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060914), // Premium derin karanlık lacivert
      body: Stack(
        children: [
          // Arka Plan Gradient Efektli Orb Işıkları (Premium Parallax)
          Positioned(
            top: -120,
            left: -120,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 100,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF007AFF).withValues(alpha: 0.12),
                    blurRadius: 90,
                    spreadRadius: 30,
                  ),
                ],
              ),
            ),
          ),
          
          // Ana İçerik
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 3),
                
                // Pulsing glowing emblem/logo
                Center(
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF161C2E),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.28),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 24,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // Logo yoksa veya yüklenemezse şık bir seyahat ikonu çiz
                            return const Icon(
                              Icons.hiking_rounded,
                              color: AppColors.primary,
                              size: 48,
                            );
                          },
                        ),
                      ),
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat(reverse: true))
                      .scale(
                        begin: const Offset(0.96, 0.96),
                        end: const Offset(1.04, 1.04),
                        duration: 1400.ms,
                        curve: Curves.easeInOutCubic,
                      ),
                ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.8, 0.8), duration: 800.ms, curve: Curves.easeOutBack),
                
                const SizedBox(height: 28),
                
                // Başlık
                Text(
                  'HEPSİ DÜZİÇİ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                    letterSpacing: 4.0,
                    shadows: [
                      Shadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
                
                const SizedBox(height: 8),
                
                // Alt Başlık
                const Text(
                  'Akıllı Şehir & Seyahat Rehberi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF9AA3B5),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ).animate().fadeIn(delay: 350.ms, duration: 600.ms),
                
                const Spacer(flex: 2),
                
                // Premium İlerleme Çubuğu (Loading Bar) ve Durum Bilgisi
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Column(
                    children: [
                      // Durum metni
                      SizedBox(
                        height: 20,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: animation.drive(
                                  Tween<Offset>(
                                    begin: const Offset(0, 0.3),
                                    end: Offset.zero,
                                  ).chain(CurveTween(curve: Curves.easeOutCubic)),
                                ),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            _statusText,
                            key: ValueKey<String>(_statusText),
                            style: const TextStyle(
                              color: Color(0xFF7E899D),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      
                      // İlerleme Track & Glowing Fill
                      Container(
                        height: 5,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _progress,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE8C547), AppColors.primary],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 500.ms, duration: 600.ms),
                
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
