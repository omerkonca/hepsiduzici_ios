import 'package:flutter/material.dart';

import '../../../core/theme/premium_city_theme.dart';
import '../../../core/utils/target_router.dart';

class QuickAccessSection extends StatelessWidget {
  const QuickAccessSection({super.key});

  static const _cardBg = Color(0xFFFAFAF8);
  static const _cardBorder = Color(0xFFEBEEF3);

  @override
  Widget build(BuildContext context) {
    const items = [
      _AccessItem('Taksi', Icons.local_taxi_rounded, Color(0xFFE5A800),
          'screen:taxi'),
      _AccessItem('Ulaşım', Icons.directions_bus_filled_rounded,
          Color(0xFF2B7BB9), 'screen:transport'),
      _AccessItem('Belediye', Icons.account_balance_rounded,
          Color(0xFF3D8B37), 'screen:municipality'),
      _AccessItem('Haberler', Icons.article_rounded, Color(0xFFE0453A),
          'screen:news'),
      _AccessItem('Namaz Vakitleri', Icons.mosque_rounded,
          Color(0xFF2D6B3F), 'screen:prayer'),
      _AccessItem('Gezi Rehberi', Icons.terrain_rounded,
          Color(0xFF7B5EAD), 'screen:explore_nature'),
      _AccessItem('Etkinlikler', Icons.event_available_rounded,
          Color(0xFFE08A2E), 'screen:calendar'),
      _AccessItem('Acil Durum', Icons.phone_in_talk_rounded,
          Color(0xFFE03E2F), 'screen:emergency'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Hızlı Erişim',
          onTap: () => TargetRouter.handle(context, 'screen:municipality'),
        ),
        const SizedBox(height: PremiumCityTheme.sectionHeaderGap),
        GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            mainAxisExtent: 82,
          ),
          itemBuilder: (context, index) => _QuickAccessCard(item: items[index]),
        ),
      ],
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({required this.item});

  final _AccessItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => TargetRouter.handle(context, item.target),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: QuickAccessSection._cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: QuickAccessSection._cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, color: item.color, size: 26),
                const SizedBox(height: 5),
                Text(
                  item.title,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PremiumCityTheme.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 9.5,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: PremiumCityTheme.ink,
              fontWeight: FontWeight.w900,
              fontSize: PremiumCityTheme.sectionTitleSize,
              letterSpacing: -0.3,
            ),
          ),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF8B7355),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tümü',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              SizedBox(width: 2),
              Icon(Icons.chevron_right_rounded, size: 18),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccessItem {
  const _AccessItem(this.title, this.icon, this.color, this.target);

  final String title;
  final IconData icon;
  final Color color;
  final String target;
}
