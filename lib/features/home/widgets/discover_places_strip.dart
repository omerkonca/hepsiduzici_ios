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
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: places.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
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
      borderRadius: BorderRadius.circular(17),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: SizedBox(
          width: 108,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(place.image, fit: BoxFit.cover),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xD9000000)],
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                    child: Text(
                      place.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
