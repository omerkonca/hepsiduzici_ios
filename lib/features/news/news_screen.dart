import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/primary_card.dart';
import '../../core/widgets/service_page_layout.dart';
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

    return async.when(
      data: (List<NewsItem> allNews) {
        final categories = ['Düziçi', 'Osmaniye'];
        final filteredNews = allNews.where((n) => n.category == selectedCategory).toList();

        return ServicePageLayout(
          title: 'Haberler',
          subtitle: '$selectedCategory ve çevresinden en son gelişmeler.',
          icon: 'newspaper',
          color: const Color(0xFF1E88E5),
          onRefresh: () async => ref.invalidate(newsListProvider),
          isEmpty: filteredNews.isEmpty,
          emptyMessage: '$selectedCategory için henüz bir haber bulunmamaktadır.',
          child: SliverMainAxisGroup(
            slivers: [
              // Category Selector
              SliverToBoxAdapter(
                child: Container(
                  height: 44,
                  margin: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final isSelected = cat == selectedCategory;
                      return GestureDetector(
                        onTap: () => ref.read(_newsCategoryProvider.notifier).state = cat,
                        child: AnimatedContainer(
                          duration: 250.ms,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Theme.of(context).disabledColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : [],
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Theme.of(context).textTheme.bodySmall?.color,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // News List
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final n = filteredNews[index];
                    return _NewsListCard(
                      item: n,
                      onTap: () => _openDetail(context, n),
                    ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: 0.05, end: 0);
                  },
                  childCount: filteredNews.length,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Yüklenemedi: $e'))),
    );
  }

  void _openDetail(BuildContext context, NewsItem n) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NewsDetailScreen(item: n),
      ),
    );
  }
}

class _NewsListCard extends StatelessWidget {
  const _NewsListCard({required this.item, required this.onTap});

  final NewsItem item;
  final VoidCallback onTap;

  static const double _thumbSize = 92;

  @override
  Widget build(BuildContext context) {
    return PrimaryCard(
      onTap: onTap,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: _thumbSize,
              height: _thumbSize,
              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(context),
                    )
                  : _placeholder(context),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (item.sourceName != null && item.sourceName!.isNotEmpty) ...[
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.sourceName!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      _formatDate(item.createdAt),
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    FavoriteButton(
                      id: item.id, // News items are identified by ID
                      category: FavoriteCategory.news,
                      size: 18,
                      padding: const EdgeInsets.all(4),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Haberi oku',
                      style: TextStyle(
                        color: AppColors.primary.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: AppColors.primary.withValues(alpha: 0.8),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
      alignment: Alignment.center,
      child: Icon(Icons.article_outlined, color: Theme.of(context).disabledColor, size: 24),
    );
  }

  static String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays > 0) return '${diff.inDays} gün önce';
    if (diff.inHours > 0) return '${diff.inHours} saat önce';
    if (diff.inMinutes > 0) return '${diff.inMinutes} dakika önce';
    return 'Az önce';
  }
}
