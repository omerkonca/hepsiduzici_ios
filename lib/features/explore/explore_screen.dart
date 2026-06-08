import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/premium_city_theme.dart';
import '../../core/utils/icon_mapper.dart';
import '../../core/utils/target_router.dart';
import '../../data/models/city_content.dart';
import 'directory_screen.dart';
import 'explore_category_screen.dart';
import 'auto_gallery_screen.dart';
import 'obituary_screen.dart';
import '../veterinary/veterinary_screen.dart';
import '../../core/widgets/place_network_image.dart';
import 'widgets/explore_list_theme.dart';

final _exploreEntryDuration = 320.ms;
const _exploreEntryCurve = Curves.easeOutCubic;

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cityContentProvider);

    return async.when(
      data: (content) {
        final query = ref.watch(exploreSearchQueryProvider).toLowerCase();

        var services = content.cityServices;
        var categories = content.exploreCategories;
        if (categories.isEmpty || categories.every((c) => c.places.isEmpty)) {
          categories = _defaultExploreCategories;
        }

        if (query.isNotEmpty) {
          services = services
              .where((s) => s.title.toLowerCase().contains(query))
              .toList();
          categories = categories
              .where((c) =>
                  c.title.toLowerCase().contains(query) ||
                  c.places.any((p) => p.name.toLowerCase().contains(query)))
              .toList();
        }

        return ColoredBox(
          color: ExploreListTheme.background,
          child: RefreshIndicator(
            onRefresh: () async => ref.invalidate(cityContentProvider),
            color: AppColors.primaryDark,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // === FOTOĞRAFTAKİ TARZDA HERO + ARAMA ===
                SliverToBoxAdapter(
                  child: _ExploreHeroHeaderModern(
                    query: query,
                    onQueryChanged: (value) => ref
                        .read(exploreSearchQueryProvider.notifier)
                        .state = value,
                  ),
                ),

                // === ŞEHİR HİZMETLERİ GRID ===
                if (services.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _ExploreSectionHeader(
                      title: 'Şehir Hizmetleri',
                      actionLabel: 'Tümünü Gör',
                      onAction: () {},
                    ).animate(delay: 100.ms).fadeIn(
                        duration: _exploreEntryDuration,
                        curve: _exploreEntryCurve),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: PremiumCityTheme.pagePadding),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        mainAxisExtent: 104,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final svc = services[index];
                          return _CityServiceCard(
                            service: svc,
                            onTap: () => _handleServiceTap(context, svc),
                          )
                              .animate(delay: (120 + index * 30).ms)
                              .fadeIn(
                                duration: _exploreEntryDuration,
                                curve: _exploreEntryCurve,
                              )
                              .scale(
                                begin: const Offset(0.94, 0.94),
                                end: const Offset(1, 1),
                                duration: _exploreEntryDuration,
                                curve: _exploreEntryCurve,
                              );
                        },
                        childCount: services.length,
                      ),
                    ),
                  ),
                ],

                // === GEZİ KATEGORİLERİ ===
                SliverToBoxAdapter(
                  child: _ExploreSectionHeader(
                    title: 'Düziçi’ni Keşfet',
                    actionLabel: 'Tümünü Gör',
                    onAction: () {},
                  ).animate(delay: 350.ms).fadeIn(
                      duration: _exploreEntryDuration,
                      curve: _exploreEntryCurve),
                ),
                SliverToBoxAdapter(
                  child: _FeaturedSlider(
                          places: categories
                              .where((c) => c.id != 'guide')
                              .expand((c) => c.places)
                              .take(5)
                              .toList())
                      .animate(delay: 400.ms)
                      .fadeIn(
                          duration: _exploreEntryDuration,
                          curve: _exploreEntryCurve)
                      .scale(
                        begin: const Offset(0.985, 0.985),
                        duration: _exploreEntryDuration,
                        curve: _exploreEntryCurve,
                      ),
                ),

                // === KATEGORİ KARTLARI ===
                SliverToBoxAdapter(
                  child: const _ExploreSectionHeader(title: 'Kategoriler')
                      .animate(delay: 450.ms)
                      .fadeIn(
                          duration: _exploreEntryDuration,
                          curve: _exploreEntryCurve),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: PremiumCityTheme.pagePadding),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.95,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = categories[index];

                        String preSelected = 'HEPSİ';
                        if (item.id == 'places' || item.id == 'nature') {
                          preSelected = 'DOĞAL GÜZELLİK';
                        } else if (item.id == 'heritage' ||
                            item.id == 'castles') {
                          preSelected = 'KALE';
                        } else if (item.id == 'historical') {
                          preSelected = 'TARİHİ YER';
                        } else if (item.id == 'food') {
                          preSelected = 'LEZZET DURAĞI';
                        } else if (item.id == 'camping') {
                          preSelected = 'KAMP ALANI';
                        } else if (item.id == 'hiking') {
                          preSelected = 'YÜRÜYÜŞ ROTASI';
                        } else if (item.id == 'parks') {
                          preSelected = 'PARK';
                        } else if (item.id == 'highlands') {
                          preSelected = 'YAYLA';
                        } else if (item.id == 'thermal') {
                          preSelected = 'DOĞAL GÜZELLİK';
                        } else if (item.id == 'museums') {
                          preSelected = 'MÜZE';
                        }

                        return _PremiumExploreCard(
                          title: item.title,
                          subtitle: item.subtitle,
                          imageUrl: _categoryHeroImageUrl(item),
                          onTap: () => _openCategory(
                            context,
                            item.title,
                            categories,
                            preSelectedCategory: preSelected,
                            initialScope:
                                item.id == 'osmaniye' ? 'OSMANIYE' : 'DUZICI',
                          ),
                        )
                            .animate(delay: (500 + index * 80).ms)
                            .fadeIn(
                              duration: _exploreEntryDuration,
                              curve: _exploreEntryCurve,
                            )
                            .moveY(
                              begin: 16,
                              end: 0,
                              duration: _exploreEntryDuration,
                              curve: _exploreEntryCurve,
                            );
                      },
                      childCount: categories.length,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 48)),
              ],
            ),
          ),
        );
      },
      loading: () => const _ExploreStatusBody(
        child: CircularProgressIndicator(),
      ),
      error: (e, _) => _ExploreStatusBody(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text('İçerik yüklenemedi: $e', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => ref.invalidate(cityContentProvider),
              child: const Text('Yeniden dene'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleServiceTap(BuildContext context, CityServiceItem svc) {
    if (svc.id == 'veterinary') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const VeterinaryScreen()),
      );
      return;
    }
    if (svc.id == 'obituary') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ObituaryScreen()),
      );
      return;
    }
    // directory target olanlar için DirectoryScreen aç
    if (svc.target == 'screen:directory' && svc.directoryData != null) {
      if (svc.id == 'auto_gallery') {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AutoGalleryScreen(
              title: svc.title,
              subtitle: svc.subtitle,
              color: _parseColor(svc.color),
              entries: svc.directoryData!,
            ),
          ),
        );
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DirectoryScreen(
            title: svc.title,
            subtitle: svc.subtitle,
            icon: svc.icon,
            color: _parseColor(svc.color),
            entries: svc.directoryData!,
          ),
        ),
      );
      return;
    }
    // Diğer target'lar için TargetRouter kullan
    TargetRouter.handle(context, svc.target);
  }

  Color _parseColor(String hex) {
    if (hex.isEmpty) return AppColors.primary;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }

  void _openCategory(
    BuildContext context,
    String title,
    List<ExploreCategoryItem> allCategories, {
    required String preSelectedCategory,
    required String initialScope,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExploreCategoryScreen(
          title: title,
          places: const [],
          allCategories: allCategories,
          preSelectedCategory: preSelectedCategory,
          initialScope: initialScope,
        ),
      ),
    );
  }

  String _categoryHeroImageUrl(ExploreCategoryItem item) {
    for (final p in item.places) {
      final u = p.imageUrl?.trim();
      if (u != null && u.isNotEmpty) return u;
    }
    return _categoryFallbackImageUrl(item.id);
  }

  String _categoryFallbackImageUrl(String id) {
    switch (id) {
      case 'places':
      case 'gezilecek':
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f3/Berke_Baraj%C4%B1_-_Berke_Dam_01.JPG/960px-Berke_Baraj%C4%B1_-_Berke_Dam_01.JPG';
      case 'heritage':
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fc/Hemite_Kalesi_-_Amouda_Castle_03.jpg/960px-Hemite_Kalesi_-_Amouda_Castle_03.jpg';
      case 'food':
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b1/Osmaniye_Market_in_2010_1919.jpg/960px-Osmaniye_Market_in_2010_1919.jpg';
      default:
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f3/Berke_Baraj%C4%B1_-_Berke_Dam_01.JPG/960px-Berke_Baraj%C4%B1_-_Berke_Dam_01.JPG';
    }
  }
}

