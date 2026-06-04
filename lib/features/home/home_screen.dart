import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_section_header.dart';
import '../../core/utils/app_navigation.dart';
import '../../core/utils/target_router.dart';
import '../../core/utils/weather_wmo_tr.dart';
import '../news/news_screen.dart';
import '../pharmacy/pharmacy_screen.dart';
import 'widgets/highlights_strip.dart';
import 'widgets/home_stories_strip.dart';
import 'widgets/quick_actions_row.dart';
import 'widgets/top_news_carousel.dart';

final _homeNewsCategoryProvider = StateProvider<String>((ref) => 'Düziçi');

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(autoRefreshProvider);
    ref.watch(cityContentProvider); // arka planda yenile
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
          const SliverToBoxAdapter(child: _PremiumTopBar()),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
          const SliverToBoxAdapter(child: HomeStoriesStrip()),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // 0) Nöbetçi Eczane — header altında kompakt satır
          SliverToBoxAdapter(
            child: const _DutyPharmacyCard()
                .animate(delay: 60.ms)
                .fadeIn(duration: 300.ms),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // 1) Anlık şerit
          SliverToBoxAdapter(
            child: const AppSectionHeader(title: 'Anlık Bilgiler', compact: true)
                .animate(delay: 100.ms)
                .fadeIn(duration: 280.ms),
          ),
          SliverToBoxAdapter(
            child: const HighlightsStrip()
                .animate(delay: 140.ms)
                .fadeIn(duration: 320.ms)
                .slideX(begin: 0.05, end: 0),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 22)),

          // 2) Haberler
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: AppSectionHeader(
                      title: '$selectedCategory Haberleri',
                      actionLabel: 'Tümü',
                      onAction: () => _push(context, const NewsScreen()),
                      compact: true,
                      padding: const EdgeInsets.fromLTRB(20, 6, 16, 12),
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

          // 3) Hızlı erişim — haberlerin altında
          SliverToBoxAdapter(
            child: const AppSectionHeader(title: 'Hızlı Erişim', compact: true)
                .animate(delay: 380.ms)
                .fadeIn(duration: 280.ms),
          ),
          SliverToBoxAdapter(
            child: const QuickActionsRow()
                .animate(delay: 420.ms)
                .fadeIn(duration: 320.ms)
                .slideY(begin: 0.06, end: 0),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget page) {
    AppNavigation.push<void>(context, page);
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
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => onChanged(cat),
              child: AnimatedContainer(
                duration: 220.ms,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            Color.lerp(selectedColor, Colors.white, 0.15)!,
                            selectedColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : Theme.of(context).dividerColor.withValues(alpha: 0.15),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: selectedColor.withValues(alpha: 0.32),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      Icon(
                        cat == 'Osmaniye' ? Icons.location_city_rounded : Icons.home_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      cat,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).textTheme.bodySmall?.color,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
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
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showDutyPharmacySheet(context, list),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isDark
                      ? const Color(0xFF004D40).withValues(alpha: 0.55)
                      : const Color(0xFFE8F5E9),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF26A69A).withValues(alpha: 0.35)
                        : const Color(0xFFA5D6A7),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    // İkon
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF26A69A), Color(0xFF00897B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(Icons.local_pharmacy_rounded, color: Colors.white, size: 21),
                    ),
                    const SizedBox(width: 14),
                    
                    // Eczane Detayları (Nöbetçi etiketi + Eczane İsmi)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00897B),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'NÖBETÇİ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 8.5,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Bugün',
                                style: TextStyle(
                                  color: isDark ? Colors.white60 : const Color(0xFF546E7A),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p.name,
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF1B5E20),
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // Telefon Numarası
                    if (p.phone.isNotEmpty) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            p.phone,
                            style: TextStyle(
                              color: isDark ? Colors.white70 : const Color(0xFF2E7D32),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Dokun & Ara',
                            style: TextStyle(
                              color: isDark ? Colors.white38 : const Color(0xFF78909C),
                              fontWeight: FontWeight.w600,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 6),
                    ],
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: isDark
                          ? Colors.white38
                          : const Color(0xFF009688).withValues(alpha: 0.6),
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
                      AppNavigation.push<void>(context, const PharmacyScreen());
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


// =====================================================================
// PREMIUM TOP BAR
// =====================================================================

class _GreetingTheme {
  final List<Color> gradientColors;
  final Color borderColor;
  final Color shadowColor;
  final IconData icon;
  final List<Color> iconGradientColors;
  final Color textColor;
  final Color subTextColor;
  final Color badgeBgColor;
  final Color badgeTextColor;

  const _GreetingTheme({
    required this.gradientColors,
    required this.borderColor,
    required this.shadowColor,
    required this.icon,
    required this.iconGradientColors,
    required this.textColor,
    required this.subTextColor,
    required this.badgeBgColor,
    required this.badgeTextColor,
  });
}

class _PremiumTopBar extends ConsumerWidget {
  const _PremiumTopBar();

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return 'İyi Geceler';
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'İyi Günler';
    return 'İyi Akşamlar';
  }

  static String _formattedDateShort() {
    return DateFormat('d MMM EEE', 'tr_TR').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherProvider);
    final greeting = _greeting();
    final dateShort = _formattedDateShort();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hour = DateTime.now().hour;
    final isNight = hour >= 20 || hour < 6;
    final isEvening = hour >= 17 && hour < 20;

    final weather = weatherAsync.asData?.value;
    final int? condition = weather?.conditionCode;
    final wType = condition != null ? weatherVisualType(condition) : null;

    final _GreetingTheme gTheme;

    if (isNight) {
      gTheme = isDark
          ? const _GreetingTheme(
              gradientColors: [Color(0xFF0F172A), Color(0xFF020617)],
              borderColor: Color(0x2238BDF8),
              shadowColor: Color(0xFF020617),
              icon: Icons.nightlight_round,
              iconGradientColors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
              textColor: Colors.white,
              subTextColor: Color(0xFF94A3B8),
              badgeBgColor: Color(0x1F38BDF8),
              badgeTextColor: Color(0xFF38BDF8),
            )
          : const _GreetingTheme(
              gradientColors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              borderColor: Color(0x3338BDF8),
              shadowColor: Color(0x1F0F172A),
              icon: Icons.nightlight_round,
              iconGradientColors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
              textColor: Colors.white,
              subTextColor: Color(0xFF94A3B8),
              badgeBgColor: Color(0x2438BDF8),
              badgeTextColor: Color(0xFF38BDF8),
            );
    } else if (isEvening) {
      gTheme = isDark
          ? const _GreetingTheme(
              gradientColors: [Color(0xFF2E1065), Color(0xFF4C1D95)],
              borderColor: Color(0x22C084FC),
              shadowColor: Color(0xFF2E1065),
              icon: Icons.wb_twilight_rounded,
              iconGradientColors: [Color(0xFFE9D5FF), Color(0xFFC084FC)],
              textColor: Colors.white,
              subTextColor: Color(0xFFD8B4FE),
              badgeBgColor: Color(0x1FC084FC),
              badgeTextColor: Color(0xFFE9D5FF),
            )
          : const _GreetingTheme(
              gradientColors: [Color(0xFFFFF1F2), Color(0xFFFAE8FF)],
              borderColor: Color(0x22F43F5E),
              shadowColor: Color(0x0CF43F5E),
              icon: Icons.wb_twilight_rounded,
              iconGradientColors: [Color(0xFFF43F5E), Color(0xFFD946EF)],
              textColor: Color(0xFF4C0519),
              subTextColor: Color(0xFF881337),
              badgeBgColor: Color(0x1AF43F5E),
              badgeTextColor: Color(0xFFBE123C),
            );
    } else if (wType == WeatherVisualType.rainy || wType == WeatherVisualType.stormy) {
      gTheme = isDark
          ? const _GreetingTheme(
              gradientColors: [Color(0xFF0C4A6E), Color(0xFF082F49)],
              borderColor: Color(0x2238BDF8),
              shadowColor: Color(0xFF082F49),
              icon: Icons.umbrella_rounded,
              iconGradientColors: [Color(0xFF7DD3FC), Color(0xFF38BDF8)],
              textColor: Colors.white,
              subTextColor: Color(0xFFBAE6FD),
              badgeBgColor: Color(0x1F38BDF8),
              badgeTextColor: Color(0xFF7DD3FC),
            )
          : const _GreetingTheme(
              gradientColors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE)],
              borderColor: Color(0x220EA5E9),
              shadowColor: Color(0x0C0EA5E9),
              icon: Icons.umbrella_rounded,
              iconGradientColors: [Color(0xFF38BDF8), Color(0xFF0EA5E9)],
              textColor: Color(0xFF0369A1),
              subTextColor: Color(0xFF0284C7),
              badgeBgColor: Color(0x1A0EA5E9),
              badgeTextColor: Color(0xFF0369A1),
            );
    } else if (wType == WeatherVisualType.cloudy || wType == WeatherVisualType.foggy) {
      gTheme = isDark
          ? const _GreetingTheme(
              gradientColors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              borderColor: Color(0x2294A3B8),
              shadowColor: Color(0xFF0F172A),
              icon: Icons.cloud_rounded,
              iconGradientColors: [Color(0xFFCBD5E1), Color(0xFF94A3B8)],
              textColor: Colors.white,
              subTextColor: Color(0xFF94A3B8),
              badgeBgColor: Color(0x1F94A3B8),
              badgeTextColor: Color(0xFFCBD5E1),
            )
          : const _GreetingTheme(
              gradientColors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
              borderColor: Color(0x2294A3B8),
              shadowColor: Color(0x0C94A3B8),
              icon: Icons.cloud_rounded,
              iconGradientColors: [Color(0xFF94A3B8), Color(0xFF64748B)],
              textColor: Color(0xFF334155),
              subTextColor: Color(0xFF475569),
              badgeBgColor: Color(0x1A64748B),
              badgeTextColor: Color(0xFF475569),
            );
    } else {
      gTheme = isDark
          ? const _GreetingTheme(
              gradientColors: [Color(0xFF78350F), Color(0xFF451A03)],
              borderColor: Color(0x22F59E0B),
              shadowColor: Color(0xFF451A03),
              icon: Icons.wb_sunny_rounded,
              iconGradientColors: [Color(0xFFFDE047), Color(0xFFF59E0B)],
              textColor: Colors.white,
              subTextColor: Color(0xFFFDE047),
              badgeBgColor: Color(0x1FF59E0B),
              badgeTextColor: Color(0xFFFDE047),
            )
          : const _GreetingTheme(
              gradientColors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
              borderColor: Color(0x22F59E0B),
              shadowColor: Color(0x0CF59E0B),
              icon: Icons.wb_sunny_rounded,
              iconGradientColors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              textColor: Color(0xFF78350F),
              subTextColor: Color(0xFF92400E),
              badgeBgColor: Color(0x1AF59E0B),
              badgeTextColor: Color(0xFFB45309),
            );
    }

    final logoColor =
        isNight || isEvening || isDark ? Colors.white : AppColors.textDark;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gTheme.gradientColors,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: gTheme.borderColor),
            boxShadow: [
              BoxShadow(
                color: gTheme.shadowColor.withValues(alpha: 0.08),
                blurRadius: 14,
                spreadRadius: -4,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              _CompactLogo(textColor: logoColor),
              const SizedBox(width: 8),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gTheme.iconGradientColors,
                  ),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(gTheme.icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$greeting 👋',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: gTheme.textColor,
                        letterSpacing: -0.3,
                        height: 1.15,
                      ),
                    ),
                    Text(
                      '$dateShort · Akdeniz\'in İncisi',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: gTheme.subTextColor,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Consumer(
                builder: (context, ref, child) {
                  final unreadCount = ref.watch(unreadNotificationsCountProvider);
                  final badgeLabel = unreadCount > 99 ? '99+' : unreadCount.toString();
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _ActionButtonDynamic(
                        icon: Icons.notifications_none_rounded,
                        color: gTheme.textColor,
                        onTap: () => TargetRouter.handle(context, 'screen:notifications'),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: unreadCount > 9 ? 4 : 5,
                              vertical: 2,
                            ),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE53935),
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                            child: Text(
                              badgeLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 6),
              weatherAsync.when(
                data: (w) => GestureDetector(
                  onTap: () => TargetRouter.handle(context, 'screen:weather'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: gTheme.textColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: gTheme.textColor.withValues(alpha: 0.16)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        WeatherAnimatedIcon(
                          conditionCode: w.conditionCode,
                          isDay: w.isDay,
                          size: 14,
                          color: gTheme.textColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${w.temperature.round()}°',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12.5,
                            color: gTheme.textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                loading: () => const SizedBox(width: 44, height: 30),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ).animate(delay: 80.ms).fadeIn(duration: 350.ms).slideY(begin: 0.04, end: 0),
    );
  }
}

class _CompactLogo extends StatelessWidget {
  const _CompactLogo({required this.textColor});

  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'HEPSİ',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: textColor,
            letterSpacing: -0.6,
            fontSize: 15,
            height: 1,
          ),
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE3AF4C), Color(0xFFD4941A)],
            ),
            borderRadius: BorderRadius.circular(5),
          ),
          child: const Text(
            'DÜZİÇİ',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 11.5,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButtonDynamic extends StatelessWidget {
  const _ActionButtonDynamic({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: color.withValues(alpha: 0.15),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.18),
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 19,
          ),
        ),
      ),
    );
  }
}
