import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/ui_tokens.dart';
import '../../core/widgets/app_section_header.dart';
import '../../core/widgets/app_pressable.dart';
import '../../core/widgets/skeleton_shimmer.dart';
import '../../core/utils/app_navigation.dart';
import '../../core/utils/weather_wmo_tr.dart';
import '../../core/utils/icon_mapper.dart';
import 'emergency_numbers_screen.dart';
import 'health_facilities_screen.dart';
import 'municipality_units_screen.dart';
import '../news/news_screen.dart';
import '../pharmacy/pharmacy_screen.dart';
import '../veterinary/veterinary_screen.dart';
import '../prayer/prayer_screen.dart';
import '../weather/weather_screen.dart';
import '../../data/models/city_content.dart';
import 'transportation_screen.dart';
import 'outages_screen.dart';
import 'closed_roads_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class ServicesScreen extends ConsumerStatefulWidget {
  const ServicesScreen({super.key});

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(cityContentProvider);
    final prayerAsync = ref.watch(stampedPrayerProvider);
    final weatherAsync = ref.watch(stampedWeatherProvider);
    final pharmacyAsync = ref.watch(stampedPharmacyProvider);

    return async.when(
      data: (content) {
        final activeTiles = content.serviceTiles.where((t) => t.isActive).toList();
        final acilSaglik = activeTiles.where((t) => ['pharmacy', 'health', 'emergency'].contains(t.id)).toList();
        final sehirHayati = activeTiles.where((t) => ['outages', 'transport', 'news_center', 'prayer', 'weather'].contains(t.id)).toList();
        final resmiIslemler = activeTiles.where((t) => ['municipality'].contains(t.id)).toList();

        bool matchesSearch(ServiceTileItem tile) {
          return tile.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                 tile.subtitle.toLowerCase().contains(_searchQuery.toLowerCase());
        }

        final filteredAcil = acilSaglik.where(matchesSearch).toList();
        final filteredSehir = sehirHayati.where(matchesSearch).toList();
        final filteredResmi = resmiIslemler.where(matchesSearch).toList();

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(cityContentProvider),
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(
                child: _ServiceHeader(
                  onSearchChanged: (val) => setState(() => _searchQuery = val),
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: -0.05, end: 0, curve: Curves.easeOutCubic),
              ),
              if (_searchQuery.isEmpty)
                SliverToBoxAdapter(
                  child: _ServiceBentoGrid(
                    prayerSnippet: prayerAsync.maybeWhen(
                      data: (d) {
                        final next = d.data.nextPrayer(DateFormat('HH:mm').format(DateTime.now()));
                        return next != null ? '${next.name} ${next.time}' : '...';
                      },
                      orElse: () => 'Yükleniyor...',
                    ),
                    weatherSnippet: weatherAsync.maybeWhen(
                      data: (d) {
                        final w = d.data.current;
                        final precip = precipitationLevelTr(w.conditionCode);
                        final trail = precip == null ? '' : ' · $precip';
                        return '${w.temperature.round()}°C · ${w.conditionText}'
                            '${w.windSpeed != null ? ' · ${windSummaryTr(w.windSpeed, w.windGust)}' : ''}$trail';
                      },
                      orElse: () => '...',
                    ),
                    pharmacyCount: pharmacyAsync.maybeWhen(
                      data: (d) => '${d.data.length} Açık',
                      orElse: () => '...',
                    ),
                    onPharmacyTap: () => _openServiceTarget(context, 'pharmacy', content),
                    onPrayerTap: () => _openServiceTarget(context, 'prayer', content),
                    onWeatherTap: () => _openServiceTarget(context, 'weather', content),
                    onNewsTap: () => _openServiceTarget(context, 'news', content),
                  ).animate(delay: 150.ms).fadeIn().scale(begin: const Offset(0.98, 0.98)),
                ),
              
              if (filteredAcil.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: const AppSectionHeader(title: 'Acil ve Sağlık')
                      .animate(delay: 250.ms).fadeIn(),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _ServiceTile(
                      tile: filteredAcil[index],
                      onTap: () => _openServiceTarget(context, filteredAcil[index].target, content),
                    ).animate(delay: (300 + (index * 50)).ms).fadeIn().slideX(begin: 0.05, end: 0),
                    childCount: filteredAcil.length,
                  ),
                ),
              ],

              if (filteredSehir.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: const AppSectionHeader(title: 'Şehir Dinamiği')
                      .animate(delay: 400.ms).fadeIn(),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _ServiceTile(
                      tile: filteredSehir[index],
                      onTap: () => _openServiceTarget(context, filteredSehir[index].target, content),
                    ).animate(delay: (450 + (index * 50)).ms).fadeIn().slideX(begin: 0.05, end: 0),
                    childCount: filteredSehir.length,
                  ),
                ),
              ],

              if (filteredResmi.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: const AppSectionHeader(title: 'Resmi İşlemler')
                      .animate(delay: 550.ms).fadeIn(),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _ServiceTile(
                      tile: filteredResmi[index],
                      onTap: () => _openServiceTarget(context, filteredResmi[index].target, content),
                    ).animate(delay: (600 + (index * 50)).ms).fadeIn().slideX(begin: 0.05, end: 0),
                    childCount: filteredResmi.length,
                  ),
                ),
              ],

              if (_searchQuery.isEmpty) ...[
                SliverToBoxAdapter(
                  child: const AppSectionHeader(title: 'Hızlı İletişim')
                      .animate(delay: 700.ms).fadeIn(),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ContactCard(
                            icon: Icons.chat_bubble_rounded,
                            title: 'WhatsApp',
                            color: const Color(0xFF25D366),
                            onTap: () => launchUrl(Uri.parse('https://wa.me/903288760001')),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ContactCard(
                            icon: Icons.headset_mic_rounded,
                            title: 'Alo 153',
                            color: AppColors.primary,
                            onTap: () => launchUrl(Uri.parse('tel:153')),
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: 800.ms).fadeIn().slideY(begin: 0.1, end: 0),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 60)),
            ],
          ),
        );
      },
      loading: () => const _ServicesLoadingSkeleton(),
      error: (e, _) => _ErrorState(error: e.toString(), onRetry: () => ref.invalidate(cityContentProvider)),
    );
  }

  void _push(BuildContext context, Widget page) {
    AppNavigation.push<void>(context, page);
  }

  void _openServiceTarget(BuildContext context, String target, CityContent content) {
    switch (target) {
      case 'pharmacy':
        _push(context, const PharmacyScreen());
        break;
      case 'prayer':
        _push(context, const PrayerScreen());
        break;
      case 'weather':
        _push(context, const WeatherScreen());
        break;
      case 'news':
        _push(context, const NewsScreen());
        break;
      case 'health':
        _push(context, const HealthFacilitiesScreen());
        break;
      case 'veterinary':
        _push(context, const VeterinaryScreen());
        break;
      case 'emergency':
        _push(context, const EmergencyNumbersScreen());
        break;
      case 'municipality':
        _push(context, const MunicipalityUnitsScreen());
        break;
      case 'outages':
        _push(context, const OutagesScreen());
        break;
      case 'closed_roads':
        _push(context, const ClosedRoadsScreen());
        break;
      case 'transport':
        _push(context, TransportationScreen(data: content.transportation));
        break;
      default:
        break;
    }
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ContactCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.softGrey.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('Hizmetler yüklenemedi', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Tekrar dene'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServicesLoadingSkeleton extends StatelessWidget {
  const _ServicesLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      children: [
        const SkeletonBlock(height: 30, width: 210, radius: 10),
        const SizedBox(height: 12),
        const SkeletonBlock(height: 14, width: 170, radius: 8),
        const SizedBox(height: 22),
        const SkeletonBlock(height: 52, radius: 18),
        const SizedBox(height: 20),
        const SkeletonBlock(height: 180, radius: 28),
        const SizedBox(height: 24),
        const SkeletonBlock(height: 22, width: 180, radius: 8),
        const SizedBox(height: 12),
        ...List.generate(
          4,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: const SkeletonBlock(height: 92, radius: 24),
          ),
        ),
      ],
    );
  }
}

