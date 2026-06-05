import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/premium_city_theme.dart';

class HomeStatsStrip extends ConsumerWidget {
  const HomeStatsStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventListProvider).asData?.value ?? const [];
    final news = ref.watch(newsListProvider).asData?.value ?? const [];
    final weather = ref.watch(weatherProvider).asData?.value;
    final unread = ref.watch(unreadNotificationsCountProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Şehir Özeti', action: 'Canlı'),
        const SizedBox(height: 12),
        SizedBox(
          height: 126,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              _StatCard(
                title: 'Yaklasan',
                value: '${events.length}',
                label: 'etkinlik',
                icon: Icons.calendar_month_rounded,
                color: const Color(0xFF2563EB),
              ),
              _StatCard(
                title: 'Haber',
                value: '${news.length}',
                label: 'güncel içerik',
                icon: Icons.newspaper_rounded,
                color: const Color(0xFFEA580C),
              ),
              _StatCard(
                title: 'Hava',
                value:
                    weather == null ? '--' : '${weather.temperature.round()}°',
                label: weather?.conditionText.isNotEmpty == true
                    ? weather!.conditionText
                    : 'Düziçi',
                icon: Icons.wb_cloudy_rounded,
                color: const Color(0xFF0891B2),
              ),
              _StatCard(
                title: 'Bildirim',
                value: '$unread',
                label: unread == 0 ? 'okunmamış yok' : 'okunmamış',
                icon: Icons.notifications_rounded,
                color: PremiumCityTheme.gold,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.action});

  final String title;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 20,
          decoration: BoxDecoration(
            color: PremiumCityTheme.gold,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: PremiumCityTheme.ink,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: -0.4,
            ),
          ),
        ),
        Text(
          action,
          style: const TextStyle(
            color: PremiumCityTheme.gold,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 156,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: PremiumCityTheme.card(radius: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              const Spacer(),
              const Icon(Icons.auto_awesome_rounded,
                  color: Color(0xFFD7DEE8), size: 16),
            ],
          ),
          const Spacer(),
          Text(title,
              style: const TextStyle(
                  color: PremiumCityTheme.muted,
                  fontWeight: FontWeight.w800,
                  fontSize: 12)),
          const SizedBox(height: 3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PremiumCityTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 27,
                    letterSpacing: -0.7,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: PremiumCityTheme.muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
