import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/utils/icon_mapper.dart';
import '../../core/utils/launcher_utils.dart';
import '../../core/utils/target_router.dart';
import '../../core/widgets/primary_card.dart';
import '../../core/widgets/service_page_layout.dart';
import '../../data/models/city_content.dart';
import 'directory_screen.dart';
import 'explore_detail_screen.dart';
import 'auto_gallery_screen.dart';

const _guideColor = Color(0xFF5C6BC0);

class CityGuideScreen extends ConsumerWidget {
  const CityGuideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cityContentProvider);
    return async.when(
      data: (content) => _CityGuideBody(
        content: content,
        onRefresh: () async => ref.invalidate(cityContentProvider),
      ),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Yüklenemedi: $e'))),
    );
  }
}

class _CityGuideBody extends StatelessWidget {
  const _CityGuideBody({required this.content, required this.onRefresh});

  final CityContent content;
  final Future<void> Function() onRefresh;

  static const _quickActions = <_QuickAction>[
    _QuickAction('Dolmuş', Icons.directions_bus_filled_rounded, Color(0xFF43A047), 'screen:transport'),
    _QuickAction('Taksi', Icons.local_taxi_rounded, Color(0xFFFFA726), 'screen:taxi'),
    _QuickAction('Akaryakıt', Icons.local_gas_station_rounded, Color(0xFFFF7043), 'screen:fuel'),
    _QuickAction('Eczane', Icons.local_pharmacy_rounded, Color(0xFFE53935), 'screen:pharmacy'),
    _QuickAction('Hava', Icons.wb_sunny_rounded, Color(0xFF29B6F6), 'screen:weather'),
    _QuickAction('Acil', Icons.sos_rounded, Color(0xFFD32F2F), 'screen:emergency'),
  ];

  List<ExplorePlace> get _guidePlaces {
    final cat = content.exploreCategories.where((c) => c.id == 'guide').toList();
    if (cat.isNotEmpty) return cat.first.places;
    return const [];
  }

  List<ExplorePlace> get _foodHighlights {
    final cat = content.exploreCategories.where((c) => c.id == 'food').toList();
    if (cat.isEmpty) return const [];
    return cat.first.places.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final directories = content.cityServices
        .where((s) => s.directoryData != null && s.directoryData!.isNotEmpty)
        .toList();

    return ServicePageLayout(
      title: 'Şehir Rehberi',
      subtitle: 'Ulaşım, merkez noktalar, pazarlar ve günlük hayat — Düziçi için tek rehber.',
      icon: 'location_city',
      color: _guideColor,
      onRefresh: onRefresh,
      child: SliverList(
        delegate: SliverChildListDelegate([
          _HeroBanner()
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: -0.04, end: 0),
          const SizedBox(height: 20),
          _SectionLabel(title: 'Hızlı Erişim', icon: Icons.bolt_rounded),
          const SizedBox(height: 10),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _quickActions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final a = _quickActions[i];
                return _QuickActionChip(
                  label: a.label,
                  icon: a.icon,
                  color: a.color,
                  onTap: () => TargetRouter.handle(context, a.target),
                ).animate(delay: (80 + i * 40).ms).fadeIn().scale(
                      begin: const Offset(0.92, 0.92),
                      end: const Offset(1, 1),
                    );
              },
            ),
          ),
          const SizedBox(height: 24),
          _SectionLabel(title: 'Temel Noktalar', icon: Icons.place_rounded),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _HubCard(
                  icon: Icons.account_balance_rounded,
                  color: const Color(0xFFE65100),
                  title: 'Düziçi Kaymakamlığı',
                  subtitle: 'Kurtuluş Mah. · Hükümet Konağı',
                  detail: 'İlçe Nüfus Müdürlüğü, Tapu, Malmüdürlüğü ve Sosyal Yardımlaşma Vakfı gibi idari birimler Hükümet Konağı binasında hizmet vermektedir.',
                  actionLabel: 'Haritada Göster',
                  onAction: () => LauncherUtils.openUrlExternal(context, 'https://www.google.com/maps/search/?api=1&query=Düziçi+Kaymakamlığı'),
                  onCall: () => LauncherUtils.callPhone(context, '03288761009'),
                ),
                _HubCard(
                  icon: Icons.corporate_fare_rounded,
                  color: const Color(0xFF00ACC1),
                  title: 'Düziçi Belediyesi',
                  subtitle: 'Kurtuluş Mah. · Refik Cesur Bulvarı No:140',
                  detail: 'Başkanlık makamı, Zabıta, İmar, Fen İşleri ve Beyaz Masa hizmetleri ana binada yer alır. Şikayet ve önerileriniz için Beyaz Masa hattını arayabilirsiniz.',
                  actionLabel: 'Belediye Birimleri',
                  onAction: () => TargetRouter.handle(context, 'screen:municipality'),
                  onCall: () => LauncherUtils.callPhone(context, '03288761259'),
                ),
                _HubCard(
                  icon: Icons.local_hospital_rounded,
                  color: const Color(0xFFE53935),
                  title: 'Düziçi Devlet Hastanesi',
                  subtitle: 'İrfanlı Mah. · Ahmet Lütfi Dağlar Bulvarı',
                  detail: 'Poliklinik hizmetleri, acil servis (7/24) ve yataklı tedavi üniteleri sunar. Randevu almak için ALO 182 veya MHRS platformlarını kullanabilirsiniz.',
                  actionLabel: 'Sağlık Kurumları',
                  onAction: () => TargetRouter.handle(context, 'screen:health'),
                  onCall: () => LauncherUtils.callPhone(context, '03288765496'),
                ),
              ],
            ),
          ),
          if (_guidePlaces.isNotEmpty) ...[
            const SizedBox(height: 24),
            _SectionLabel(title: 'Pratik Bilgiler', icon: Icons.menu_book_rounded),
            const SizedBox(height: 10),
            ..._guidePlaces.asMap().entries.map((e) {
              final p = e.value;
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: _GuidePlaceTile(
                  place: p,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ExploreDetailScreen(place: p),
                    ),
                  ),
                ).animate(delay: (120 + e.key * 50).ms).fadeIn().slideX(begin: 0.03, end: 0),
              );
            }),
          ],
          if (_foodHighlights.isNotEmpty) ...[
            const SizedBox(height: 14),
            _SectionLabel(title: 'Lezzet Durakları', icon: Icons.restaurant_rounded),
            const SizedBox(height: 10),
            SizedBox(
              height: 118,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _foodHighlights.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final p = _foodHighlights[i];
                  return _FoodChip(
                    place: p,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ExploreDetailScreen(place: p),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 24),
          _SectionLabel(title: 'Esnaf & Hizmet Rehberleri', icon: Icons.store_rounded),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.85,
              ),
              itemCount: directories.length + 1,
              itemBuilder: (context, i) {
                if (i == directories.length) {
                  final muniService = CityServiceItem(
                    id: 'muni_link',
                    icon: 'account_balance',
                    title: 'Belediye Birimleri',
                    subtitle: 'Müdürlükler & iletişim',
                    color: '#1565C0',
                    target: 'screen:municipality',
                  );
                  return _DirectoryGridCard(
                    service: muniService,
                    onTap: () => TargetRouter.handle(context, 'screen:municipality'),
                  );
                }
                final svc = directories[i];
                return _DirectoryGridCard(
                  service: svc,
                  onTap: () => _openDirectory(context, svc),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Text(
              'Güzergâh ve saatler kooperatif duyurularına göre değişebilir. Güncel bilgi için ilgili ekranları kullanın.',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).textTheme.bodySmall?.color,
                height: 1.4,
              ),
            ),
          ),
        ]),
      ),
    );
  }

  void _openDirectory(BuildContext context, CityServiceItem svc) {
    if (svc.directoryData == null) return;
    if (svc.id == 'auto_gallery') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
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
      MaterialPageRoute<void>(
        builder: (_) => DirectoryScreen(
          title: svc.title,
          subtitle: svc.subtitle,
          icon: svc.icon,
          color: _parseColor(svc.color),
          entries: svc.directoryData!,
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return _guideColor;
    }
  }
}

