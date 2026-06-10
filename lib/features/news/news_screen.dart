import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/premium_city_theme.dart';
import '../../core/utils/relative_time.dart';
import '../../core/utils/target_router.dart';
import '../../core/widgets/publisher_contact_strip.dart';
import '../../data/models/news_item.dart';
import 'news_detail_screen.dart';

class NewsScreen extends ConsumerStatefulWidget {
  const NewsScreen({super.key});

  @override
  ConsumerState<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends ConsumerState<NewsScreen> {
  late final PageController _pageController =
      PageController(viewportFraction: 1);
  Timer? _autoTimer;
  int _current = 0;
  String _selectedScope = 'Düziçi';

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide(int count) {
    _autoTimer?.cancel();
    if (count <= 1) return;
    _autoTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final next = (_current + 1) % count;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(newsListProvider);

    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.white),
      child: async.when(
        data: (allNews) {
          final duziciNews = allNews.where(_isDuziciNews).toList();
          final osmaniyeNews =
              allNews.where((item) => !_isDuziciNews(item)).toList();
          final selectedNews =
              _selectedScope == 'Düziçi' ? duziciNews : osmaniyeNews;
          final visibleNews = selectedNews.isNotEmpty ? selectedNews : allNews;
          final headlines = visibleNews.take(16).toList();
          final latest =
              visibleNews.length > 1 ? visibleNews.sublist(1) : visibleNews;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _startAutoSlide(headlines.length);
          });

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
                const SliverToBoxAdapter(child: SizedBox(height: 6)),
                const SliverToBoxAdapter(child: PublisherContactStrip()),
                SliverToBoxAdapter(
                  child: _LatestTicker(
                    items: allNews.take(10).toList(),
                    onTap: (item) => _openDetail(context, item),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                SliverToBoxAdapter(
                  child: _NewsScopeTabs(
                    selected: _selectedScope,
                    duziciCount: duziciNews.length,
                    osmaniyeCount: osmaniyeNews.length,
                    onChanged: (scope) {
                      setState(() {
                        _selectedScope = scope;
                        _current = 0;
                      });
                      if (_pageController.hasClients) {
                        _pageController.jumpToPage(0);
                      }
                    },
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                if (headlines.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _HeadlineSlider(
                      controller: _pageController,
                      items: headlines,
                      current: _current,
                      onChanged: (value) => setState(() => _current = value),
                      onTap: (item) => _openDetail(context, item),
                    ).animate().fadeIn(duration: 360.ms),
                  )
                else
                  const SliverToBoxAdapter(child: _EmptyNewsState()),
                const SliverToBoxAdapter(child: SizedBox(height: 18)),
                SliverToBoxAdapter(
                  child: _SectionTitle(
                    title: _selectedScope == 'Düziçi'
                        ? 'Düziçi’den Son Haberler'
                        : 'Osmaniye Genelinden Haberler',
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                if (latest.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 96),
                    sliver: SliverList.separated(
                      itemCount: latest.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final item = latest[index];
                        return _LatestNewsTile(
                          item: item,
                          onTap: () => _openDetail(context, item),
                        )
                            .animate(delay: (index * 24).ms)
                            .fadeIn(duration: 280.ms)
                            .slideY(begin: 0.04, end: 0);
                      },
                    ),
                  )
                else
                  const SliverToBoxAdapter(child: SizedBox(height: 18)),
                if (_selectedScope == 'Tümü' && osmaniyeNews.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: _SectionTitle(title: 'Osmaniye Genelinden Haberler'),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 96),
                    sliver: SliverList.separated(
                      itemCount: osmaniyeNews.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final item = osmaniyeNews[index];
                        return _LatestNewsTile(
                          item: item,
                          onTap: () => _openDetail(context, item),
                        )
                            .animate(delay: (index * 18).ms)
                            .fadeIn(duration: 260.ms)
                            .slideY(begin: 0.035, end: 0);
                      },
                    ),
                  ),
                ] else
                  const SliverToBoxAdapter(child: SizedBox(height: 18)),
                const SliverToBoxAdapter(child: _NewsPolicyFooter()),
                const SliverToBoxAdapter(child: SizedBox(height: 96)),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Haberler yüklenemedi: $error',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }

  bool _isDuziciNews(NewsItem item) {
    final category = _normalize(item.category);
    final title = _normalize(item.title);
    final summary = _normalize(item.summary ?? '');
    return category.contains('duzici') ||
        title.contains('duzici') ||
        summary.contains('duzici') ||
        title.contains('duldul') ||
        summary.contains('duldul');
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('ü', 'u')
        .replaceAll('Ã¼', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('Ã¶', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('Ã§', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ÄŸ', 'g')
        .replaceAll('ş', 's')
        .replaceAll('ÅŸ', 's')
        .replaceAll('ı', 'i')
        .replaceAll('Ä±', 'i');
  }

  void _openDetail(BuildContext context, NewsItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => NewsDetailScreen(item: item)),
    );
  }
}

class _NewsScopeTabs extends StatelessWidget {
  const _NewsScopeTabs({
    required this.selected,
    required this.duziciCount,
    required this.osmaniyeCount,
    required this.onChanged,
  });

  final String selected;
  final int duziciCount;
  final int osmaniyeCount;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4F7),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            _ScopeTabButton(
              label: 'Düziçi',
              count: duziciCount,
              selected: selected == 'Düziçi',
              onTap: () => onChanged('Düziçi'),
            ),
            const SizedBox(width: 6),
            _ScopeTabButton(
              label: 'Osmaniye',
              count: osmaniyeCount,
              selected: selected == 'Osmaniye',
              onTap: () => onChanged('Osmaniye'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScopeTabButton extends StatelessWidget {
  const _ScopeTabButton({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? const Color(0xFF111827)
                      : const Color(0xFF6B7280),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.13)
                      : Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color:
                        selected ? AppColors.primary : const Color(0xFF6B7280),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
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

class _LatestTicker extends StatelessWidget {
  const _LatestTicker({required this.items, required this.onTap});

  final List<NewsItem> items;
  final ValueChanged<NewsItem> onTap;

  @override
  Widget build(BuildContext context) {
    final text = items.isEmpty
        ? 'Düziçi’den son gelişmeler hazırlanıyor'
        : items.map((item) => item.title).join('   •   ');

    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE9EDF3)),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Text(
            'En Yeniler:',
            style: TextStyle(
              color: Color(0xFFE31B23),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: GestureDetector(
              onTap: items.isEmpty ? null : () => onTap(items.first),
              child: _MarqueeText(text: text),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarqueeText extends StatefulWidget {
  const _MarqueeText({required this.text});

  final String text;

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant _MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _controller
        ..reset()
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: Color(0xFF111827),
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
    );

    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final distance = constraints.maxWidth + 900;
              final x = constraints.maxWidth - (_controller.value * distance);
              return Transform.translate(
                offset: Offset(x, 0),
                child: Text(
                  '${widget.text}   •   ${widget.text}',
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: style,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _HeadlineSlider extends StatelessWidget {
  const _HeadlineSlider({
    required this.controller,
    required this.items,
    required this.current,
    required this.onChanged,
    required this.onTap,
  });

  final PageController controller;
  final List<NewsItem> items;
  final int current;
  final ValueChanged<int> onChanged;
  final ValueChanged<NewsItem> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 228,
          child: PageView.builder(
            controller: controller,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            onPageChanged: onChanged,
            itemBuilder: (context, index) {
              final item = items[index];
              return _HeadlineCard(
                item: item,
                onTap: () => onTap(item),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        _NumberedIndicators(count: items.length, current: current),
      ],
    );
  }
}

class _HeadlineCard extends StatelessWidget {
  const _HeadlineCard({required this.item, required this.onTap});

  final NewsItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _NewsImage(url: item.imageUrl, category: item.category),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.05),
                    Colors.black.withValues(alpha: 0.25),
                    Colors.black.withValues(alpha: 0.86),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16.5,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        color: Colors.white.withValues(alpha: 0.74),
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        RelativeTime.format(item.createdAt),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (item.sourceName?.isNotEmpty == true) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          child: Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.55),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            item.sourceName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberedIndicators extends StatelessWidget {
  const _NumberedIndicators({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final visibleCount = count.clamp(0, 16);
    return SizedBox(
      height: 18,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(visibleCount, (index) {
          final selected = index == current;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: selected ? 18 : 12,
            height: selected ? 18 : 12,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color:
                  selected ? const Color(0xFFE31B23) : const Color(0xFFE4E5E8),
              shape: BoxShape.circle,
            ),
            child: selected
                ? Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  )
                : null,
          );
        }),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF111827),
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _LatestNewsTile extends StatelessWidget {
  const _LatestNewsTile({required this.item, required this.onTap});

  final NewsItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 58,
                  height: 58,
                  child:
                      _NewsImage(url: item.imageUrl, category: item.category),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${RelativeTime.format(item.createdAt)}${item.sourceName?.isNotEmpty == true ? " • ${item.sourceName}" : ""}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 13.4,
                        height: 1.28,
                        fontWeight: FontWeight.w800,
                      ),
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

class _NewsImage extends StatelessWidget {
  const _NewsImage({this.url, this.category = 'Düziçi'});

  final String? url;
  final String category;

  String get _placeholderAsset {
    final normalized =
        category.toLowerCase().replaceAll('ü', 'u').replaceAll('Ã¼', 'u');
    if (normalized.contains('osmaniye')) {
      return 'assets/images/duzici_scenic_header.png';
    }
    return 'assets/images/duzici_castle_header.png';
  }

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.trim().isEmpty) {
      return Image.asset(_placeholderAsset, fit: BoxFit.cover);
    }
    return CachedNetworkImage(
      imageUrl: url!,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey.shade100,
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
        ),
      ),
      errorWidget: (_, __, ___) => Image.asset(
        _placeholderAsset,
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
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        height: 148,
        alignment: Alignment.center,
        decoration: PremiumCityTheme.card(radius: 18),
        child: const Text(
          'Henüz haber bulunamadı.',
          style: TextStyle(
            color: PremiumCityTheme.muted,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _NewsPolicyFooter extends StatelessWidget {
  const _NewsPolicyFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: PremiumCityTheme.card(radius: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Haber kaynakları',
              style: TextStyle(
                color: PremiumCityTheme.ink,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Haberler bağımsız yayıncılardan toplanır. Her haberde yayıncı '
              'adı ve orijinal bağlantı gösterilir.',
              style: TextStyle(
                color: PremiumCityTheme.muted,
                fontSize: 12.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () =>
                      TargetRouter.handle(context, 'screen:news_sources'),
                  icon: const Icon(Icons.newspaper_rounded, size: 18),
                  label: const Text('Kaynakları gör'),
                ),
                OutlinedButton.icon(
                  onPressed: () => TargetRouter.handle(context, 'screen:contact'),
                  icon: const Icon(Icons.support_agent_rounded, size: 18),
                  label: const Text('Bize Ulaşın'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
