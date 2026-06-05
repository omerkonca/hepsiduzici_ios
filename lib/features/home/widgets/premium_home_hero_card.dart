import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/premium_city_theme.dart';
import '../../../core/utils/target_router.dart';
import '../../../core/utils/weather_wmo_tr.dart';
import '../../../data/models/prayer_times.dart';
import '../../../data/models/weather_info.dart';

class PremiumHomeHeroCard extends ConsumerWidget {
  const PremiumHomeHeroCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weather = ref.watch(weatherProvider).asData?.value;
    final prayer = ref.watch(prayerTimesProvider).asData?.value;
    final pharmacy = ref.watch(pharmacyListProvider).asData?.value;
    final unread = ref.watch(unreadNotificationsCountProvider);

    final now = DateTime.now();
    final currentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final nextPrayer =
        prayer?.nextPrayer(currentTime) ?? prayer?.allTimes.first;
    final pharmacyName =
        pharmacy?.isNotEmpty == true ? pharmacy!.first.name : 'Aydın Eczanesi';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CityHeader(unread: unread),
        const SizedBox(height: 10),
        _LiveCityCard(
          weather: weather,
          prayerTitle: _prayerDisplayName(nextPrayer?.name ?? 'Akşam'),
          prayerTime: nextPrayer?.time ?? '20:15',
          prayerCountdown: prayer == null
              ? '1s 12dk kaldı'
              : _prayerCountdownTr(prayer, nextPrayer?.time ?? '20:15', now),
          pharmacyName: pharmacyName,
        ),
      ],
    );
  }

  static String _prayerDisplayName(String name) {
    if (name.contains('Namaz')) return name;
    return '$name Namazı';
  }

  static String _prayerCountdownTr(
    PrayerTimes prayer,
    String nextTime,
    DateTime now,
  ) {
    final parts = nextTime.split(':');
    if (parts.length != 2) return '';
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return '';

    var target = DateTime(now.year, now.month, now.day, hour, minute);
    final current =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    if (nextTime.compareTo(current) <= 0) {
      target = target.add(const Duration(days: 1));
    }

    final diff = target.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (hours > 0) return '${hours}s ${minutes}dk kaldı';
    if (minutes > 0) return '${minutes}dk kaldı';
    return 'Vakit geldi';
  }
}

class _CityHeader extends StatelessWidget {
  const _CityHeader({required this.unread});

  final int unread;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: PremiumCityTheme.navyGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: PremiumCityTheme.softShadow(
              color: PremiumCityTheme.navy,
              alpha: 0.18,
            ),
          ),
          child: const Icon(Icons.location_on_rounded,
              color: Colors.white, size: 17),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DÜZİÇİ',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: PremiumCityTheme.navy,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.9,
                  height: 0.95,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Doğasıyla, tarihiyle, insanıyla güzel ilçemiz',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: PremiumCityTheme.ink,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        _HeaderIconButton(
          icon: Icons.notifications_none_rounded,
          badge: unread,
          onTap: () => TargetRouter.handle(context, 'screen:notifications'),
        ),
        const SizedBox(width: 8),
        _HeaderIconButton(
          icon: Icons.person_rounded,
          onTap: () => TargetRouter.handle(context, 'screen:more'),
        ),
      ],
    );
  }
}

class _LiveCityCard extends StatelessWidget {
  const _LiveCityCard({
    required this.weather,
    required this.prayerTitle,
    required this.prayerTime,
    required this.prayerCountdown,
    required this.pharmacyName,
  });

  final WeatherInfo? weather;
  final String prayerTitle;
  final String prayerTime;
  final String prayerCountdown;
  final String pharmacyName;

