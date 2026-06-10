import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/launcher_utils.dart';
import '../../core/utils/target_router.dart';
import '../../core/widgets/app_banner_ad.dart';
import '../../core/widgets/publisher_contact_strip.dart';
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
        actions: [
          IconButton(
            tooltip: 'Bize Ulaşın',
            onPressed: () => TargetRouter.handle(context, 'screen:contact'),
            icon: const Icon(Icons.support_agent_rounded),
          ),
        ],
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
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 220,
                  color: Theme.of(context).disabledColor.withValues(alpha: 0.05),
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
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
          _PublisherCard(item: item, dateLabel: _formatDate(item.createdAt)),
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
          const SizedBox(height: 20),
          const AppBannerAd(inline: true),
          if (item.sourceUrl != null && item.sourceUrl!.isNotEmpty) ...[
            const SizedBox(height: 28),
            Text(
              'Bu haber bağımsız bir yayıncıdan alınmıştır. Tam metin ve güncel '
              'içerik için orijinal kaynağı ziyaret edin.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => LauncherUtils.openUrlExternal(context, item.sourceUrl!),
                icon: const Icon(Icons.open_in_new_rounded, size: 20),
                label: Text(
                  item.sourceName?.isNotEmpty == true
                      ? '${item.sourceName} sitesinde oku'
                      : 'Orijinal kaynağı aç',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => TargetRouter.handle(context, 'screen:news_sources'),
            icon: const Icon(Icons.newspaper_rounded, size: 18),
            label: const Text('Tüm haber kaynaklarını gör'),
          ),
          const SizedBox(height: 12),
          const PublisherContactStrip(
            compact: true,
            margin: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _PublisherCard extends StatelessWidget {
  const _PublisherCard({required this.item, required this.dateLabel});

  final NewsItem item;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    final publisher = item.sourceName?.trim().isNotEmpty == true
        ? item.sourceName!.trim()
        : 'Bilinmeyen yayıncı';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryDark.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Yayıncı / Kaynak',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            publisher,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Yayın tarihi: $dateLabel',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Uygulama yayıncısı: ${AppConfig.publisherName}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
          ),
        ],
      ),
    );
  }
}
