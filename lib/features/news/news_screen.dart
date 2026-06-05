import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/premium_city_theme.dart';
import '../../core/utils/relative_time.dart';
import '../../core/widgets/favorite_button.dart';
import '../../data/models/news_item.dart';
import '../../data/services/favorites_service.dart';
import 'news_detail_screen.dart';

final _newsCategoryProvider = StateProvider<String>((ref) => 'Düziçi');

class NewsScreen extends ConsumerWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(newsListProvider);
    final selectedCategory = ref.watch(_newsCategoryProvider);

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: PremiumCityTheme.canvas,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFDFBF4),
            Color(0xFFF6F7FB),
            Color(0xFFEFF3F8),
          ],
        ),
      ),
      child: async.when(
        data: (allNews) {
          final categories = _categoriesFor(allNews);
          final filteredNews =
              allNews.where((n) => n.category == selectedCategory).toList();
          final headline = filteredNews.isNotEmpty ? filteredNews.first : null;
          final rest = filteredNews.length > 1
              ? filteredNews.sublist(1)
              : const <NewsItem>[];

          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: Colors.white,
            onRefresh: () async {
              ref.invalidate(stampedNewsProvider);
              ref.invalidate(newsListProvider);
              await Future<void>.delayed(const Duration(milliseconds: 450));
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 4)),
                SliverToBoxAdapter(
                  child: _NewsHeader(
                    category: selectedCategory,
                    totalCount: filteredNews.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                SliverToBoxAdapter(
                  child: _CategoryRail(
                    categories: categories,
                    selected: selectedCategory,
                    onChanged: (cat) =>
                        ref.read(_newsCategoryProvider.notifier).state = cat,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                if (headline != null)
                  SliverToBoxAdapter(
                    child: _HeadlineCard(
                      item: headline,
                      onTap: () => _openDetail(context, headline),
                    ).animate().fadeIn(duration: 360.ms).slideY(
                          begin: 0.04,
                          end: 0,
                          duration: 360.ms,
                          curve: Curves.easeOutCubic,
                        ),
                  )
                else
                  const SliverToBoxAdapter(child: _EmptyNewsState()),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                if (rest.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        PremiumCityTheme.pagePadding, 0, PremiumCityTheme.pagePadding, 88),
                    sliver: SliverList.separated(
                      itemCount: rest.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = rest[index];
                        return _PremiumNewsCard(
                          item: item,
                          onTap: () => _openDetail(context, item),
                        ).animate(delay: (index * 35).ms).fadeIn(
                              duration: 300.ms,
                              curve: Curves.easeOutCubic,
                            );
                      },
                    ),
                  )
                else
                  const SliverToBoxAdapter(child: SizedBox(height: 88)),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Haberler yüklenemedi: $e',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }

  static List<String> _categoriesFor(List<NewsItem> news) {
    final values = <String>{'Düziçi', 'Osmaniye'};
    for (final item in news) {
      if (item.category.trim().isNotEmpty) values.add(item.category);
    }
    return values.toList();
  }

  void _openDetail(BuildContext context, NewsItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => NewsDetailScreen(item: item)),
    );
  }
}

class _NewsHeader extends StatelessWidget {
  const _NewsHeader({required this.category, required this.totalCount});

  final String category;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PremiumCityTheme.pagePadding),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: PremiumCityTheme.navyGradient,
          boxShadow: PremiumCityTheme.softShadow(
            color: PremiumCityTheme.navy,
            alpha: 0.18,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -26,
              top: -34,
              child: Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                  ),
                  child: const Icon(
                    Icons.article_rounded,
                    color: PremiumCityTheme.gold,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Haberler',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.65,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$category gündemi, son dakika ve yerel gelişmeler',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.76),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _LiveBadge(count: totalCount),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
              ).animate(onPlay: (c) => c.repeat()).fadeOut(
                    begin: 1,
                    duration: 900.ms,
                  ),
              const SizedBox(width: 6),
              Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryRail extends StatelessWidget {
  const _CategoryRail({
    required this.categories,
    required this.selected,
    required this.onChanged,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: PremiumCityTheme.pagePadding),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selected;
          return GestureDetector(
            onTap: () => onChanged(category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? PremiumCityTheme.gold : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected
                      ? PremiumCityTheme.gold
                      : const Color(0xFFE5EAF1),
                ),
                boxShadow: isSelected
                    ? PremiumCityTheme.softShadow(alpha: 0.10)
                    : null,
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : PremiumCityTheme.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 11.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeadlineCard extends StatelessWidget {
  const _HeadlineCard({required this.item, required this.onTap});

  final NewsItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PremiumCityTheme.pagePadding),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            height: 192,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: PremiumCityTheme.softShadow(alpha: 0.16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _NewsImage(url: item.imageUrl),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x18000000),
                          Color(0x330F2744),
                          Color(0xE80F2744),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: _SourceChip(label: item.sourceName ?? 'Gündem'),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17.5,
                            fontWeight: FontWeight.w900,
                            height: 1.08,
                            letterSpacing: -0.35,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              color: Colors.white.withValues(alpha: 0.82),
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                RelativeTime.format(item.createdAt),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.82),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            FavoriteButton(
                              id: item.id,
                              category: FavoriteCategory.news,
                              size: 17,
                              padding: const EdgeInsets.all(5),
                            ),
                          ],
                        ),
                      ],
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

class _PremiumNewsCard extends StatelessWidget {
  const _PremiumNewsCard({required this.item, required this.onTap});

  final NewsItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8EDF4)),
            boxShadow: PremiumCityTheme.softShadow(alpha: 0.07),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 88,
                  height: 76,
                  child: _NewsImage(url: item.imageUrl),
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
                          child: _SourceChip(
                            label: item.sourceName ?? item.category,
                            compact: true,
                          ),
                        ),
                        const Spacer(),
                        FavoriteButton(
                          id: item.id,
                          category: FavoriteCategory.news,
                          size: 15,
                          padding: const EdgeInsets.all(4),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PremiumCityTheme.ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        height: 1.14,
                        letterSpacing: -0.12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          color: PremiumCityTheme.muted,
                          size: 12,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            RelativeTime.format(item.createdAt),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: PremiumCityTheme.muted,
                              fontWeight: FontWeight.w700,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: PremiumCityTheme.gold,
                          size: 15,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.label, this.compact = false});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 7 : 8,
            vertical: compact ? 3 : 5,
          ),
          decoration: BoxDecoration(
            color: compact
                ? PremiumCityTheme.gold.withValues(alpha: 0.13)
                : Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: compact
                  ? PremiumCityTheme.gold.withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.18),
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: compact ? PremiumCityTheme.gold : Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: compact ? 9 : 10,
            ),
          ),
        ),
      ),
    );
  }
}

class _NewsImage extends StatelessWidget {
  const _NewsImage({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Image.asset('assets/images/duzici_castle_header.png',
          fit: BoxFit.cover);
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Image.asset(
        'assets/images/duzici_castle_header.png',
        fit: BoxFit.cover,
      ),
    );
  }
}

class _EmptyNewsState extends StatelessWidget {
  const _EmptyNewsState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PremiumCityTheme.pagePadding),
      child: Container(
        height: 148,
        alignment: Alignment.center,
        decoration: PremiumCityTheme.card(radius: 22),
        child: const Text(
          'Bu kategori için henüz haber yok.',
          style: TextStyle(
            color: PremiumCityTheme.muted,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
