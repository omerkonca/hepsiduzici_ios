import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_card.dart';
import '../../../data/models/news_item.dart';

class NewsCardList extends ConsumerWidget {
  const NewsCardList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(newsListProvider);
    return async.when(
      data: (List<NewsItem> list) {
        if (list.isEmpty) {
          return PrimaryCard(
            child: Text(
              'Henüz haber yok.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...list.take(3).map(
                  (n) => PrimaryCard(
                    onTap: () {},
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          n.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (n.sourceName?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Text(
                            n.sourceName!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                        if (n.summary != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            n.summary!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textMuted,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
          ],
        );
      },
      loading: () => PrimaryCard(
        child: Row(
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 16),
            Text(
              'Haberler yükleniyor...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      error: (_, __) => PrimaryCard(
        child: Text(
          'Haberler yüklenemedi',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
