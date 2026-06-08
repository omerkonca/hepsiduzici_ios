import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/premium_city_theme.dart';
import 'widgets/city_tools_grid.dart';
import 'widgets/discover_places_strip.dart';
import 'widgets/top_news_carousel.dart';
import 'widgets/premium_home_hero_card.dart';
import 'widgets/quick_access_section.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(autoRefreshProvider);

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: PremiumCityTheme.canvas,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFDFBF4),
            Color(0xFFF6F7FB),
            Color(0xFFEFF3F8),
          ],
        ),
      ),
      child: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: Colors.white,
        onRefresh: () async {
          ref.invalidate(stampedWeatherProvider);
          ref.invalidate(stampedPrayerProvider);
          ref.read(pharmacyForceRefreshProvider.notifier).state++;
          ref.invalidate(stampedPharmacyProvider);
          ref.invalidate(stampedNewsProvider);
          ref.invalidate(stampedEventsProvider);
          ref.invalidate(cityContentProvider);
          await Future<void>.delayed(const Duration(milliseconds: 600));
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            const SliverSafeArea(
              bottom: false,
              sliver: SliverToBoxAdapter(child: SizedBox(height: 4)),
            ),
            _PremiumSliver(
              child: const PremiumHomeHeroCard()
                  .animate()
                  .fadeIn(duration: 420.ms, curve: Curves.easeOutCubic)
                  .slideY(
                      begin: 0.035,
                      end: 0,
                      duration: 420.ms,
                      curve: Curves.easeOutCubic),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            _PremiumSliver(
              child: const DiscoverPlacesStrip()
                  .animate(delay: 80.ms)
                  .fadeIn(duration: 360.ms, curve: Curves.easeOutCubic),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            _PremiumSliver(
              child: const TopNewsCarousel()
                  .animate(delay: 120.ms)
                  .fadeIn(duration: 360.ms, curve: Curves.easeOutCubic),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            _PremiumSliver(
              child: const QuickAccessSection()
                  .animate(delay: 160.ms)
                  .fadeIn(duration: 360.ms, curve: Curves.easeOutCubic),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            _PremiumSliver(
              child: const CityToolsGrid()
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 360.ms, curve: Curves.easeOutCubic),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 88)),
          ],
        ),
      ),
    );
  }
}

class _PremiumSliver extends StatelessWidget {
  const _PremiumSliver({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: PremiumCityTheme.pagePadding),
            child: child,
          ),
        ),
      ),
    );
  }
}
