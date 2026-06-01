import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/icon_mapper.dart';
import '../../core/utils/target_router.dart';
import '../../data/models/city_content.dart';
import 'directory_screen.dart';
import 'explore_category_screen.dart';
import 'auto_gallery_screen.dart';
import '../veterinary/veterinary_screen.dart';
import '../home/widgets/home_header.dart';
import '../../core/widgets/favorite_button.dart';
import '../../core/widgets/place_network_image.dart';
import '../../data/services/favorites_service.dart';

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
          services = services.where((s) => s.title.toLowerCase().contains(query)).toList();
          categories = categories.where((c) => 
            c.title.toLowerCase().contains(query) || 
            c.places.any((p) => p.name.toLowerCase().contains(query))
          ).toList();
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(cityContentProvider),
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // === HEADER ===
              const SliverToBoxAdapter(
                child: HomeHeader(imagesOnly: true),
              ),

              // === ŞEHİR HİZMETLERİ GRID ===
              if (services.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: const _SectionHeader(title: 'Şehir Hizmetleri')
                      .animate(delay: 100.ms)
                      .fadeIn(),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.78,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final svc = services[index];
                        return _CityServiceCard(
                          service: svc,
                          onTap: () => _handleServiceTap(context, svc),
                        ).animate(delay: (120 + index * 30).ms).fadeIn().scale(
                              begin: const Offset(0.9, 0.9),
                              end: const Offset(1, 1),
                              curve: Curves.easeOutBack,
                            );
                      },
                      childCount: services.length,
                    ),
                  ),
                ),
              ],

              // === GEZİ KATEGORİLERİ ===
              SliverToBoxAdapter(
                child: const _SectionHeader(title: 'Gezi & Keşfet', showAll: true)
                    .animate(delay: 350.ms)
                    .fadeIn(),
              ),
              SliverToBoxAdapter(
                child: _FeaturedSlider(
                    places: categories.expand((c) => c.places).take(5).toList())
                    .animate(delay: 400.ms)
                    .fadeIn()
                    .scale(begin: const Offset(0.98, 0.98)),
              ),

              // === KATEGORİ KARTLARI ===
              SliverToBoxAdapter(
                child: const _SectionHeader(title: 'Kategoriler')
                    .animate(delay: 450.ms)
                    .fadeIn(),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.82,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = categories[index];
                      
                      String preSelected = 'HEPSİ';
                      if (item.id == 'places' || item.id == 'nature') {
                        preSelected = 'DOĞAL GÜZELLİK';
                      } else if (item.id == 'heritage' || item.id == 'castles') {
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
                          initialScope: item.id == 'osmaniye' ? 'OSMANIYE' : 'DUZICI',
                        ),
                      ).animate(delay: (500 + index * 80).ms).fadeIn().moveY(begin: 16, end: 0);
                    },
                    childCount: categories.length,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 60)),
            ],
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
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.18),
                  color.withValues(alpha: 0.07),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.16),
                  blurRadius: 12,
                  spreadRadius: -6,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    IconMapper.fromName(service.icon),
                    color: color,
                    size: 26,
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: FavoriteButton(
                    id: service.id,
                    category: FavoriteCategory.service,
                    size: 14,
                    padding: const EdgeInsets.all(4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            service.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: -0.2,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    if (hex.isEmpty) return AppColors.primary;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }
}

// Explore Header removed in favor of HomeHeader

// ╔══════════════════════════════════════════════════════════════╗
// ║                   ÖNE ÇIKAN SLIDER                         ║
// ╚══════════════════════════════════════════════════════════════╝

class _FeaturedSlider extends StatefulWidget {
  const _FeaturedSlider({required this.places});
  final List<ExplorePlace> places;

  @override
  State<_FeaturedSlider> createState() => _FeaturedSliderState();
}

class _FeaturedSliderState extends State<_FeaturedSlider> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: widget.places.length,
            itemBuilder: (context, index) {
              final place = widget.places[index];
              return AnimatedScale(
                scale: _currentPage == index ? 1.0 : 0.95,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: PlaceNetworkImage(
                            place: place,
                            fit: BoxFit.cover,
                            maxHeight: 600,
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: FavoriteButton(
                            id: place.name, 
                            category: FavoriteCategory.place,
                            size: 22,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.75),
                              ],
                              stops: const [0.4, 1.0],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  place.tag.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                place.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                place.shortDescription,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
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
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.places.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 5,
              width: _currentPage == index ? 18 : 5,
              decoration: BoxDecoration(
                color: _currentPage == index ? AppColors.primary : Theme.of(context).disabledColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
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
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned.fill(
                child: imageUrl.startsWith('assets/')
                    ? Image.asset(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                          child: const Icon(Icons.image_not_supported, size: 40),
                        ),
                      )
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Theme.of(context).disabledColor.withValues(alpha: 0.05),
                            child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        },
                        errorBuilder: (_, __, ___) => Container(
                          color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                          child: const Icon(Icons.image_not_supported, size: 40),
                        ),
                      ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.7),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
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
}

// ╔══════════════════════════════════════════════════════════════╗
// ║                   SECTION HEADER                            ║
// ╚══════════════════════════════════════════════════════════════╝

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.showAll = false});

  final String title;
  final bool showAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 5,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: -0.3,
                    ),
              ),
            ],
          ),
          if (showAll)
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: AppColors.primaryDark,
                backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Row(
                children: [
                  Text('Tümü',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios_rounded, size: 10),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

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
      color: Theme.of(context).scaffoldBackgroundColor,
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
