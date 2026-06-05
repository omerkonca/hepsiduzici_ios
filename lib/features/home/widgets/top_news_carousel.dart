import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/news_item.dart';
import '../../news/news_detail_screen.dart';

/// Ana sayfanın en üstündeki büyük, kaydırmalı haber kartı.
/// Yatay PageView + alt indicator + otomatik geçiş (5 sn).
class TopNewsCarousel extends ConsumerStatefulWidget {
  const TopNewsCarousel({
    super.key,
    this.height = 188,
    this.maxItems = 5,
    this.category = 'Düziçi',
  });

  final double height;
  final int maxItems;
  final String category;

  @override
  ConsumerState<TopNewsCarousel> createState() => _TopNewsCarouselState();
}

class _TopNewsCarouselState extends ConsumerState<TopNewsCarousel> {
  late final PageController _controller = PageController(viewportFraction: 0.92);
  Timer? _timer;
  int _index = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startAutoSwipe(int len) {
    _timer?.cancel();
    if (len <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_index + 1) % len;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(newsListProvider);
    return async.when(
      data: (list) {
        final filtered = list.where((n) {
          return n.category == widget.category;
        }).toList();
        final items = filtered.take(widget.maxItems).toList();
        
        if (items.isEmpty) return _empty(context);
        
        // Reset index and timer if category changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _startAutoSwipe(items.length);
        });

        return _content(context, items);
      },
      loading: () => SizedBox(
        height: widget.height + 24,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => _empty(context),
    );
  }

  Widget _content(BuildContext context, List<NewsItem> items) {
    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _controller,
            itemCount: items.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final item = items[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _NewsCard(
                  item: item,
                  badgeLabel: widget.category,
                  onTap: () => _open(context, item),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        _Indicators(count: items.length, current: _index),
      ],
    );
  }

  Widget _empty(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.softGrey.withValues(alpha: 0.5)),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.article_outlined, size: 38, color: AppColors.textMuted.withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            Text(
              "${widget.category} haberleri yakında burada",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, NewsItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NewsDetailScreen(item: item)),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({
    required this.item,
    required this.badgeLabel,
    required this.onTap,
  });
  final NewsItem item;
  final String badgeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final badgeColor = badgeLabel == 'Osmaniye' ? AppColors.accentBlue : AppColors.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppColors.cardOverlay,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Positioned.fill(
                  child: item.imageUrl != null && item.imageUrl!.trim().isNotEmpty
                      ? Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[100],
                              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            );
                          },
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/images/duzici_castle_header.png',
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          'assets/images/duzici_castle_header.png',
                          fit: BoxFit.cover,
                        ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.08),
                        Colors.black.withValues(alpha: 0.52),
                        Colors.black.withValues(alpha: 0.86),
                      ],
                      stops: const [0.05, 0.55, 1],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: badgeColor.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              badgeLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w900,
                              height: 1.2,
                              letterSpacing: -0.3,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded, color: Colors.white.withValues(alpha: 0.7), size: 12),
                              const SizedBox(width: 4),
                              Text(
                                _relativeTime(item.createdAt),
                                style: TextStyle(
                                  color: AppColors.white.withValues(alpha: 0.85),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (item.sourceName != null && item.sourceName!.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: Container(
                                    width: 3,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.5),
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
                                      color: AppColors.white.withValues(alpha: 0.7),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16),
                          width: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.black.withValues(alpha: 0.18),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.14),
                          ],
                          stops: const [0.0, 0.48, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _relativeTime(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays > 0) return '${diff.inDays} gün önce';
    if (diff.inHours > 0) return '${diff.inHours} saat önce';
    if (diff.inMinutes > 0) return '${diff.inMinutes} dakika önce';
    return 'Az önce';
  }
}

class _Indicators extends StatelessWidget {
  const _Indicators({required this.count, required this.current});
  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 6,
          height: 5,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.softGrey.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
