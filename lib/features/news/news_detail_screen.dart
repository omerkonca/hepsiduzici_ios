import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/launcher_utils.dart';
import '../../data/models/news_item.dart';

/// Haber tıklanınca açılan ayrı sayfa: tam metin (kaynaktan çekilir) + kaynağa link.
class NewsDetailScreen extends ConsumerWidget {
  const NewsDetailScreen({super.key, required this.item});

  final NewsItem item;

  static String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays > 0) return '${diff.inDays} gün önce';
    if (diff.inHours > 0) return '${diff.inHours} saat önce';
    if (diff.inMinutes > 0) return '${diff.inMinutes} dakika önce';
    return 'Az önce';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = item.sourceUrl != null && item.sourceUrl!.isNotEmpty
        ? ref.watch(newsArticleDetailsProvider(item.sourceUrl))
        : null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Haber'),
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? Theme.of(context).colorScheme.surface 
            : Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: detailsAsync != null
          ? detailsAsync.when(
              data: (details) => _buildBody(
                context,
                bodyText: details.fullText ?? item.summary,
                imageUrl: item.imageUrl ?? details.imageUrl,
              ),
              loading: () => _buildBody(context, bodyText: item.summary, showLoading: true),
              error: (_, __) => _buildBody(context, bodyText: item.summary),
            )
          : _buildBody(context, bodyText: item.summary),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    String? bodyText,
    String? imageUrl,
    bool showLoading = false,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 160,
                  color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                  child: Icon(Icons.image_not_supported_rounded, size: 48, color: Theme.of(context).disabledColor),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          Text(
            item.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (item.sourceName != null && item.sourceName!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.sourceName!,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Text(
                _formatDate(item.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (showLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else if (bodyText != null && bodyText.trim().isNotEmpty)
            Text(
              bodyText.trim(),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.65,
                  ),
            ),
          if (item.sourceUrl != null && item.sourceUrl!.isNotEmpty) ...[
            const SizedBox(height: 28),
            Text(
              'Haberi kaynak sitede okuyabilirsiniz.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => LauncherUtils.openUrlExternal(context, item.sourceUrl!),
                icon: const Icon(Icons.open_in_new_rounded, size: 20),
                label: const Text('Habere git'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
