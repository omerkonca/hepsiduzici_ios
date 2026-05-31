import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/assets.dart';
import '../../core/theme/app_colors.dart';
import 'onboarding_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Düziçi\'ne Hoş Geldiniz',
      description: 'Şehrimizle ilgili her şey artık elinizin altında. Keşfetmeye hazır mısınız?',
      image: Assets.onboardingWelcome,
      color: AppColors.primary,
    ),
    OnboardingData(
      title: 'Etkinlikleri Kaçırmayın',
      description: 'Konserler, festivaller ve kültürel buluşmalardan anında haberdar olun.',
      image: Assets.onboardingEvents,
      color: const Color(0xFF6C63FF),
    ),
    OnboardingData(
      title: 'Akıllı Hizmetler',
      description: 'Nöbetçi eczaneler, namaz vakitleri ve güncel hava durumu her an yanınızda.',
      image: Assets.onboardingServices,
      color: const Color(0xFF00BFA6),
    ),
    OnboardingData(
      title: 'Keşfetmeye Başlayın',
      description: 'Şehrin en güzel yerlerini, lezzet duraklarını ve dinlenme alanlarını keşfedin.',
      image: Assets.onboardingExplore,
      color: const Color(0xFFFF8A65),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return OnboardingPage(data: _pages[index]);
            },
          ),
          Positioned(
            bottom: 60,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Page Indicator
                Row(
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 8),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? AppColors.primary : Theme.of(context).disabledColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                // Navigation Button
                ElevatedButton(
                  onPressed: () {
                    if (_currentPage == _pages.length - 1) {
                      ref.read(onboardingCompletedProvider.notifier).completeOnboarding();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeInOutCubic,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    _currentPage == _pages.length - 1 ? 'Başlayalım' : 'Sonraki',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ).animate(key: ValueKey(_currentPage == _pages.length - 1)).scale(),
              ],
            ),
          ),
          Positioned(
            top: 60,
            right: 24,
            child: TextButton(
              onPressed: () {
                ref.read(onboardingCompletedProvider.notifier).completeOnboarding();
              },
              child: Text(
                'Geç',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 500.ms),
        ],
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final OnboardingData data;

  const OnboardingPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Image.asset(
            data.image,
            height: 300,
          ).animate().slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic, duration: 800.ms).fadeIn(),
          const SizedBox(height: 60),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 20),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  height: 1.5,
                ),
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final String image;
  final Color color;

  OnboardingData({
    required this.title,
    required this.description,
    required this.image,
    required this.color,
  });
}
