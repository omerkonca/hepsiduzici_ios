import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/premium_city_theme.dart';
import '../../core/utils/launcher_utils.dart';
import '../../core/utils/target_router.dart';
import '../../core/widgets/app_pressable.dart';
import '../../data/models/city_content.dart';

/// Google Play Haber toplayıcı politikası: üçüncü taraf kaynak şeffaflığı.
class NewsSourcesScreen extends ConsumerWidget {
  const NewsSourcesScreen({super.key});

  static String _publisherSite(String rssUrl) {
    try {
      final uri = Uri.parse(rssUrl);
      return '${uri.scheme}://${uri.host}';
    } catch (_) {
      return rssUrl;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cityContentProvider);

    return Scaffold(
      backgroundColor: PremiumCityTheme.canvas,
      appBar: AppBar(
        title: const Text('Haber Kaynakları'),
        backgroundColor: PremiumCityTheme.canvas,
        foregroundColor: PremiumCityTheme.ink,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _ErrorBody(onRetry: () => ref.invalidate(cityContentProvider)),
        data: (content) => _SourcesBody(sources: content.newsSources),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Kaynak listesi yüklenemedi.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Tekrar dene')),
          ],
        ),
      ),
    );
  }
}

class _SourcesBody extends StatelessWidget {
  const _SourcesBody({required this.sources});

  final List<NewsSourceItem> sources;

  @override
  Widget build(BuildContext context) {
    final active = sources.where((s) => s.isActive && s.name.isNotEmpty).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: PremiumCityTheme.card(radius: 20),
          child: const Text(
            'Hepsi Düziçi bir haber toplayıcıdır. Uygulamada gördüğünüz '
            'haberler aşağıdaki bağımsız yayıncılardan alınır. Her haber '
            'detayında orijinal yayıncı adı ve kaynak bağlantısı gösterilir.',
            style: TextStyle(
              color: PremiumCityTheme.ink,
              fontSize: 14,
              height: 1.55,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Aktif kaynaklar (${active.length})',
          style: const TextStyle(
            color: PremiumCityTheme.ink,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        if (active.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Henüz kaynak tanımlanmamış.',
              style: TextStyle(color: PremiumCityTheme.muted),
            ),
          )
        else
          ...active.map((source) {
            final site = NewsSourcesScreen._publisherSite(source.url);
            return AppPressable(
              onTap: () => LauncherUtils.openUrlExternal(context, site),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: PremiumCityTheme.card(radius: 18),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: PremiumCityTheme.navy.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.newspaper_rounded,
                        color: PremiumCityTheme.navy,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            source.name,
                            style: const TextStyle(
                              color: PremiumCityTheme.ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            site,
                            style: const TextStyle(
                              color: PremiumCityTheme.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.open_in_new_rounded, color: PremiumCityTheme.muted, size: 20),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 8),
        AppPressable(
          onTap: () => TargetRouter.handle(context, 'screen:contact'),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: PremiumCityTheme.navyGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(Icons.support_agent_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bize Ulaşın',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        AppConfig.contactEmail,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
