import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/premium_city_theme.dart';
import '../../../core/utils/relative_time.dart';
import '../../../core/utils/target_router.dart';

class NewsPreviewSection extends ConsumerWidget {
  const NewsPreviewSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final news = ref.watch(newsListProvider).asData?.value ?? const [];
    final first = news.isNotEmpty ? news.first : null;
    final second = news.length > 1 ? news[1] : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Düziçi Haberleri',
          onTap: () => TargetRouter.handle(context, 'screen:news'),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE8EDF4)),
            boxShadow: PremiumCityTheme.softShadow(alpha: 0.075),
          ),
          child: first == null
              ? const SizedBox(
                  height: 118,
                  child: Center(
                    child: Text(
                      'Haberler yükleniyor',
                      style: TextStyle(
                        color: PremiumCityTheme.muted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    _FeaturedNewsRow(item: first),
                    if (second != null) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1),
                      ),
                      _CompactNewsRow(item: second),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _FeaturedNewsRow extends StatelessWidget {
  const _FeaturedNewsRow({required this.item});

  final dynamic item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => TargetRouter.handle(context, 'screen:news'),
      borderRadius: BorderRadius.circular(18),
      child: Row(
        children: [
          _NewsImage(url: item.imageUrl, width: 168, height: 118),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: PremiumCityTheme.gold.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'GÜNDEM',
                    style: TextStyle(
                      color: PremiumCityTheme.gold,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  item.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PremiumCityTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    height: 1.16,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${item.sourceName ?? 'Yerel kaynak'} · ${RelativeTime.format(item.createdAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PremiumCityTheme.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactNewsRow extends StatelessWidget {
  const _CompactNewsRow({required this.item});

  final dynamic item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => TargetRouter.handle(context, 'screen:news'),
      borderRadius: BorderRadius.circular(16),
      child: Row(
        children: [
          _NewsImage(url: item.imageUrl, width: 92, height: 70),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PremiumCityTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    height: 1.18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${item.sourceName ?? 'Yerel kaynak'} · ${RelativeTime.format(item.createdAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PremiumCityTheme.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NewsImage extends StatelessWidget {
  const _NewsImage(
      {required this.url, required this.width, required this.height});

  final String? url;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: SizedBox(
        width: width,
        height: height,
        child: url == null || url!.isEmpty
            ? Image.asset('assets/images/duzici_castle_header.png',
                fit: BoxFit.cover)
            : CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Image.asset(
                  'assets/images/duzici_castle_header.png',
                  fit: BoxFit.cover,
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
        Container(
          width: 5,
          height: 21,
          decoration: BoxDecoration(
            color: PremiumCityTheme.gold,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: PremiumCityTheme.ink,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: -0.35,
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
