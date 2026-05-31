import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/launcher_utils.dart';
import '../../core/utils/target_router.dart';
import '../../core/utils/weather_wmo_tr.dart';
import '../../data/models/city_content.dart';
import '../news/news_screen.dart';
import '../pharmacy/pharmacy_screen.dart';
import 'widgets/highlights_strip.dart';
import 'widgets/quick_actions_row.dart';
import 'widgets/top_news_carousel.dart';

final _homeNewsCategoryProvider = StateProvider<String>((ref) => 'Düziçi');

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(autoRefreshProvider);
    final cityContentAsync = ref.watch(cityContentProvider);
    final selectedCategory = ref.watch(_homeNewsCategoryProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(stampedWeatherProvider);
        ref.invalidate(stampedPrayerProvider);
        ref.invalidate(stampedPharmacyProvider);
        ref.invalidate(stampedNewsProvider);
        ref.invalidate(stampedFinanceProvider);
        ref.invalidate(stampedFuelProvider);
        ref.invalidate(cityContentProvider);
        await Future<void>.delayed(const Duration(milliseconds: 600));
      },
      color: AppColors.primary,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          const SliverToBoxAdapter(child: _HomeTopBar()),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // 1) Anlık şerit
          SliverToBoxAdapter(
            child: const _SectionTitle(title: 'Anlık Bilgiler')
                .animate(delay: 80.ms)
                .fadeIn(duration: 280.ms),
          ),
          SliverToBoxAdapter(
            child: const HighlightsStrip()
                .animate(delay: 120.ms)
                .fadeIn(duration: 320.ms)
                .slideX(begin: 0.05, end: 0),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // 2) Haberler Kategorize Edilmiş
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: _SectionTitle(
                      title: '$selectedCategory Haberleri',
                      actionLabel: 'Tümü',
                      onAction: () => _push(context, const NewsScreen()),
                    ),
                  ),
                ],
              ),
            ).animate(delay: 200.ms).fadeIn(duration: 280.ms),
          ),
          SliverToBoxAdapter(
            child: _HomeNewsTabs(
              selectedCategory: selectedCategory,
              onChanged: (cat) => ref.read(_homeNewsCategoryProvider.notifier).state = cat,
            ).animate(delay: 220.ms).fadeIn(),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: TopNewsCarousel(category: selectedCategory)
                .animate(key: ValueKey(selectedCategory))
                .fadeIn(duration: 320.ms)
                .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // 3) Hızlı erişim
          SliverToBoxAdapter(
            child: const _SectionTitle(title: 'Hızlı Erişim')
                .animate(delay: 440.ms)
                .fadeIn(duration: 280.ms),
          ),
          SliverToBoxAdapter(
            child: const QuickActionsRow()
                .animate(delay: 480.ms)
                .fadeIn(duration: 320.ms)
                .slideX(begin: 0.05, end: 0),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // 4) Bugünün nöbetçi eczanesi
          SliverToBoxAdapter(
            child: const _DutyPharmacyCard()
                .animate(delay: 560.ms)
                .fadeIn(duration: 320.ms)
                .slideY(begin: 0.05, end: 0),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // 5) Sponsorlar
          SliverToBoxAdapter(
            child: cityContentAsync.when(
              data: (content) {
                final items = content.mediaSponsors.where((x) => x.isActive).toList();
                if (items.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle(title: 'Sponsorluk ve Medya'),
                    _SponsorStrip(items: items),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ).animate(delay: 640.ms).fadeIn(duration: 320.ms),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }
}

class _HomeNewsTabs extends StatelessWidget {
  const _HomeNewsTabs({required this.selectedCategory, required this.onChanged});
  final String selectedCategory;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final categories = ['Düziçi', 'Osmaniye'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: categories.map((cat) {
          final isSelected = cat == selectedCategory;
          final selectedColor = cat == 'Osmaniye' ? AppColors.accentBlue : AppColors.primary;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => onChanged(cat),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: 250.ms,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? selectedColor : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? selectedColor : Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: selectedColor.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Theme.of(context).textTheme.bodySmall?.color,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 16, 12),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 8,
                  spreadRadius: -2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                children: [
                  Text(
                    actionLabel!,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primaryDark),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DutyPharmacyCard extends ConsumerWidget {
  const _DutyPharmacyCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pharmacyListProvider);
    return async.when(
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        final p = list.first;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => _showDutyPharmacySheet(context, list),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context).brightness == Brightness.dark 
                          ? const Color(0xFF1B2E2B) 
                          : const Color(0xFFEAF8F5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? const Color(0xFF2C4A45) 
                        : const Color(0xFFBFE4DE),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF009688).withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.08 : 0.14),
                      blurRadius: 16,
                      spreadRadius: -8,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF009688).withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.local_pharmacy_rounded, color: Color(0xFF009688), size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF009688).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'BUGÜN',
                                  style: TextStyle(
                                    color: Color(0xFF00897B),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            p.name,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (p.phone.isNotEmpty)
                            Text(
                              p.phone,
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodySmall?.color,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? const Color(0xFF2C4A45) 
                              : const Color(0xFFCCE7E2),
                        ),
                      ),
                      child: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF8AA7A1)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showDutyPharmacySheet(BuildContext context, List<dynamic> list) {
    final today = list.isNotEmpty ? list.first : null;
    final tomorrow = list.length > 1 ? list[1] : null;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DutyTile(
                  label: 'Bugünün nöbetçi eczanesi',
                  name: (today?.name ?? '-') as String,
                  phone: (today?.phone ?? '') as String,
                  color: const Color(0xFF009688),
                ),
                const SizedBox(height: 10),
                _DutyTile(
                  label: 'Yarının nöbetçi eczanesi',
                  name: (tomorrow?.name ?? 'Yarın için veri henüz yayınlanmadı') as String,
                  phone: (tomorrow?.phone ?? '') as String,
                  color: const Color(0xFF1E88E5),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PharmacyScreen()),
                      );
                    },
                    icon: const Icon(Icons.list_alt_rounded),
                    label: const Text('Tüm eczane listesini aç'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DutyTile extends StatelessWidget {
  const _DutyTile({
    required this.label,
    required this.name,
    required this.phone,
    required this.color,
  });

  final String label;
  final String name;
  final String phone;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.local_pharmacy_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                if (phone.trim().isNotEmpty)
                  Text(
                    phone,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeTopBar extends ConsumerWidget {
  const _HomeTopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 16, 4),
        child: Row(
          children: [
            // Logo — dar ekranda aksiyonlara yer açmak için küçülür
            Expanded(
              child: ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: const _BrandWordmark()
                        .animate()
                        .fadeIn(duration: 420.ms)
                        .slideX(begin: -0.08, end: 0),
                  ),
                ),
              ),
            ),

            // Action buttons row
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Theme toggle – minimal, icon-only
                _TopBarIconButton(
                  icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  onTap: () {
                    final current = ref.read(themeModeProvider);
                    ref.read(themeModeProvider.notifier).state =
                        current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
                  },
                ).animate().fadeIn(delay: 150.ms).scale(begin: const Offset(0.8, 0.8)),

                const SizedBox(width: 8),

                // Notifications
                _TopBarIconButton(
                  icon: Icons.notifications_none_rounded,
                  onTap: () => TargetRouter.handle(context, 'screen:notifications'),
                ).animate().fadeIn(delay: 180.ms).scale(begin: const Offset(0.8, 0.8)),

                const SizedBox(width: 8),

                // Weather pill
                weatherAsync.when(
                  data: (dynamic w) {
                    final wTheme = weatherVisualTheme(w.conditionCode as int);
                    return GestureDetector(
                      onTap: () => ref.read(currentIndexProvider.notifier).state = 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    wTheme.gradientStart.withValues(alpha: 0.3),
                                    wTheme.gradientEnd.withValues(alpha: 0.18),
                                  ]
                                : [
                                    wTheme.gradientStart.withValues(alpha: 0.15),
                                    wTheme.gradientEnd.withValues(alpha: 0.08),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? wTheme.gradientStart.withValues(alpha: 0.3)
                                : wTheme.gradientStart.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            WeatherAnimatedIcon(
                              conditionCode: w.conditionCode as int,
                              size: 20,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : wTheme.gradientStart,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              '${w.temperature.round()}°',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: isDark ? Colors.white : wTheme.gradientStart,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).scale(begin: const Offset(0.8, 0.8));
                  },
                  loading: () => const SizedBox(width: 60, height: 40),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const SizedBox(width: 8),

                // Search button
                _TopBarIconButton(
                  icon: Icons.search_rounded,
                  onTap: () => TargetRouter.handle(context, 'screen:search'),
                ).animate().fadeIn(delay: 280.ms).scale(begin: const Offset(0.8, 0.8)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable minimal icon button for the top bar.
class _TopBarIconButton extends StatelessWidget {
  const _TopBarIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDark
                ? Colors.white.withValues(alpha: 0.8)
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
      ),
    );
  }
}

class _SponsorStrip extends StatelessWidget {
  const _SponsorStrip({required this.items});

  final List<MediaSponsorItem> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 178,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final item = items[index];
          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => LauncherUtils.openUrlExternal(context, item.targetUrl),
            child: Container(
              width: 284,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.black.withValues(alpha: 0.4) 
                        : AppColors.textDark.withValues(alpha: 0.16),
                    blurRadius: 18,
                    spreadRadius: -6,
                    offset: const Offset(0, 10),
                  ),
                ],
                image: DecorationImage(
                  image: NetworkImage(item.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.68),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.badge,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: items.length,
      ),
    );
  }
}

class _BrandWordmark extends StatelessWidget {
  const _BrandWordmark();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'HEPSİ',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.8,
                    fontSize: 18,
                    height: 1.0,
                  ),
            ),
            const SizedBox(width: 5),
            ClipPath(
              clipper: _BrandLogoCapsuleClipper(),
              child: Container(
                height: 28,
                padding: const EdgeInsets.only(left: 20, right: 10),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFE3AF4C),
                ),
                child: Text(
                  'DÜZİÇİ',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.black.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        fontSize: 17,
                        height: 1,
                      ),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 1, left: 74),
          child: Text(
            "Akdeniz'in İncisi",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w700,
                  fontSize: 8.5,
                  letterSpacing: 0.1,
                  height: 1,
                ),
          ),
        ),
      ],
    );
  }
}

class _BrandLogoCapsuleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    // Image 1'deki karakteristik sola yatık kavis
    path.moveTo(size.height * 0.6, 0); // Üst sol kavis başlangıcı
    path.quadraticBezierTo(0, 0, 0, size.height); // Sol kavis
    path.lineTo(size.width - 8, size.height); // Alt sağ (hafif yuvarlaklık için pay)
    path.quadraticBezierTo(size.width, size.height, size.width, size.height * 0.7); // Sağ alt köşe yuvarlatma
    path.lineTo(size.width, 0); // Sağ üst köşe (keskin)
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
