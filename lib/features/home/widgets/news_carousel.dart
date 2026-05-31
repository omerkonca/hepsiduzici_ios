import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/news_item.dart';
import '../../../features/news/news_detail_screen.dart';

/// Ana sayfada Hepsi Düziçi’ye özel haber bölümü. Resimdeki gibi kaydırmalı:
/// ticker + öne çıkan kart + dikey liste ana scroll içinde SliverList ile.
class NewsCarousel extends ConsumerWidget {
  const NewsCarousel({super.key});

  static const double _featureHeight = 220;
  static const double _cardRadius = 18;

  /// Ana sayfada kullan: haber listesi ana kaydırmaya bağlı olur (resimdeki gibi).
  static List<Widget> buildSlivers(BuildContext context, WidgetRef ref) {
    final async = ref.watch(newsListProvider);
    final selectedCategory = ref.watch(selectedNewsCategoryProvider);
    return async.when(
      data: (List<NewsItem> list) {
        if (list.isEmpty) {
          return [SliverToBoxAdapter(child: _buildEmpty(context))];
        }
        final filtered = selectedCategory == null
            ? list
            : list.where((e) => _topicForItem(e) == selectedCategory).toList();
        if (filtered.isEmpty) {
          final cats = _categoriesForChips();
          return [
            SliverToBoxAdapter(child: _newsTickerStrip(list: list)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
                child: Row(
                  children: [
                    Container(width: 4, height: 24, decoration: BoxDecoration(color: AppColors.primaryDark, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Düziçi'den Haberler", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                          const SizedBox(height: 2),
                          Text('Güncel ve geçmiş haberler', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(onPressed: () => ref.invalidate(newsListProvider), icon: const Icon(Icons.refresh_rounded), color: AppColors.primaryDark, tooltip: 'Yenile'),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(child: _NewsCategoryChips(categories: cats, ref: ref)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'Bu kategoride haber yok.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                  ),
                ),
              ),
            ),
          ];
        }
        final categories = _categoriesForChips();
        final isOffline = list.every((e) => e.sourceUrl == null || e.sourceUrl!.isEmpty);
        final featuredCount = filtered.length >= 3 ? 3 : filtered.length;
        final featuredList = filtered.take(featuredCount).toList();
        final restList = filtered.length > featuredCount ? filtered.sublist(featuredCount) : <NewsItem>[];
        return [
          SliverToBoxAdapter(child: _newsTickerStrip(list: filtered)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Düziçi'den Haberler",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Güncel ve geçmiş haberler • Aşağı çekerek yenileyin',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => ref.invalidate(newsListProvider),
                    icon: const Icon(Icons.refresh_rounded),
                    color: AppColors.primaryDark,
                    tooltip: 'Haberleri yenile',
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: _NewsCategoryChips(categories: categories, ref: ref)),
          if (isOffline)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: GestureDetector(
                  onTap: () => ref.invalidate(newsListProvider),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.cloud_off_rounded, size: 18, color: AppColors.textMuted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Haberler sunucudan alinamiyor. Asagi cekip tekrar deneyin.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                height: _featureHeight + 36,
                child: _FeaturedNewsCarousel(
                  items: featuredList,
                  featureHeight: _featureHeight,
                  radius: _cardRadius,
                  onTap: (item) => _openDetail(context, item),
                ),
              ),
            ),
          ),
          if (restList.isNotEmpty) ...[
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = restList[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: index < restList.length - 1 ? 12 : 20),
                      child: _NewsRowTile(
                        item: item,
                        onTap: () => _openDetail(context, item),
                      ),
                    );
                  },
                  childCount: restList.length,
                ),
              ),
            ),
          ] else
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ];
      },
      loading: () => [
        SliverToBoxAdapter(
          child: SizedBox(
            height: _featureHeight + 100,
            child: const Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ),
      ],
      error: (_, __) => [
        SliverToBoxAdapter(child: _buildEmpty(context)),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: buildSlivers(context, ref),
    );
  }

  static Widget _buildEmpty(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(NewsCarousel._cardRadius),
          border: Border.all(
            color: AppColors.textMuted.withValues(alpha: 0.2),
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.article_outlined, size: 40, color: AppColors.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              "Düziçi haberleri burada",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// Resimdeki gibi: "En Yeniler:" kırmızı + yatay kaydırmalı başlıklar (kırmızı nokta ile).
  static Widget _newsTickerStrip({required List<NewsItem> list}) {
    return Container(
      height: 44,
      margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
      color: AppColors.textMuted.withValues(alpha: 0.08),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              'En Yeniler:',
              style: TextStyle(
                color: AppColors.primaryDark,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final title = list[index].title;
                final display = title.length > 35 ? '${title.substring(0, 35)}...' : title;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (index > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    Text(
                      display,
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Konu kategorileri: Ekonomi, Spor, Eğitim vb. (kaynak degil).
  static const List<String> topicCategories = [
    'Spor',
    'Ekonomi',
    'Eğitim',
    'Kültür & Sanat',
    'Belediye',
    'Sağlık',
    'Politika',
    'Genel',
  ];

  static String _topicForItem(NewsItem item) {
    final text = '${item.title} ${item.summary ?? ''}'.toLowerCase();
    if (_hasAny(text, ['spor', 'maç', 'lig', 'futbol', 'basketbol', 'antrenman', 'şampiyon', 'gol', 'transfer', 'sampiyon'])) return 'Spor';
    if (_hasAny(text, ['ekonomi', 'borsa', 'dolar', 'enflasyon', 'faiz', 'yatırım', 'bütçe', 'butce', 'tl ', 'lira'])) return 'Ekonomi';
    if (_hasAny(text, ['eğitim', 'egitim', 'okul', 'öğrenci', 'ogrenci', 'üniversite', 'universite', 'sınav', 'sinav', 'ders', 'öğretmen'])) return 'Eğitim';
    if (_hasAny(text, ['kültür', 'kultur', 'sanat', 'sergi', 'tiyatro', 'konser', 'kitap', 'sinema'])) return 'Kültür & Sanat';
    if (_hasAny(text, ['belediye', 'belediye başkan', 'meclis', 'altyapı', 'altyapi', 'yol', 'park', 'imar', 'temizlik'])) return 'Belediye';
    if (_hasAny(text, ['sağlık', 'saglik', 'hastane', 'doktor', 'aşı', 'asi', 'salgın', 'salgın', 'ilaç', 'ilac'])) return 'Sağlık';
    if (_hasAny(text, ['siyaset', 'parti', 'milletvekili', 'seçim', 'secim', 'akp', 'chp', 'mhp', 'oy'])) return 'Politika';
    return 'Genel';
  }

  static bool _hasAny(String text, List<String> keywords) {
    for (final k in keywords) {
      if (text.contains(k)) return true;
    }
    return false;
  }

  static List<String> _categoriesForChips() => topicCategories;

  static void _openDetail(BuildContext context, NewsItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NewsDetailScreen(item: item),
      ),
    );
  }
}

/// Kategori secimi: Tumu + konu kategorileri (Spor, Ekonomi, Eğitim vb.).
class _NewsCategoryChips extends StatelessWidget {
  const _NewsCategoryChips({required this.categories, required this.ref});

  final List<String> categories;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedNewsCategoryProvider);
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          _Chip(
            label: 'Tümü',
            selected: selected == null,
            onTap: () => ref.read(selectedNewsCategoryProvider.notifier).state = null,
          ),
          ...categories.map(
            (name) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _Chip(
                label: name,
                selected: selected == name,
                onTap: () => ref.read(selectedNewsCategoryProvider.notifier).state = name,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryDark : AppColors.textMuted.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: selected ? AppColors.white : AppColors.textDark,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Öne çıkan haber kartları: yatay kaydırmalı (PageView) + sayfa noktaları.
class _FeaturedNewsCarousel extends StatefulWidget {
  const _FeaturedNewsCarousel({
    required this.items,
    required this.featureHeight,
    required this.radius,
    required this.onTap,
  });

  final List<NewsItem> items;
  final double featureHeight;
  final double radius;
  final void Function(NewsItem item) onTap;

  @override
  State<_FeaturedNewsCarousel> createState() => _FeaturedNewsCarouselState();
}

class _FeaturedNewsCarouselState extends State<_FeaturedNewsCarousel> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.items.length;
    if (count == 0) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: widget.featureHeight,
          child: PageView.builder(
            controller: _pageController,
            itemCount: count,
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _FeaturedNewsCard(
                  item: item,
                  height: widget.featureHeight,
                  radius: widget.radius,
                  onTap: () => widget.onTap(item),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        if (count > 1)
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                count,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: ListenableBuilder(
                    listenable: _pageController,
                    builder: (context, _) {
                      final page = _pageController.hasClients
                          ? (_pageController.page ?? 0).round().clamp(0, count - 1)
                          : 0;
                      final active = page == i;
                      return Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active ? AppColors.primaryDark : AppColors.textMuted.withValues(alpha: 0.3),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: active ? Colors.white : AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Resimdeki dikey liste satırı: solda kare resim, sağda tarih + başlık (beyaz kart).
class _NewsRowTile extends StatelessWidget {
  const _NewsRowTile({required this.item, required this.onTap});

  final NewsItem item;
  final VoidCallback onTap;

  static const double _thumbSize = 80;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: AppColors.textDark.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: _thumbSize,
                  height: _thumbSize,
                  child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatDate(item.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w600,
                            height: 1.28,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

  Widget _placeholder() => Container(
        color: AppColors.cardOverlay.withValues(alpha: 0.5),
        child: Icon(Icons.article_outlined, color: AppColors.textMuted.withValues(alpha: 0.5), size: 28),
      );

  static String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays > 0) return '${diff.inDays} gün önce';
    if (diff.inHours > 0) return '${diff.inHours} saat önce';
    if (diff.inMinutes > 0) return '${diff.inMinutes} dakika önce';
    return 'Az önce';
  }
}

/// Öne çıkan büyük haber kartı (ilk haber).
class _FeaturedNewsCard extends StatelessWidget {
  const _FeaturedNewsCard({
    required this.item,
    required this.height,
    required this.radius,
    required this.onTap,
  });

  final NewsItem item;
  final double height;
  final double radius;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: _TapScaleChild(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: AppColors.textDark.withValues(alpha: 0.14),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                  Image.network(
                    item.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholderGradient(),
                  )
                else
                  _placeholderGradient(),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.5),
                        Colors.black.withValues(alpha: 0.88),
                      ],
                      stops: const [0.35, 0.7, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(radius),
                        bottomLeft: Radius.circular(radius),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (item.sourceName != null && item.sourceName!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item.sourceName!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      if (item.sourceName != null && item.sourceName!.isNotEmpty) const SizedBox(height: 10),
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 1.22,
                          shadows: [
                            Shadow(color: Colors.black38, offset: Offset(0, 1), blurRadius: 6),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(item.createdAt),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholderGradient() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.cardOverlay.withValues(alpha: 0.8),
              AppColors.cardOverlay,
            ],
          ),
        ),
      );

  static String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays > 0) return '${diff.inDays} gün önce';
    if (diff.inHours > 0) return '${diff.inHours} saat önce';
    return 'Az önce';
  }
}

class _TapScaleChild extends StatefulWidget {
  const _TapScaleChild({
    required this.onTap,
    required this.borderRadius,
    required this.child,
  });

  final VoidCallback onTap;
  final BorderRadius borderRadius;
  final Widget child;

  @override
  State<_TapScaleChild> createState() => _TapScaleChildState();
}

class _TapScaleChildState extends State<_TapScaleChild> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}