class _ServiceHeader extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;

  const _ServiceHeader({required this.onSearchChanged});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Şehir Hizmetleri',
                    style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: -1.2,
                          fontSize: 28.0,
                        ),
                  ),
                  Text(
                    'İhtiyacın olan her şey burada.',
                    style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(UiTokens.radiusControl),
              boxShadow: UiTokens.softShadow(opacity: 0.035),
              border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
            ),
            child: TextField(
              onChanged: onSearchChanged,
              style: const TextStyle(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Hizmet veya birim ara...',
                hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.6)),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceBentoGrid extends StatelessWidget {
  const _ServiceBentoGrid({
    required this.onPharmacyTap,
    required this.onPrayerTap,
    required this.onWeatherTap,
    required this.onNewsTap,
    required this.prayerSnippet,
    required this.weatherSnippet,
    required this.pharmacyCount,
  });

  final VoidCallback onPharmacyTap;
  final VoidCallback onPrayerTap;
  final VoidCallback onWeatherTap;
  final VoidCallback onNewsTap;
  final String prayerSnippet;
  final String weatherSnippet;
  final String pharmacyCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        height: 200,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: _BentoItem(
                title: 'Nöbetçi\nEczaneler',
                subtitle: pharmacyCount,
                icon: Icons.local_pharmacy_rounded,
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.blueGrey.withValues(alpha: 0.2) 
                    : const Color(0xFFE3F2FD),
                iconColor: Colors.blueAccent,
                onTap: onPharmacyTap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  Expanded(
                    child: _BentoItem(
                      title: 'Namaz Vakitleri',
                      subtitle: prayerSnippet,
                      icon: Icons.mosque_rounded,
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.blueGrey.withValues(alpha: 0.2) 
                          : const Color(0xFFE8F5E9),
                      iconColor: Colors.green,
                      isHorizontal: true,
                      onTap: onPrayerTap,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _BentoItem(
                      title: 'Hava Durumu',
                      subtitle: weatherSnippet,
                      icon: Icons.cloud_rounded,
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.blueGrey.withValues(alpha: 0.2) 
                          : const Color(0xFFFFF3E0),
                      iconColor: Colors.orange,
                      isHorizontal: true,
                      onTap: onWeatherTap,
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
}

class _BentoItem extends StatelessWidget {
  const _BentoItem({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.onTap,
    this.isHorizontal = false,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isHorizontal;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? color.withValues(alpha: 0.15) 
            : color,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(32),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(32),
          child: Container(
            padding: EdgeInsets.all(isHorizontal ? 14 : 20),
            width: double.infinity,
            child: isHorizontal
                ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.black.withValues(alpha: 0.2) 
                              : Colors.white.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: iconColor, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w900, 
                                fontSize: 16, 
                                letterSpacing: -0.8, 
                                height: 1.1,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: iconColor.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.black.withValues(alpha: 0.2) 
                                  : Colors.white.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: iconColor, size: 24),
                          ),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness == Brightness.dark 
                                      ? Colors.black.withValues(alpha: 0.2) 
                                      : Colors.white.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 4,
                                      decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                                    ).animate(onPlay: (c) => c.repeat()).scale(duration: 1000.ms, begin: const Offset(1, 1), end: const Offset(1.5, 1.5)).fadeOut(),
                                    const SizedBox(width: 4),
                                    const Text('CANLI', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w900, 
                          fontSize: 18, 
                          height: 1.1, 
                          letterSpacing: -0.8,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: TextStyle(color: iconColor.withValues(alpha: 0.8), fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.tile,
    this.onTap,
  });

  final ServiceTileItem tile;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = _getTileColor(tile.id);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: AppPressable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(UiTokens.radiusCard),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(UiTokens.radiusCard),
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
            boxShadow: UiTokens.softShadow(opacity: 0.03),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withValues(alpha: 0.15),
                        color.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(IconMapper.fromName(tile.icon), color: color, size: 26),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tile.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: -0.4,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tile.subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.softGrey,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getTileColor(String id) {
    switch (id) {
      case 'pharmacy':
        return Colors.teal;
      case 'prayer':
        return Colors.green[700]!;
      case 'weather':
        return Colors.blue[600]!;
      case 'news_center':
        return Colors.indigoAccent;
      case 'health':
        return Colors.blueAccent;
      case 'emergency':
        return Colors.redAccent;
      case 'municipality':
        return Colors.amber[800]!;
      case 'outages':
        return Colors.orange;
      case 'transport':
        return Colors.deepPurple;
      default:
        return AppColors.primary;
    }
  }
}
