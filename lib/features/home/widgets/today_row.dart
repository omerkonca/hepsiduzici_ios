import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/weather_wmo_tr.dart';
import '../../../data/models/prayer_times.dart';
import '../../../data/models/weather_info.dart';

/// Hava durumu ve namaz vakti yan yana premium kartlar.
class TodayRow extends ConsumerWidget {
  const TodayRow({super.key});

  static const double _iconSize = 32;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherProvider);
    final prayerAsync = ref.watch(prayerTimesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Bugün',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: weatherAsync.when(
                  data: (WeatherInfo w) => _TodayCard(
                    icon: weatherCodeIcon(w.conditionCode),
                    iconColor: AppColors.accentBlue,
                    label: 'Hava',
                    value: '${w.temperature.round()}°C',
                    sub: '${w.conditionText}\n${windSummaryTr(w.windSpeed, w.windGust)}',
                  )
                      .animate(delay: 80.ms)
                      .fadeIn(duration: 380.ms, curve: Curves.easeOut)
                      .scale(begin: const Offset(0.88, 0.88), end: const Offset(1, 1), curve: Curves.easeOutBack),
                  loading: () => const _TodayCardSkeleton(),
                  error: (_, __) => _TodayCard(
                    icon: Icons.wb_cloudy_rounded,
                    iconColor: AppColors.textMuted,
                    label: 'Hava',
                    value: '--',
                    sub: 'Yüklenemedi',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: prayerAsync.when(
                  data: (PrayerTimes p) {
                    final now = DateTime.now();
                    final current =
                        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
                    final next = p.nextPrayer(current) ?? p.allTimes.first;
                    return _TodayCard(
                      icon: Icons.mosque_rounded,
                      iconColor: AppColors.primaryDark,
                      label: 'Sıradaki vakit',
                      value: next.time,
                      sub: next.name,
                    )
                        .animate(delay: 180.ms)
                        .fadeIn(duration: 380.ms, curve: Curves.easeOut)
                        .scale(begin: const Offset(0.88, 0.88), end: const Offset(1, 1), curve: Curves.easeOutBack);
                  },
                  loading: () => const _TodayCardSkeleton(),
                  error: (_, __) => _TodayCard(
                    icon: Icons.mosque_rounded,
                    iconColor: AppColors.textMuted,
                    label: 'Vakit',
                    value: '--',
                    sub: 'Yüklenemedi',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.sub,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: TodayRow._iconSize, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
          ),
          Text(
            sub,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _TodayCardSkeleton extends StatelessWidget {
  const _TodayCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 60,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 80,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
