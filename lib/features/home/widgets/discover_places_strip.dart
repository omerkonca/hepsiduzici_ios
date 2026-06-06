import 'package:flutter/material.dart';

import '../../../core/theme/premium_city_theme.dart';
import '../../../core/utils/target_router.dart';

class DiscoverPlacesStrip extends StatelessWidget {
  const DiscoverPlacesStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final places = [
      _Place('Karasu\nŞelalesi', 'assets/images/karasu_selalesi.jpg'),
      _Place('Haruniye\nKaplıcaları', 'assets/images/harun_resit.jpg'),
      _Place('Düldül\nDağı', 'assets/images/duldul_mountain_header.png'),
      _Place('Tarihi\nYerler', 'assets/images/toprakkale.jpg'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Düziçi’ni Keşfet',
          onTap: () => TargetRouter.handle(context, 'screen:explore'),
        ),
        const SizedBox(height: PremiumCityTheme.sectionHeaderGap),
        SizedBox(
          height: 115,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: places.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) => _PlaceCard(place: places[index]),
          ),
        ),
      ],
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.place});

  final _Place place;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => TargetRouter.handle(context, 'screen:explore'),
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  place.image,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              place.title.replaceAll('\n', ' '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
                height: 1.15,
              ),
            ),
          ],
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

class _Place {
  const _Place(this.title, this.image);

  final String title;
  final String image;
}
