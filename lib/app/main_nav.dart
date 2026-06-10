import 'dart:async';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui' as ui;
import '../data/services/notification_service.dart';
import '../core/ads/ad_service.dart';
import '../core/push/push_notification_service.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/app_navigation.dart';
import '../core/widgets/app_banner_ad.dart';
import '../data/models/news_item.dart';
import '../data/models/stamped_data.dart';
import '../data/services/news_notification_utils.dart';
import '../features/events/events_screen.dart';
import '../features/explore/explore_screen.dart';
import '../features/home/home_screen.dart';
import '../features/more/more_screen.dart';
import '../features/news/news_detail_screen.dart';
import '../features/news/news_screen.dart';
import 'news_update_banner.dart';
import 'providers.dart';

class MainNav extends ConsumerStatefulWidget {
  const MainNav({super.key});

  @override
  ConsumerState<MainNav> createState() => _MainNavState();
}

class _MainNavState extends ConsumerState<MainNav> with WidgetsBindingObserver {
  String? _pendingNewsTapKey;
  bool _openingFromNotification = false;
  StreamSubscription<String>? _tapSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Bildirim tıklamalarını dinle ve anında yönlendir
    _tapSubscription = NotificationService.tapController.stream.listen((payload) {
      _handleDirectNotificationTap(payload);
    });