class _ExploreHeroHeaderModern extends ConsumerWidget {
  const _ExploreHeroHeaderModern({
    required this.query,
    required this.onQueryChanged,
  });

  final String query;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(brandingProvider);
    final exploreHeaderBg = branding?.exploreHeaderBg;

    return SizedBox(
      height: 326,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 270,
            margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              boxShadow: PremiumCityTheme.softShadow(
                color: PremiumCityTheme.navy,
                alpha: 0.22,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildBackgroundImage(exploreHeaderBg),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        PremiumCityTheme.navy.withValues(alpha: 0.78),
                        Colors.black.withValues(alpha: 0.08),
                        PremiumCityTheme.navy.withValues(alpha: 0.72),
                      ],
                      stops: const [0, 0.48, 1],
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.72, -0.72),
                      radius: 1.1,
                      colors: [
                        PremiumCityTheme.gold.withValues(alpha: 0.22),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  top: 18,
                  child: Row(
                    children: [
                      const _HeroPill(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _LiveDot(),
                            SizedBox(width: 8),
                            Text(
                              'CANLI KEŞİF',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 10.5,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      _HeroPill(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.cloud_rounded,
                                color: Color(0xFFD7ECFF), size: 18),
                            SizedBox(width: 6),
                            Text(
                              '19°  Parçalı Bulutlu',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 40,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: PremiumCityTheme.goldGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  PremiumCityTheme.gold.withValues(alpha: 0.32),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.explore_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Hepsi\nDüziçi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                          height: 0.92,
                          shadows: [
                            Shadow(
                              color: Color(0x99000000),
                              blurRadius: 16,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 4,
                            decoration: BoxDecoration(
                              gradient: PremiumCityTheme.goldGradient,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Akdeniz’in incisi Düziçi',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontWeight: FontWeight.w800,
                              fontSize: 13.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 2,
            child: Container(
              height: 62,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE8EDF4)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 28,
                    spreadRadius: -16,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: PremiumCityTheme.gold.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.search_rounded,
                        color: PremiumCityTheme.gold, size: 22),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(text: query)
                        ..selection =
                            TextSelection.collapsed(offset: query.length),
                      onChanged: onQueryChanged,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Haber, etkinlik veya hizmet ara...',
                        hintStyle: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                      style: const TextStyle(
                        color: PremiumCityTheme.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _HeroRoundButton(
                      icon: Icons.mic_rounded, color: PremiumCityTheme.gold),
                  const SizedBox(width: 6),
                  _HeroRoundButton(
                      icon: Icons.auto_awesome_rounded,
                      color: PremiumCityTheme.navy),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundImage(String? heroCardBg) {
    final bg = heroCardBg;
    if (bg == null || bg.trim().isEmpty) {
      return Image.asset(
        'assets/images/duzici_castle_header.png',
        fit: BoxFit.cover,
        alignment: const Alignment(0.04, -0.14),
      );
    }

    if (bg.startsWith('http://') || bg.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: bg,
        fit: BoxFit.cover,
        alignment: const Alignment(0.04, -0.14),
        placeholder: (context, url) => Container(color: PremiumCityTheme.navy),
        errorWidget: (context, url, error) => Image.asset(
          'assets/images/duzici_castle_header.png',
          fit: BoxFit.cover,
          alignment: const Alignment(0.04, -0.14),
        ),
      );
    }

    final assetPath = bg.startsWith('asset:') ? bg.substring(6) : bg;
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      alignment: const Alignment(0.04, -0.14),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: child,
    );
  }
}

// ignore: unused_element
class _ExploreHeroHeader extends StatelessWidget {
  const _ExploreHeroHeader({
    required this.query,
    required this.onQueryChanged,
  });

  final String query;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 318,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(26),
              bottomRight: Radius.circular(26),
            ),
            child: SizedBox(
              height: 262,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset('assets/images/karasu_selalesi.jpg',
                      fit: BoxFit.cover),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x33000000),
                          Color(0x440F2744),
                          Color(0xE60A1623),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    top: 56,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18)),
                      ),
                      child: const Row(
                        children: [
                          _LiveDot(),
                          SizedBox(width: 9),
                          Text(
                            'CANLI AKIŞ',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 10.5,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 18,
                    top: 52,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.cloud_rounded,
                              color: Color(0xFFD7ECFF), size: 20),
                          SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '19°',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                  height: 1,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Parçalı Bulutlu',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 20,
                    bottom: 42,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on_rounded,
                            color: PremiumCityTheme.gold, size: 26),
                        SizedBox(height: 10),
                        Text(
                          'Hepsi\nDüziçi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.2,
                            height: 0.92,
                          ),
                        ),
                        SizedBox(height: 8),
                        SizedBox(
                          width: 36,
                          child: Divider(
                            color: PremiumCityTheme.gold,
                            thickness: 3,
                            height: 3,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Akdeniz’in incisi Düziçi',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 0,
            child: Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE8EDF4)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 28,
                    spreadRadius: -16,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded,
                      color: PremiumCityTheme.gold, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(text: query)
                        ..selection =
                            TextSelection.collapsed(offset: query.length),
                      onChanged: onQueryChanged,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Haber, etkinlik veya hizmet ara...',
                        hintStyle: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                      style: const TextStyle(
                        color: PremiumCityTheme.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _HeroRoundButton(
                      icon: Icons.mic_rounded, color: PremiumCityTheme.gold),
                  const SizedBox(width: 6),
                  _HeroRoundButton(
                      icon: Icons.auto_awesome_rounded,
                      color: PremiumCityTheme.navy),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: const Color(0xFF16A34A).withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFF22C55E),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _HeroRoundButton extends StatelessWidget {
  const _HeroRoundButton({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}

class _ExploreSectionHeader extends StatelessWidget {
  const _ExploreSectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          PremiumCityTheme.pagePadding, 0, PremiumCityTheme.pagePadding, 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
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
                color: PremiumCityTheme.navy,
                fontWeight: FontWeight.w900,
                fontSize: PremiumCityTheme.sectionTitleSize,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: PremiumCityTheme.ink.withValues(alpha: 0.70),
                backgroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                  side: const BorderSide(color: Color(0xFFE8EDF4)),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel!,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 11),
                  ),
                  const SizedBox(width: 3),
                  const Icon(Icons.chevron_right_rounded, size: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ╔══════════════════════════════════════════════════════════════╗
// ║                  ŞEHİR HİZMETLERİ KARTI                    ║
// ╚══════════════════════════════════════════════════════════════╝

class _CityServiceCard extends StatelessWidget {
  const _CityServiceCard({required this.service, required this.onTap});
  final CityServiceItem service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(service.color);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEBEEF3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  IconMapper.fromName(service.icon),
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                service.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: PremiumCityTheme.ink,
                  letterSpacing: -0.15,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                service.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: PremiumCityTheme.muted.withValues(alpha: 0.92),
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _parseColor(String hex) {
    if (hex.trim().isEmpty) return PremiumCityTheme.gold;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return PremiumCityTheme.gold;
    }
  }
}

// Explore Header removed in favor of HomeHeader

// ╔══════════════════════════════════════════════════════════════╗
// ║                   ÖNE ÇIKAN SLIDER                         ║
// ╚══════════════════════════════════════════════════════════════╝

class _FeaturedSlider extends StatelessWidget {
  const _FeaturedSlider({required this.places});

  final List<ExplorePlace> places;

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 136,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
            horizontal: PremiumCityTheme.pagePadding),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: places.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final place = places[index];
          return SizedBox(
            width: 106,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PlaceNetworkImage(
                    place: place,
                    fit: BoxFit.cover,
                    maxHeight: 600,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color(0x33000000),
                          Color(0xE6000000),
                        ],
                      ),
                    ),
                  ),
                  const Positioned(
                    right: 8,
                    bottom: 10,
                    child: Icon(
                      Icons.location_on_rounded,
                      color: PremiumCityTheme.gold,
                      size: 15,
                    ),
                  ),
                  Positioned(
                    left: 8,
                    right: 20,
                    bottom: 8,
                    child: Text(
                      place.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ╔══════════════════════════════════════════════════════════════╗
// ║                   KATEGORİ KART                             ║
// ╚══════════════════════════════════════════════════════════════╝

class _PremiumExploreCard extends StatelessWidget {
  const _PremiumExploreCard({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ExploreListTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(
                child: imageUrl.startsWith('assets/')
                    ? Image.asset(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Theme.of(context)
                              .disabledColor
                              .withValues(alpha: 0.1),
                          child:
                              const Icon(Icons.image_not_supported, size: 40),
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Theme.of(context)
                              .disabledColor
                              .withValues(alpha: 0.05),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 1.5),
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: Theme.of(context)
                              .disabledColor
                              .withValues(alpha: 0.1),
                          child:
                              const Icon(Icons.image_not_supported, size: 40),
                        ),
                      ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.04),
                      Colors.black.withValues(alpha: 0.45),
                      Colors.black.withValues(alpha: 0.78),
                    ],
                    stops: const [0.05, 0.55, 1.0],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.15,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.42),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        height: 1.15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.13),
                        width: 1.0,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withValues(alpha: 0.12),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.1),
                        ],
                        stops: const [0, 0.5, 1],
                      ),
                    ),
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

// ╔══════════════════════════════════════════════════════════════╗
// ║                   SECTION HEADER                            ║
// ╚══════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════════════════════════════╗
// ║                   PROVIDERS                                 ║
// ╚══════════════════════════════════════════════════════════════╝

// Shared provider exploreSearchQueryProvider is now used

// ╔══════════════════════════════════════════════════════════════╗
// ║                   DEFAULT DATA                              ║
// ╚══════════════════════════════════════════════════════════════╝

class _ExploreStatusBody extends StatelessWidget {
  const _ExploreStatusBody({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ExploreListTheme.background,
      child: SizedBox.expand(
        child: Center(child: child),
      ),
    );
  }
}

List<ExploreCategoryItem> get _defaultExploreCategories {
  return [
    ExploreCategoryItem(
      id: 'places',
      icon: 'park',
      title: 'Doğa ve termal',
      subtitle: 'Şelale, kaplıca, baraj ve yayla',
      badge: 'Doğa',
      places: [
        const ExplorePlace(
          name: 'Karasu Şelalesi (Sabun Çayı)',
          shortDescription: 'Düldül eteklerinde doğal çağlayan.',
          detail: 'Sabun Çayı üzerinde yer alan doğal şelale.',
          address: 'Sabun Çayı, Düziçi',
          tag: 'ŞELALE',
          imageUrl: 'assets/images/karasu_selalesi.jpg',
        ),
        const ExplorePlace(
          name: 'Haruniye Kaplıcaları',
          shortDescription: 'Kuşçu yöresi, Düldül etekleri.',
          detail: 'Mineral termal suyu ile turizm merkezi.',
          address: 'Kuşçu köyü yöresi, Düziçi',
          tag: 'TERMAL',
          imageUrl:
              'https://upload.wikimedia.org/wikipedia/commons/thumb/b/be/D%C3%BCld%C3%BCl_Da%C4%9F%C4%B1_-_Mount_D%C3%BCld%C3%BCl_04.JPG/960px-D%C3%BCld%C3%BCl_Da%C4%9F%C4%B1_-_Mount_D%C3%BCld%C3%BCl_04.JPG',
        ),
        const ExplorePlace(
          name: 'Berke Barajı',
          shortDescription: 'Ceyhan üzerinde görsel güçlü baraj gölü.',
          detail: 'Fotoğraf için sık anılan büyük baraj.',
          address: 'Ceyhan Nehri, Düziçi sınırı',
          tag: 'BARAJ',
          imageUrl:
              'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f3/Berke_Baraj%C4%B1_-_Berke_Dam_01.JPG/960px-Berke_Baraj%C4%B1_-_Berke_Dam_01.JPG',
        ),
      ],
    ),
    ExploreCategoryItem(
      id: 'heritage',
      icon: 'menu_book',
      title: 'Tarih ve mimari',
      subtitle: 'Kale ve köprü izleri',
      badge: 'Miras',
      places: [
        const ExplorePlace(
          name: 'Harun Reşit Kalesi',
          shortDescription: 'Kurtbeyoğlu yakınındaki kale kalıntısı.',
          detail: 'Kayalık üzerinde tarihî tahkimat.',
          address: 'Kurtbeyoğlu Mahallesi çevresi, Düziçi',
          tag: 'KALE',
          imageUrl:
              'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fc/Hemite_Kalesi_-_Amouda_Castle_03.jpg/960px-Hemite_Kalesi_-_Amouda_Castle_03.jpg',
        ),
      ],
    ),
  ];
}