  @override
  Widget build(BuildContext context) {
    final temperature =
        weather == null ? '19°C' : '${weather!.temperature.round()}°C';
    final condition = weather?.conditionText.isNotEmpty == true
        ? weather!.conditionText
        : 'Parçalı Bulutlu';
    final wind = windSummaryTr(weather?.windSpeed, weather?.windGust);
    final weatherIcon = weatherCodeIcon(
      weather?.conditionCode ?? 2,
      isDay: weather?.isDay ?? true,
    );

    return Container(
      height: 178,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: PremiumCityTheme.softShadow(
          color: PremiumCityTheme.navy,
          alpha: 0.22,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/karasu_selalesi.jpg',
              fit: BoxFit.cover,
              alignment: const Alignment(0.16, -0.08),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.35, -0.45),
                  radius: 1.20,
                  colors: [
                    Colors.black.withValues(alpha: 0.10),
                    PremiumCityTheme.navy.withValues(alpha: 0.28),
                    Colors.black.withValues(alpha: 0.66),
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.12),
                    Colors.black.withValues(alpha: 0.30),
                    Colors.black.withValues(alpha: 0.62),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      const SizedBox.shrink(),
                      const Spacer(),
                      _HeroPhotoBadge(
                        icon: Icons.castle_rounded,
                        label: 'Düziçi Kalesi',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _WeatherBlock(
                            temperature: temperature,
                            condition: condition,
                            wind: wind,
                            icon: weatherIcon,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PrayerBlock(
                            title: prayerTitle,
                            time: prayerTime,
                            countdown: prayerCountdown,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 7),
                  _PharmacyBar(pharmacyName: pharmacyName),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 420.ms, curve: Curves.easeOutCubic).scale(
          begin: const Offset(0.98, 0.98),
          end: const Offset(1, 1),
          duration: 420.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

// ignore: unused_element
class _HeroLiveBadge extends StatelessWidget {
  const _HeroLiveBadge();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

// ignore: unused_element
class _UnusedHeroPhotoBadgeView extends StatelessWidget {
  const _UnusedHeroPhotoBadgeView({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.24),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.55),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              const Text(
                'CANLI ŞEHİR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroPhotoBadge extends StatelessWidget {
  const _HeroPhotoBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

// ignore: unused_element
class _HeroPhotoBadgeView extends StatelessWidget {
  const _HeroPhotoBadgeView({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: const Color(0xFFFFD56A), size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _GlassInfoPanel extends StatelessWidget {
  const _GlassInfoPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _WeatherBlock extends StatelessWidget {
  const _WeatherBlock({
    required this.temperature,
    required this.condition,
    required this.wind,
    required this.icon,
  });

  final String temperature;
  final String condition;
  final String wind;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              temperature,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 26,
                height: 1,
                letterSpacing: -0.7,
              ),
            ),
            const SizedBox(width: 4),
            Icon(icon, color: const Color(0xFFFFD56A), size: 22),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          condition,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 11,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          wind,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.88),
            fontWeight: FontWeight.w600,
            fontSize: 9.5,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

class _PrayerBlock extends StatelessWidget {
  const _PrayerBlock({
    required this.title,
    required this.time,
    required this.countdown,
  });

  final String title;
  final String time;
  final String countdown;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 10.5,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Icon(
              Icons.mosque_rounded,
              color: Color(0xFFFFD56A),
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              time,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 24,
                height: 1,
                letterSpacing: -0.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          countdown,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.88),
            fontWeight: FontWeight.w600,
            fontSize: 9.5,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

class _PharmacyBar extends StatelessWidget {
  const _PharmacyBar({required this.pharmacyName});

  final String pharmacyName;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Material(
          color: Colors.black.withValues(alpha: 0.32),
          child: InkWell(
            onTap: () => TargetRouter.handle(context, 'screen:pharmacy'),
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_pharmacy_rounded,
                      color: Color(0xFF22C55E),
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nöbetçi Eczane',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFFFFD56A),
                            fontWeight: FontWeight.w800,
                            fontSize: 10.5,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          pharmacyName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFD56A),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: PremiumCityTheme.navy.withValues(alpha: 0.9),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(21),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(21),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE7ECF2)),
                boxShadow: PremiumCityTheme.softShadow(alpha: 0.06),
              ),
              child: Icon(icon, color: PremiumCityTheme.navy, size: 19),
            ),
          ),
        ),
        if (badge > 0)
          Positioned(
            right: -1,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 3),
              decoration: const BoxDecoration(
                color: Color(0xFFE53935),
                shape: BoxShape.circle,
              ),
              child: Text(
                badge > 99 ? '99+' : '$badge',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