    Future.microtask(() async {
      await _loadPendingNewsTap();
      await _checkNewsOnResume();
      await _syncReminders();
      await _registerPushToken();
      AdService.instance.startSessionTimer();
    });
  }

  @override
  void dispose() {
    _tapSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    AdService.instance.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(appLifecycleStateProvider.notifier).state = state;
    final isForeground = state == AppLifecycleState.resumed;
    AdService.instance.onAppLifecycle(isForeground);
    if (isForeground) {
      _loadPendingNewsTap(); // Arka plandan tıklanarak gelindiyse kontrol et
      _checkNewsOnResume();
      _syncReminders();
      _registerPushToken();
    }
  }

  void _handleDirectNotificationTap(String payload) {
    if (payload.trim().isEmpty) return;
    _pendingNewsTapKey = payload.trim();
    final stamped = ref.read(stampedNewsProvider).valueOrNull;
    if (stamped != null) {
      _tryOpenPendingNews(stamped.data);
    } else {
      ref.invalidate(stampedNewsProvider);
    }
  }

  Future<void> _registerPushToken() async {
    if (kIsWeb) return;
    final notify = ref.read(notificationServiceProvider);
    await PushNotificationService.instance.ensureRegistered(notify);
  }

  Future<void> _syncReminders() async {
    if (kIsWeb) return;
    final prayer = ref.read(stampedPrayerProvider).valueOrNull?.data;
    final pharmacies = ref.read(stampedPharmacyProvider).valueOrNull?.data;
    await ref.read(reminderSchedulerServiceProvider).syncAll(
          prayerTimes: prayer,
          pharmacies: pharmacies,
        );
  }

  /// Arka plan görevleri her cihazda güvenilir değil; açılış / ön plana dönüşte kontrol.
  Future<void> _checkNewsOnResume() async {
    if (kIsWeb) return;

    final prefs = ref.read(notificationPreferencesServiceProvider);
    final enabled = await prefs.getSystemTrayNewNews();
    if (!enabled) return;

    final notify = ref.read(notificationServiceProvider);
    var granted = await notify.areSystemNotificationsEnabled();
    if (!granted && !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      await notify.ensureNotificationPermissions();
      granted = await notify.areSystemNotificationsEnabled();
    }
    if (!granted) return;

    await notify.checkAndNotifyNewHeadline();
    ref.invalidate(stampedNewsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ref.listen<AsyncValue<Stamped<List<NewsItem>>>>(
      stampedNewsProvider,
      (_, next) {
        final stamped = next.asData?.value;
        if (stamped == null) return;
        Future.microtask(() async {
          if (!context.mounted) return;
          await handleStampedNewsNotification(context, ref, stamped);
          _tryOpenPendingNews(stamped.data);
        });
      },
    );
    ref.listen(stampedPrayerProvider, (_, __) => _syncReminders());
    ref.listen(stampedPharmacyProvider, (_, __) => _syncReminders());

    final index = ref.watch(currentIndexProvider);
    return Scaffold(
      appBar: null,
      body: IndexedStack(
        index: index,
        children: [
          const SizedBox.expand(child: HomeScreen()),
          const SafeArea(child: SizedBox.expand(child: NewsScreen())),
          const SafeArea(child: SizedBox.expand(child: ExploreScreen())),
          const SafeArea(child: SizedBox.expand(child: EventsScreen())),
          const SafeArea(child: SizedBox.expand(child: MoreScreen())),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SafeArea(
            minimum: EdgeInsets.zero,
            bottom: false,
            child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 28,
                  spreadRadius: -12,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.white.withValues(alpha: 0.72)),
                    color: isDark
                        ? const Color(0xE11A1A1A)
                        : const Color(0xEBFFFFFF),
                  ),
                  child: SizedBox(
                    height: 64,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: _NavItem(
                              iconAsset: 'assets/icons/nav/home_outline.svg',
                              selectedIconAsset:
                                  'assets/icons/nav/home_filled.svg',
                              fallbackIcon: Icons.home_outlined,
                              selectedFallbackIcon: Icons.home_rounded,
                              label: 'Ana Sayfa',
                              selected: index == 0,
                              onTap: () => _switchTab(0),
                            ),
                          ),
                          Expanded(
                            child: _NavItem(
                              iconAsset:
                                  'assets/icons/nav/services_outline.svg',
                              selectedIconAsset:
                                  'assets/icons/nav/services_filled.svg',
                              fallbackIcon: Icons.article_outlined,
                              selectedFallbackIcon: Icons.article_rounded,
                              label: 'Haberler',
                              selected: index == 1,
                              onTap: () => _switchTab(1),
                            ),
                          ),
                          Expanded(
                            child: _NavItem(
                              iconAsset:
                                  'assets/icons/nav/discover_outline.svg',
                              selectedIconAsset:
                                  'assets/icons/nav/discover_filled.svg',
                              fallbackIcon: Icons.explore_outlined,
                              selectedFallbackIcon: Icons.explore_rounded,
                              label: 'Keşfet',
                              selected: index == 2,
                              onTap: () => _switchTab(2),
                            ),
                          ),
                          Expanded(
                            child: _NavItem(
                              iconAsset: 'assets/icons/nav/events_outline.svg',
                              selectedIconAsset:
                                  'assets/icons/nav/events_filled.svg',
                              fallbackIcon: Icons.event_outlined,
                              selectedFallbackIcon: Icons.event_rounded,
                              label: 'Etkinlik',
                              selected: index == 3,
                              onTap: () => _switchTab(3),
                            ),
                          ),
                          Expanded(
                            child: _NavItem(
                              iconAsset: 'assets/icons/nav/more_outline.svg',
                              selectedIconAsset:
                                  'assets/icons/nav/more_filled.svg',
                              fallbackIcon: Icons.more_horiz_outlined,
                              selectedFallbackIcon: Icons.more_horiz_rounded,
                              label: 'Daha Fazla',
                              selected: index == 4,
                              onTap: () => _switchTab(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
          ),
          const AppBannerAd(),
        ],
      ),
    );
  }

  void _switchTab(int i) {
    final current = ref.read(currentIndexProvider);
    if (current == i) return;
    HapticFeedback.selectionClick();
    ref.read(currentIndexProvider.notifier).state = i;
  }

  Future<void> _loadPendingNewsTap() async {
    final payload =
        await ref.read(notificationServiceProvider).consumePendingNewsTap();
    if (!mounted || payload == null || payload.trim().isEmpty) return;
    _pendingNewsTapKey = payload.trim();
    final stamped = ref.read(stampedNewsProvider).valueOrNull;
    if (stamped != null) {
      _tryOpenPendingNews(stamped.data);
    } else {
      ref.invalidate(stampedNewsProvider);
    }
  }

  void _tryOpenPendingNews(List<NewsItem> items) {
    if (!mounted || _openingFromNotification || _pendingNewsTapKey == null) {
      return;
    }
    final key = _pendingNewsTapKey!.trim();
    NewsItem? target;
    for (final item in items) {
      final trackingKey = NewsNotificationUtils.headlineTrackingKey(item);
      if (trackingKey == key ||
          item.id.trim() == key ||
          item.title.trim() == key) {
        target = item;
        break;
      }
    }
    if (target == null) return;

    _openingFromNotification = true;
    _pendingNewsTapKey = null;
    ref.read(currentIndexProvider.notifier).state = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await AppNavigation.push<void>(context, NewsDetailScreen(item: target!));
      _openingFromNotification = false;
    });
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.selected,
    required this.iconAsset,
    required this.fallbackIcon,
  });

  final bool selected;
  final String iconAsset;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : const Color(0xFF8A9099);
    final size = selected ? 20.0 : 19.5;
    return Icon(fallbackIcon, size: size, color: color);
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.iconAsset,
    required this.selectedIconAsset,
    required this.fallbackIcon,
    required this.selectedFallbackIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String iconAsset;
  final String selectedIconAsset;
  final IconData fallbackIcon;
  final IconData selectedFallbackIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: AppColors.primary.withValues(alpha: 0.16),
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: selected
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            border: selected
                ? Border.all(
                    color: AppColors.primary.withValues(alpha: 0.22), width: 1)
                : Border.all(color: Colors.transparent),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.24),
                      blurRadius: 18,
                      spreadRadius: -7,
                      offset: const Offset(0, 7),
                    ),
                    BoxShadow(
                      color: const Color(0xFFFFD66D).withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: -9,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: EdgeInsets.all(selected ? 4.5 : 0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? Colors.white.withValues(alpha: 0.9)
                      : Colors.transparent,
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.22),
                            blurRadius: 12,
                            spreadRadius: -3,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.94, end: selected ? 1.06 : 1.0),
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) {
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _NavIcon(
                        selected: selected,
                        iconAsset: selected ? selectedIconAsset : iconAsset,
                        fallbackIcon:
                            selected ? selectedFallbackIcon : fallbackIcon,
                      ),
                      if (selected)
                        Positioned(
                          top: -3,
                          right: -4,
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFD66D),
                              shape: BoxShape.circle,
                            ),
                          ).animate(onPlay: (c) => c.repeat()).fadeOut(
                                duration: 850.ms,
                                begin: 1,
                              ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  height: 1.1,
                  fontSize: selected ? 10.2 : 9.8,
                  letterSpacing: -0.1,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? AppColors.primary : const Color(0xFF7F8690),
                ),
              ),
              if (selected)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 14,
                  height: 2,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ).animate().fadeIn(duration: 140.ms),
            ],
          ),
        ),
      ),
    );
  }
}
