import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/premium_city_theme.dart';
import '../../../core/utils/target_router.dart';

class HomePersonalActions extends ConsumerWidget {
  const HomePersonalActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationsCountProvider);
    final favorites = ref.watch(favoritesProvider);
    final favoriteCount =
        favorites.values.fold<int>(0, (sum, ids) => sum + ids.length);

    return Row(
      children: [
        Expanded(
          child: _PersonalActionCard(
            icon: Icons.event_available_rounded,
            title: 'Etkinliklerim',
            value: 'Takvim',
            color: const Color(0xFF7C3AED),
            onTap: () => TargetRouter.handle(context, 'screen:calendar'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PersonalActionCard(
            icon: Icons.favorite_rounded,
            title: 'Favorilerim',
            value: '$favoriteCount kayıt',
            color: const Color(0xFFE11D48),
            onTap: () => TargetRouter.handle(context, 'screen:favorites'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PersonalActionCard(
            icon: Icons.notifications_active_rounded,
            title: 'Bildirimlerim',
            value: unread == 0 ? 'Temiz' : '$unread yeni',
            color: PremiumCityTheme.gold,
            onTap: () => TargetRouter.handle(context, 'screen:notifications'),
          ),
        ),
      ],
    );
  }
}

class _PersonalActionCard extends StatelessWidget {
  const _PersonalActionCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          height: 112,
          padding: const EdgeInsets.all(14),
          decoration: PremiumCityTheme.card(radius: 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PremiumCityTheme.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PremiumCityTheme.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