class _QuickAction {
  const _QuickAction(this.label, this.icon, this.color, this.target);
  final String label;
  final IconData icon;
  final Color color;
  final String target;
}

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3949AB), Color(0xFF5C6BC0), Color(0xFF7986CB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _guideColor.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.location_city_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Düziçi Şehir Rehberi',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Merkez, ulaşım ve günlük ihtiyaçlar tek ekranda',
                        style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _StatChip(icon: Icons.route_rounded, label: 'O-52 · D-400'),
                const SizedBox(width: 8),
                _StatChip(icon: Icons.pin_drop_rounded, label: 'Osmaniye ~33 km'),
                const SizedBox(width: 8),
                _StatChip(icon: Icons.tag_rounded, label: '80600'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: Colors.white70),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _guideColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              letterSpacing: -0.3,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 76,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.actionLabel,
    required this.onAction,
    this.onCall,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String detail;
  final String actionLabel;
  final VoidCallback onAction;
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    return PrimaryCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            detail,
            style: TextStyle(fontSize: 12.5, height: 1.4, color: Theme.of(context).textTheme.bodySmall?.color),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onAction,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                ),
              ),
              if (onCall != null) ...[
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: onCall,
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  child: const Icon(Icons.phone_rounded, size: 18),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _GuidePlaceTile extends StatelessWidget {
  const _GuidePlaceTile({required this.place, required this.onTap});
  final ExplorePlace place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PrimaryCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _guideColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.info_outline_rounded, color: _guideColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(place.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                if (place.shortDescription.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    place.shortDescription,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Theme.of(context).textTheme.bodySmall?.color),
        ],
      ),
    );
  }
}

class _FoodChip extends StatelessWidget {
  const _FoodChip({required this.place, required this.onTap});
  final ExplorePlace place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 140,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8F00).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    place.tag,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFE65100),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  place.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, height: 1.2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DirectoryGridCard extends StatelessWidget {
  const _DirectoryGridCard({required this.service, required this.onTap});
  final CityServiceItem service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(int.tryParse(service.color.replaceFirst('#', '0xFF')) ?? 0xFF5C6BC0);
    return PrimaryCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(IconMapper.fromName(service.icon), color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  service.subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
