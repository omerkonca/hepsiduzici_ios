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
        const SizedBox(height: 12),
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: PremiumCityTheme.navyGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: PremiumCityTheme.softShadow(
              color: PremiumCityTheme.navy,
              alpha: 0.18,
            ),
          ),
          child: const Icon(
            Icons.location_on_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: ShaderMask(
                      shaderCallback: (rect) {
                        return const LinearGradient(
                          colors: [
                            PremiumCityTheme.navy,
                            Color(0xFF173B64),
                          ],
                        ).createShader(rect);
                      },
                      child: const Text(
                        'HEPSİ DÜZİÇİ',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                          height: 0.96,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: PremiumCityTheme.gold,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: PremiumCityTheme.gold.withValues(alpha: 0.55),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              const Text(
                'Akdeniz’in incisi Düziçi',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: PremiumCityTheme.ink,
                  fontSize: 11.2,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
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
      height: 184,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: PremiumCityTheme.softShadow(
          color: PremiumCityTheme.navy,
          alpha: 0.23,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/duzici_castle_header.png',
              fit: BoxFit.cover,
              alignment: const Alignment(0.05, -0.10),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.06),
                    Colors.black.withValues(alpha: 0.18),
                    Colors.black.withValues(alpha: 0.48),
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    PremiumCityTheme.navy.withValues(alpha: 0.56),
                    Colors.transparent,
                    PremiumCityTheme.navy.withValues(alpha: 0.48),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => TargetRouter.handle(context, 'screen:weather'),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                child: _WeatherBlock(
                                  temperature: temperature,
                                  condition: condition,
                                  wind: wind,
                                  icon: weatherIcon,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => TargetRouter.handle(context, 'screen:prayer'),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                child: _PrayerBlock(
                                  title: prayerTitle,
                                  time: prayerTime,
                                  countdown: prayerCountdown,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
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
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.topLeft,
      child: Column(
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
                  fontSize: 27,
                  height: 1,
                  letterSpacing: 0,
                  shadows: [
                    Shadow(
                      color: Color(0xAA000000),
                      blurRadius: 12,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Icon(icon, color: const Color(0xFFFFD56A), size: 23),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            condition,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
              height: 1.1,
              shadows: [
                Shadow(
                  color: Color(0x99000000),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            wind,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.90),
              fontWeight: FontWeight.w700,
              fontSize: 10,
              height: 1.1,
            ),
          ),
        ],
      ),
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
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.topRight,
      child: Column(
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
              fontWeight: FontWeight.w800,
              fontSize: 10.8,
              height: 1.1,
              shadows: [
                Shadow(
                  color: Color(0x99000000),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Icon(
                Icons.mosque_rounded,
                color: Color(0xFFFFD56A),
                size: 16,
              ),
              const SizedBox(width: 5),
              Text(
                time,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 25,
                  height: 1,
                  letterSpacing: 0,
                  shadows: [
                    Shadow(
                      color: Color(0xAA000000),
                      blurRadius: 12,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            countdown,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.90),
              fontWeight: FontWeight.w700,
              fontSize: 10,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _PharmacyBar extends StatelessWidget {
  const _PharmacyBar({required this.pharmacyName});

  final String pharmacyName;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => TargetRouter.handle(context, 'screen:pharmacy'),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: PremiumCityTheme.navy.withValues(alpha: 0.74),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
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
                        fontWeight: FontWeight.w900,
                        fontSize: 10.4,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      pharmacyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11.3,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 27,
                height: 27,
                decoration: BoxDecoration(
                  gradient: PremiumCityTheme.goldGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: PremiumCityTheme.gold.withValues(alpha: 0.32),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
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
          color: Colors.white.withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(21),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(21),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: PremiumCityTheme.softShadow(alpha: 0.065),
              ),
              child: Icon(icon, color: PremiumCityTheme.navy, size: 19),
            ),
          ),
        ),
        if (badge > 0)
          Positioned(
            right: -2,
            top: -5,
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
