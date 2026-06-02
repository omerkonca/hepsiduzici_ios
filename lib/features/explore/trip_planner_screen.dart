import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/utils/launcher_utils.dart';
import '../../data/models/city_content.dart';
import '../../data/providers/trip_planner_provider.dart';
import '../../data/services/trip_route_engine.dart';
import 'explore_category_screen.dart';
import 'explore_detail_screen.dart';
import 'widgets/trip_planner_category_hub.dart';
import 'widgets/trip_planner_theme.dart';
import 'widgets/trip_planner_widgets.dart';

class TripPlannerScreen extends ConsumerStatefulWidget {
  const TripPlannerScreen({super.key});

  @override
  ConsumerState<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends ConsumerState<TripPlannerScreen> {
  final _planner = TripPlannerProvider.instance;
  int _selectedTabIndex = 0; // 0: Kayıtlı Duraklarım, 1: Editörün Rotaları
  bool _showCategoryHub = true;
  bool _showIntro = false;
  bool _showTimeline = false;
  EditorRoute? _selectedEditorRoute;

  @override
  void initState() {
    super.initState();
    _planner.addListener(_rebuild);
  }

  @override
  void dispose() {
    _planner.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _startPresetRoute(EditorRoute route, List<ExploreCategoryItem> allCategories) {
    final resolved = _resolvePlacesForRoute(route, allCategories);
    _planner.loadPresetRoute(route.name, resolved);
    setState(() {
      _selectedEditorRoute = route;
      _showIntro = true;
      _showTimeline = false;
    });
  }

  void _startCustomRoute() {
    if (_planner.places.isNotEmpty) {
      setState(() {
        _selectedEditorRoute = null;
        _showIntro = true;
        _showTimeline = false;
      });
    }
  }

  void _openExploreWithCategories(Set<String> categoryIds) {
    final content = ref.read(cityContentProvider).value;
    if (content == null || !mounted) return;

    const exploreIds = [
      'nature', 'castles', 'historical', 'hiking', 'camping', 'parks',
      'highlands', 'thermal', 'places', 'heritage',
    ];
    var places = content.exploreCategories
        .where((c) => exploreIds.contains(c.id))
        .expand((c) => c.places)
        .toList();

    if (!categoryIds.contains('HEPSİ')) {
      places = places.where((p) {
        final cats = _plannerCategoriesForPlace(p);
        return categoryIds.any(cats.contains);
      }).toList();
    }

    final preCat = categoryIds.contains('HEPSİ')
        ? 'HEPSİ'
        : categoryIds.first;

    setState(() => _showCategoryHub = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExploreCategoryScreen(
          title: 'Gezi Rehberi',
          places: places,
          allCategories: content.exploreCategories,
          preSelectedCategory: preCat == 'EDITOR' ? 'DOĞAL GÜZELLİK' : preCat,
          initialScope: 'DUZICI',
        ),
      ),
    );
  }

  List<String> _plannerCategoriesForPlace(ExplorePlace place) {
    final tag = place.tag.toUpperCase();
    final name = place.name.toLowerCase();
    final list = <String>[];
    if (tag.contains('KALE')) list.add('KALE');
    if (tag.contains('TARİH') || tag.contains('KÖPRÜ') || tag.contains('CAMİ') || tag.contains('ANTİK')) {
      list.add('TARİHİ YER');
    }
    if (tag.contains('TATLI') || tag.contains('ESNAF') || name.contains('lezzet')) list.add('LEZZET DURAĞI');
    if (tag.contains('KAMP') || tag.contains('PİKNİK')) list.add('KAMP ALANI');
    if (tag.contains('MÜZE')) list.add('MÜZE');
    if (tag.contains('YÜRÜYÜŞ') || tag.contains('TREKKING')) list.add('YÜRÜYÜŞ ROTASI');
    if (tag.contains('ŞELALE') || tag.contains('DOĞA') || tag.contains('VADİ')) list.add('DOĞAL GÜZELLİK');
    if (tag.contains('YAYLA')) list.add('YAYLA');
    if (tag.contains('PARK')) list.add('PARK');
    if (list.isEmpty) list.add('DOĞAL GÜZELLİK');
    return list;
  }

  List<ExplorePlace> _resolvePlacesForRoute(EditorRoute route, List<ExploreCategoryItem> categories) {
    final allPlaces = categories.expand((c) => c.places).toList();
    return TripRouteEngine.resolveStops(allPlaces, route.placeNames);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = true;
    final contentAsync = ref.watch(cityContentProvider);

    // Eğer aktif seyahat başlatılmışsa doğrudan aktif navigasyon ekranına geç
    if (_planner.isActiveTrip) {
      return _buildActiveNavigationScreen(theme, isDark);
    }

    if (_showCategoryHub) {
      return TripPlannerCategoryHub(
        onBack: () => Navigator.maybePop(context),
        onEditorRoutes: () => setState(() {
          _showCategoryHub = false;
          _selectedTabIndex = 1;
        }),
        onSavedRoutes: () => setState(() {
          _showCategoryHub = false;
          _selectedTabIndex = 0;
        }),
        onContinue: _openExploreWithCategories,
      );
    }

    // Giriş (Intro) Ekranı ("Hazırsanız Başlayalım!")
    if (_showIntro) {
      return _buildIntroStartScreen(theme, isDark);
    }

    // Zaman Tüneli Detay Ekranı
    if (_showTimeline) {
      return _buildTimelineDetailScreen(theme, isDark);
    }

    return Theme(
      data: TripPlannerTheme.theme(),
      child: Scaffold(
      backgroundColor: TripPlannerTheme.bg,
      appBar: AppBar(
        title: Text(_selectedTabIndex == 1 ? 'Editörün Seçtikleri' : 'Gezi Planlayıcı'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => setState(() => _showCategoryHub = true),
        ),
        actions: [
          if (_planner.places.isNotEmpty && _selectedTabIndex == 0)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFFF6B6B)),
              tooltip: 'Tümünü temizle',
              onPressed: _showClearDialog,
            ),
        ],
      ),
      body: contentAsync.when(
        data: (content) {
          return Column(
            children: [
              _buildSegmentControl(isDark),
              Expanded(
                child: _selectedTabIndex == 0
                    ? _buildCustomRouteTab(theme, isDark)
                    : _buildEditorRoutesTab(theme, isDark, content.exploreCategories),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Veriler yüklenemedi: $err', style: const TextStyle(color: TripPlannerTheme.textSecondary)),
        ),
      ),
    ),
    );
  }

  // === A. SEGMENT SELECTOR ===
  Widget _buildSegmentControl(bool isDark) {
    final savedCount = _planner.count;
    final editorCount = TripPlannerProvider.editorRoutes.length;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: TripPlannerTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          _SegmentTab(
            label: 'Rotalarım',
            icon: Icons.bookmark_rounded,
            count: savedCount > 0 ? savedCount : null,
            isSelected: _selectedTabIndex == 0,
            onTap: () => setState(() => _selectedTabIndex = 0),
          ),
          _SegmentTab(
            label: 'Editör',
            icon: Icons.auto_awesome_rounded,
            count: editorCount,
            isSelected: _selectedTabIndex == 1,
            onTap: () => setState(() => _selectedTabIndex = 1),
          ),
        ],
      ),
    );
  }

  // === B. KAYITLI ROTALARIM TAB ===
  Widget _buildCustomRouteTab(ThemeData theme, bool isDark) {
    final places = _planner.places;
    if (places.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated empty map illustration
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 52,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    Positioned(
                      top: 24,
                      right: 24,
                      child: Icon(
                        Icons.add_location_alt_rounded,
                        size: 28,
                        color: TripPlannerTheme.gold.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ).animate(delay: 100.ms)
                  .scale(begin: const Offset(0.7, 0.7), curve: Curves.elasticOut, duration: 800.ms)
                  .fadeIn(duration: 400.ms),
              const SizedBox(height: 24),
              const Text(
                'Rotanız henüz boş',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: TripPlannerTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1, end: 0),
              const SizedBox(height: 10),
              const Text(
                'Gezi Rehberi\'nden beğendiğiniz yerleri\nrotanıza ekleyerek başlayın.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: TripPlannerTheme.textSecondary,
                  height: 1.55,
                  fontSize: 13.5,
                ),
              ).animate(delay: 300.ms).fadeIn(),
              const SizedBox(height: 32),
              // Two action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() {
                        _showCategoryHub = false;
                        _selectedTabIndex = 1;
                      }),
                      icon: const Icon(Icons.auto_awesome_rounded, size: 16, color: TripPlannerTheme.gold),
                      label: const Text('Editör\nRotaları', textAlign: TextAlign.center),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TripPlannerTheme.textPrimary,
                        backgroundColor: TripPlannerTheme.surface,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TripPlannerTheme.primaryCta(
                      label: 'Rehberi Aç',
                      icon: Icons.explore_rounded,
                      onPressed: () => setState(() => _showCategoryHub = true),
                    ),
                  ),
                ],
              ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.15, end: 0),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Rota Bilgi Çubuğu
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: TripPlannerTheme.gold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: TripPlannerTheme.gold.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              const Icon(Icons.swap_vert_rounded, color: TripPlannerTheme.gold, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${places.length} durak — sırayı sürükleyerek değiştirin.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: TripPlannerTheme.gold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
            itemCount: places.length,
            onReorder: _planner.reorder,
            proxyDecorator: (child, index, animation) => Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(18),
              child: child,
            ),
            itemBuilder: (context, i) {
              final place = places[i];
              return _buildDraggablePlaceCard(theme, isDark, i, places.length, place);
            },
          ),
        ),
        _buildBottomStartBar('Özel Gezi Planım', _startCustomRoute),
      ],
    );
  }

  Widget _buildDraggablePlaceCard(
      ThemeData theme, bool isDark, int index, int total, ExplorePlace place) {
    return Container(
      key: ValueKey(place.name),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: TripPlannerTheme.surfaceCard(radius: 18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            TripPlannerTheme.goldStepBadge(index + 1, size: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: -0.2,
                      color: TripPlannerTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    place.address,
                    style: const TextStyle(
                      fontSize: 11,
                      color: TripPlannerTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Drag Handle
            const Icon(Icons.drag_indicator_rounded, color: Colors.grey, size: 22),
            const SizedBox(width: 4),
            // Delete IconButton
            IconButton(
              onPressed: () => _planner.remove(place),
              icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.redAccent, size: 22),
              tooltip: 'Çıkar',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
        ),
      ),
    );
  }

  // === C. EDITÖRÜN ROTALARI TAB (Görsel 2 ile Uyumlu Liste) ===
  Widget _buildEditorRoutesTab(
      ThemeData theme, bool isDark, List<ExploreCategoryItem> allCategories) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      itemCount: TripPlannerProvider.editorRoutes.length,
      itemBuilder: (context, index) {
        final route = TripPlannerProvider.editorRoutes[index];
        return TripEditorRouteCard(
          route: route,
          index: index,
          onTap: () => _startPresetRoute(route, allCategories),
        ).animate(delay: (index * 100).ms).fadeIn().moveY(begin: 15, end: 0);
      },
    );
  }

  // === D. ALT BUTON BAŞLAT BAR ===
  Widget _buildBottomStartBar(String routeName, VoidCallback onStart) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: TripPlannerTheme.bgElevated,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: SafeArea(
        top: false,
        child: TripPlannerTheme.primaryCta(
          label: 'Rota Deneyimini Başlat',
          onPressed: onStart,
        ),
      ),
    );
  }

  // === 3. MACERA GİRİŞ EKRANI ("Hazırsanız Başlayalım!") ===
  Widget _buildIntroStartScreen(ThemeData theme, bool isDark) {
    final places = _planner.places;
    final summary = _planner.routeSummary;
    final totalDuration = TripRouteEngine.formatDuration(summary.totalMinutes);
    final totalDistance = TripRouteEngine.formatDistance(summary.distanceKm);

    return Theme(
      data: TripPlannerTheme.theme(),
      child: Scaffold(
      backgroundColor: TripPlannerTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => setState(() => _showIntro = false),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // Camper Van Illustration
            const _CamperVanIllustration(),
            const SizedBox(height: 32),

            // Title
            const Text(
              'Rotanız Hazır!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.6,
              ),
            ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 6),
            const Text(
              'ROTA ÖZETİ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: TripPlannerTheme.ctaBlue,
                letterSpacing: 2.0,
              ),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 28),

            // Stat cards grid
            Row(
              children: [
                _IntroStatCard(
                  icon: Icons.place_rounded,
                  label: 'Durak',
                  value: '${places.length}',
                  color: TripPlannerTheme.gold,
                ),
                const SizedBox(width: 12),
                _IntroStatCard(
                  icon: Icons.schedule_rounded,
                  label: 'Süre',
                  value: totalDuration,
                  color: TripPlannerTheme.ctaBlue,
                ),
                const SizedBox(width: 12),
                _IntroStatCard(
                  icon: Icons.route_rounded,
                  label: 'Mesafe',
                  value: totalDistance,
                  color: const Color(0xFF4CAF50),
                ),
              ],
            ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.12, end: 0),

            const SizedBox(height: 32),
            TripPlannerTheme.primaryCta(
              label: 'Rotayı İncele →',
              icon: Icons.map_rounded,
              onPressed: () {
                setState(() {
                  _showIntro = false;
                  _showTimeline = true;
                });
              },
            ).animate(delay: 450.ms).fadeIn().slideY(begin: 0.1, end: 0),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
    );
  }

  // === 4. ZAMAN TÜNELİ ===
  Widget _buildTimelineDetailScreen(ThemeData theme, bool isDark) {
    final places = _planner.places;
    final legs = _planner.legs;
    final summary = _planner.routeSummary;
    final title = _selectedEditorRoute?.name ?? 'Kişiselleştirilmiş Gezim';
    final regionHint = _selectedEditorRoute?.regionLabel;
    final totalDuration = TripRouteEngine.formatDuration(summary.totalMinutes);
    final totalDistance = TripRouteEngine.formatDistance(summary.distanceKm);
    final totalCost = TripRouteEngine.formatCost(summary.costTry);

    return Theme(
      data: TripPlannerTheme.theme(),
      child: Scaffold(
        backgroundColor: TripPlannerTheme.bg,
        appBar: AppBar(
          title: Text(title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () {
              setState(() {
                _showTimeline = false;
                _showIntro = true;
              });
            },
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timeline header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: TripPlannerTheme.textPrimary,
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (regionHint != null && regionHint.isNotEmpty)
                              Text(
                                regionHint,
                                style: const TextStyle(
                                  color: TripPlannerTheme.gold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Stop count badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: TripPlannerTheme.gold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: TripPlannerTheme.gold.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.place_rounded, size: 13, color: TripPlannerTheme.gold),
                            const SizedBox(width: 4),
                            Text(
                              '${places.length} durak',
                              style: const TextStyle(
                                color: TripPlannerTheme.gold,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
            TripRouteStatsBar(
              duration: totalDuration,
              distance: totalDistance,
              cost: totalCost,
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: places.length,
                itemBuilder: (context, index) {
                  final place = places[index];
                  final isLast = index == places.length - 1;
                  final leg = !isLast && index < legs.length ? legs[index] : null;
                  final legKm = leg?.km;
                  final legMin = leg?.minutes;
                  return TripTimelineStop(
                    index: index,
                    place: place,
                    isLast: isLast,
                    legKm: legKm,
                    legMinutes: legMin,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ExploreDetailScreen(place: place)),
                    ),
                  );
                },
              ),
            ),
            _buildBottomStartBar(title, () => _planner.startTrip(title)),
          ],
        ),
      ),
    );
  }

  // === 5. AKTİF ADIM-ADIM NAVİGASYON ===
  Widget _buildActiveNavigationScreen(ThemeData theme, bool isDark) {
    final places = _planner.places;
    final activeIndex = _planner.activeStepIndex;
    final currentPlace = places[activeIndex];

    return Theme(
      data: TripPlannerTheme.theme(),
      child: Scaffold(
      backgroundColor: TripPlannerTheme.bg,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Özel Top App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Circular Back Arrow Button `<` in a glass border
                      GestureDetector(
                        onTap: () => _showStopTripDialog(theme),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: const Center(
                            child: Icon(Icons.chevron_left_rounded, color: Colors.white, size: 26),
                          ),
                        ),
                      ),
                      // Rota Aktif Adım Sayacı (örn: 1 / 4)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Text(
                          'Durak ${activeIndex + 1} / ${places.length}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          // Stylized vector illustrations of two travelers walking under the sky
                          const _TravelersIllustration(),
                          const SizedBox(height: 40),
                          const Text(
                            'Sıradaki Durak',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.grey,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            currentPlace.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Guidance Notice Box
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E2235), // Dark blueish box
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                            ),
                            child: Text(
                              'Varış yerine ulaştıktan sonra uygulamamıza geri dönüp \'Devam Et\' butonuna tıklayarak mekan hakkında bilgi alabilirsiniz.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.blue.shade100,
                                fontSize: 13,
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 48),
                          // Blue Button: Yol Tarifi Al
                          SizedBox(
                            width: 220,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (currentPlace.lat != null && currentPlace.lng != null) {
                                  LauncherUtils.openMapsWithLatLng(
                                      context, currentPlace.lat!, currentPlace.lng!);
                                } else {
                                  LauncherUtils.openMapsDirections(context, currentPlace.address);
                                }
                              },
                              icon: const Icon(Icons.near_me_rounded, size: 20),
                              label: const Text(
                                'Yol Tarifi Al',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF64B5F6), // Sky blue
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                                elevation: 0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Green Button: Devam Et
                          SizedBox(
                            width: 220,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: () => _openPlaceDetailsForNavigation(currentPlace),
                              icon: const Icon(Icons.flag_rounded, size: 20),
                              label: const Text(
                                'Devam Et',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CAF50), // Green
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                                elevation: 0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 36),
                          // Gray text link: Geri Adıma Dön
                          if (activeIndex > 0)
                            GestureDetector(
                              onTap: () => _planner.previousStep(),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: Text(
                                  'Geri Adıma Dön',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  void _openPlaceDetailsForNavigation(ExplorePlace place) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExploreDetailScreen(
          place: place,
          isActiveNavigation: true, // Adım adım kılavuz modunda aç
        ),
      ),
    );
  }

  // === E. DIALOG YARDIMCILARI ===
  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rotayı Temizle'),
        content: const Text('Tüm duraklar silinecek. Onaylıyor musunuz?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              _planner.clear();
              Navigator.pop(ctx);
            },
            child: const Text('Temizle', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showStopTripDialog(ThemeData theme) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seyahati Sonlandır'),
        content: const Text('Aktif seyahat deneyimini sonlandırmak ve ana ekrana dönmek istiyor musunuz?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hayır, Devam Et'),
          ),
          TextButton(
            onPressed: () {
              _planner.endTrip();
              setState(() {
                _showTimeline = false;
                _showIntro = false;
              });
              Navigator.pop(ctx);
            },
            child: const Text('Evet, Bitir', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// PURE FLUTTER VECTOR ILLUSTRATIONS (WOW FACTOR AESTHETICS)
// =====================================================================

/// 1. Camper Van Start Screen Illustration
class _CamperVanIllustration extends StatelessWidget {
  const _CamperVanIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Night sky circular backdrop
          Container(
            width: 200,
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              shape: BoxShape.circle,
            ),
          ),
          // Floating small stars
          Positioned(top: 40, left: 110, child: _buildVectorStar(8)),
          Positioned(top: 60, left: 70, child: _buildVectorStar(5)),
          Positioned(top: 80, left: 150, child: _buildVectorStar(6)),
          Positioned(top: 110, left: 60, child: _buildVectorStar(4)),
          // Mountain peaks (Triangular shapes)
          Positioned(
            bottom: 40,
            left: 55,
            child: ClipPath(
              clipper: _TriangleClipper(),
              child: Container(
                width: 100,
                height: 80,
                color: const Color(0xFF334155).withValues(alpha: 0.6),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 100,
            child: ClipPath(
              clipper: _TriangleClipper(),
              child: Container(
                width: 120,
                height: 90,
                color: const Color(0xFF475569).withValues(alpha: 0.8),
              ),
            ),
          ),
          // Little Pine Tree
          Positioned(
            bottom: 30,
            left: 45,
            child: Column(
              children: [
                ClipPath(
                  clipper: _TriangleClipper(),
                  child: Container(width: 24, height: 26, color: Colors.teal.shade800),
                ),
                ClipPath(
                  clipper: _TriangleClipper(),
                  child: Container(width: 32, height: 26, color: Colors.teal.shade900),
                ),
                Container(width: 6, height: 10, color: Colors.brown),
              ],
            ),
          ),
          // Campfire (Glow circles + logs)
          Positioned(
            bottom: 35,
            right: 50,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Fire glow ring
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                ),
                // Inner fire body
                Container(
                  width: 14,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                      bottomLeft: Radius.circular(2),
                      bottomRight: Radius.circular(2),
                    ),
                  ),
                ),
                Container(
                  width: 8,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Retro Camper Van (Body + Wheels + Window + Lights)
          Positioned(
            bottom: 38,
            left: 78,
            child: Stack(
              children: [
                // Glowing Headlight beam
                Positioned(
                  right: -55,
                  top: 14,
                  child: ClipPath(
                    clipper: _BeamClipper(),
                    child: Container(
                      width: 60,
                      height: 25,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amberAccent, Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                ),
                // Main Van Body
                Container(
                  width: 85,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF97316), // Orange
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(22),
                      bottomLeft: Radius.circular(6),
                      bottomRight: Radius.circular(6),
                    ),
                  ),
                ),
                // Top white roof strip
                Container(
                  width: 80,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                    ),
                  ),
                ),
                // Windows
                Positioned(
                  top: 6,
                  left: 10,
                  child: Container(
                    width: 22,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  left: 38,
                  child: Container(
                    width: 22,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 4,
                  child: Container(
                    width: 14,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E293B),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(3),
                        topLeft: Radius.circular(3),
                        bottomLeft: Radius.circular(3),
                      ),
                    ),
                  ),
                ),
                // Wheels
                Positioned(
                  bottom: -6,
                  left: 14,
                  child: _buildVectorWheel(),
                ),
                Positioned(
                  bottom: -6,
                  right: 18,
                  child: _buildVectorWheel(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVectorStar(double size) {
    return Icon(Icons.star_rounded, color: Colors.amberAccent, size: size);
  }

  Widget _buildVectorWheel() {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade400, width: 2),
      ),
      child: Center(
        child: Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

/// 2. Travelers Active Navigation Screen Illustration
class _TravelersIllustration extends StatelessWidget {
  const _TravelersIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Teal-blue soft backdrop ring
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.blue.shade900.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: Colors.blue.shade800.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
          ),
          // Dotted hiking path connector
          Positioned(
            left: 60,
            right: 60,
            top: 90,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                5,
                (i) => Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                ),
              ),
            ),
          ),
          // Stylized Vector Traveler 1 (Male Capsule Silhouette)
          Positioned(
            left: 125,
            bottom: 32,
            child: Column(
              children: [
                // Head
                Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(color: Color(0xFF90CAF9), shape: BoxShape.circle),
                ),
                const SizedBox(height: 4),
                // Body (Capsule)
                Container(
                  width: 22,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E88E5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),
          // Stylized Vector Traveler 2 (Female Capsule Silhouette)
          Positioned(
            right: 125,
            bottom: 32,
            child: Column(
              children: [
                // Head
                Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(color: Color(0xFFFFAB91), shape: BoxShape.circle),
                ),
                const SizedBox(height: 4),
                // Body (Capsule)
                Container(
                  width: 20,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE64A19),
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ],
            ),
          ),
          // Floating small location markers
          const Positioned(
            top: 25,
            left: 100,
            child: Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 24),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .moveY(begin: -5, end: 5, duration: 1000.ms),
          const Positioned(
            top: 45,
            right: 90,
            child: Icon(Icons.location_on_rounded, color: Colors.blueAccent, size: 18),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .moveY(begin: 3, end: -3, duration: 800.ms),
        ],
      ),
    );
  }
}

// =====================================================================
// VECTOR CUSTOM CLIPPERS
// =====================================================================

class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _BeamClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, size.height / 2)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// =====================================================================
// SEGMENT TAB — animated icon + label + optional count badge
// =====================================================================

class _SegmentTab extends StatelessWidget {
  const _SegmentTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.count,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 230),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
          decoration: BoxDecoration(
            gradient: isSelected ? TripPlannerTheme.goldGradient : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: isSelected
                ? Border.all(color: TripPlannerTheme.gold.withValues(alpha: 0.55))
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: TripPlannerTheme.gold.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? const Color(0xFF1A1508) : TripPlannerTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: isSelected ? const Color(0xFF1A1508) : TripPlannerTheme.textSecondary,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 230),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1A1508).withValues(alpha: 0.2)
                        : TripPlannerTheme.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? const Color(0xFF1A1508) : TripPlannerTheme.gold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// INTRO STAT CARD — colored icon + value card for route summary
// =====================================================================

class _IntroStatCard extends StatelessWidget {
  const _IntroStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: TripPlannerTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: TripPlannerTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: TripPlannerTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

