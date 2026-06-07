import 'package:flutter/material.dart';

import '../../../core/theme/premium_city_theme.dart';
import '../../../core/utils/target_router.dart';
import 'home_stories_strip.dart';

class DiscoverPlacesStrip extends StatelessWidget {
  const DiscoverPlacesStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Düziçi’ni Keşfet',
          onTap: () => TargetRouter.handle(context, 'screen:explore'),
        ),
        const SizedBox(height: PremiumCityTheme.sectionHeaderGap),
        const HomeStoriesStrip(),
      ],
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
            foregroundColor: PremiumCityTheme.ink.withValues(alpha: 0.72),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tümü', style: TextStyle(fontWeight: FontWeight.w800)),
              SizedBox(width: 3),
              Icon(Icons.chevron_right_rounded, size: 18),
            ],
          ),
        ),
      ],
    );
  }
}
