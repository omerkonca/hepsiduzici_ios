import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../app/providers.dart';
import '../../core/utils/launcher_utils.dart';
import '../../core/widgets/favorite_button.dart';
import '../../core/widgets/primary_card.dart';
import '../../core/widgets/service_page_layout.dart';
import '../../data/models/veterinarian.dart';
import '../../data/services/favorites_service.dart';

class _MahalleCoords {
  final double lat;
  final double lng;
  const _MahalleCoords(this.lat, this.lng);
}

class VeterinaryScreen extends ConsumerStatefulWidget {
  const VeterinaryScreen({super.key});

  @override
  ConsumerState<VeterinaryScreen> createState() => _VeterinaryScreenState();
}

class _VeterinaryScreenState extends ConsumerState<VeterinaryScreen> {
  static const _accent = Color(0xFF7CB342);

  String _searchQuery = '';
  String _selectedCategory = 'Tümü';
  String _selectedMahalle = 'Seçiniz...';

  double? _userLat;
  double? _userLng;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _getUserLocation());
  }

  static const Map<String, _MahalleCoords> _mahalleler = {
    'Seçiniz...': _MahalleCoords(0, 0),
    'İrfanlı Mahallesi': _MahalleCoords(37.2440, 36.4510),
    'Cumhuriyet Mahallesi': _MahalleCoords(37.2400, 36.4460),
    'Yeşilova Mahallesi': _MahalleCoords(37.2380, 36.4480),
    'Şehitler Mahallesi': _MahalleCoords(37.2420, 36.4490),
    'İstiklal Mahallesi': _MahalleCoords(37.2410, 36.4550),
    'Kurtuluş Mahallesi': _MahalleCoords(37.2340, 36.4420),
    'Üzümlü Mahallesi': _MahalleCoords(37.2280, 36.4650),
    'Karlıca Mahallesi': _MahalleCoords(37.2450, 36.4350),
    'Hürriyet Mahallesi': _MahalleCoords(37.2500, 36.4600),
    'Ellek Beldesi': _MahalleCoords(37.2880, 36.4800),
    'Yarbaşı Beldesi': _MahalleCoords(37.1990, 36.4300),
  };

  Future<void> _getUserLocation() async {
    setState(() => _isLocating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _snack('Konum servisleri kapalı. GPS\'i açın.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _snack('Konum izni gerekli. Yakındaki veterinerler sıralanamaz.');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      setState(() {
        _userLat = position.latitude;
        _userLng = position.longitude;
        _selectedMahalle = 'Seçiniz...';
      });
      _snack('En yakın veterinerler listenin başında.');
    } catch (_) {
      _snack('Konum alınamadı. Mahalle seçerek deneyebilirsiniz.');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLng = _deg2rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _deg2rad(double deg) => deg * (math.pi / 180);

  bool _isOpenNow(VeterinarianItem v) {
    final h = v.workingHours?.toLowerCase() ?? '';
    if (h.contains('randevu')) return true;
    if (h.contains('7/24')) return true;
    final now = DateTime.now();
    if (now.weekday == DateTime.saturday && h.contains('cumartesi')) return true;
    if (now.weekday == DateTime.sunday && !h.contains('pazar')) return false;
    final hour = now.hour;
    return hour >= 9 && hour < 19;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(cityContentProvider);
    return async.when(
      data: (content) => _buildBody(context, content.veterinarians),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Veteriner')),
        body: Center(child: Text('Veriler yüklenemedi: $e')),
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<VeterinarianItem> all) {
    final isUsingGps = _userLat != null && _userLng != null;
    final isUsingMahalle = _selectedMahalle != 'Seçiniz...';

    var list = all.where((v) {
      final q = _searchQuery.toLowerCase();
      if (q.isEmpty) return true;
      return v.name.toLowerCase().contains(q) ||
          v.address.toLowerCase().contains(q) ||
          v.neighborhood.toLowerCase().contains(q) ||
          v.type.toLowerCase().contains(q);
    }).toList();

    if (_selectedCategory != 'Tümü') {
      list = list.where((v) => v.type == _selectedCategory).toList();
    }

    final distances = <String, double>{};
    if (isUsingGps || isUsingMahalle) {
      final refLat = isUsingGps ? _userLat! : _mahalleler[_selectedMahalle]!.lat;
      final refLng = isUsingGps ? _userLng! : _mahalleler[_selectedMahalle]!.lng;
      for (final v in list) {
        if (v.hasCoords) {
          distances[v.id] = _distanceKm(refLat, refLng, v.lat!, v.lng!);
        }
      }
      list.sort((a, b) {
        final da = distances[a.id] ?? 999;
        final db = distances[b.id] ?? 999;
        return da.compareTo(db);
      });
    } else {
      list.sort((a, b) {
        if (a.hasPhone && !b.hasPhone) return -1;
        if (!a.hasPhone && b.hasPhone) return 1;
        return a.name.compareTo(b.name);
      });
    }

    final clinicCount = all.where((v) => v.type == 'Klinik').length;
    final muayeneCount = all.where((v) => v.type == 'Muayenehane').length;
    final petCount = all.where((v) => v.type == 'Pet Shop').length;

    return ServicePageLayout(
      title: 'Veteriner Rehberi',
      subtitle: 'Düziçi\'deki tüm veteriner klinikleri, muayenehaneler ve pet shop\'lar.',
      icon: 'pets',
      color: _accent,
      onRefresh: () async => ref.invalidate(cityContentProvider),
      isEmpty: all.isEmpty,
      emptyMessage: 'Henüz veteriner kaydı bulunmuyor.',
      child: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: _HeroStatsCard(
                total: all.length,
                clinics: clinicCount,
                muayene: muayeneCount,
                petShops: petCount,
              ).animate().fadeIn(duration: 350.ms),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _NearestPanel(
                isLocating: _isLocating,
                isUsingGps: isUsingGps,
                selectedMahalle: _selectedMahalle,
                mahalleler: _mahalleler.keys.toList(),
                onGps: _getUserLocation,
                onMahalleChanged: (val) {
                  setState(() {
                    _selectedMahalle = val ?? 'Seçiniz...';
                    _userLat = null;
                    _userLng = null;
                  });
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Klinik, mahalle veya hizmet ara...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _CategoryChip(
                    label: 'Tümü',
                    count: all.length,
                    selected: _selectedCategory == 'Tümü',
                    color: _accent,
                    onTap: () => setState(() => _selectedCategory = 'Tümü'),
                  ),
                  _CategoryChip(
                    label: 'Klinik',
                    count: clinicCount,
                    selected: _selectedCategory == 'Klinik',
                    color: const Color(0xFF558B2F),
                    onTap: () => setState(() => _selectedCategory = 'Klinik'),
                  ),
                  _CategoryChip(
                    label: 'Muayenehane',
                    count: muayeneCount,
                    selected: _selectedCategory == 'Muayenehane',
                    color: const Color(0xFF689F38),
                    onTap: () => setState(() => _selectedCategory = 'Muayenehane'),
                  ),
                  _CategoryChip(
                    label: 'Pet Shop',
                    count: petCount,
                    selected: _selectedCategory == 'Pet Shop',
                    color: const Color(0xFF9CCC65),
                    onTap: () => setState(() => _selectedCategory = 'Pet Shop'),
                  ),
                ],
              ),
            ),
          ),
          if (list.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: Text(
                    'Arama kriterlerinize uygun kayıt bulunamadı.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final v = list[index];
                  final dist = distances[v.id];
                  final isNearest = index == 0 && (isUsingGps || isUsingMahalle) && dist != null;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                    child: _VetCard(
                      vet: v,
                      distanceKm: dist,
                      isNearest: isNearest,
                      isUsingGps: isUsingGps,
                      isOpen: _isOpenNow(v),
                      mahalleLabel: isUsingMahalle && !isUsingGps ? _selectedMahalle : null,
                    ).animate(delay: (index * 40).ms).fadeIn().slideY(begin: 0.03, end: 0),
                  );
                },
                childCount: list.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 48)),
        ],
      ),
    );
  }
}

class _HeroStatsCard extends StatelessWidget {
  const _HeroStatsCard({
    required this.total,
    required this.clinics,
    required this.muayene,
    required this.petShops,
  });

  final int total;
  final int clinics;
  final int muayene;
  final int petShops;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF558B2F), Color(0xFF7CB342)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7CB342).withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.pets_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Düziçi Veteriner Rehberi',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$total kayıtlı işletme · $clinics klinik · $muayene muayenehane',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (petShops > 0)
                  Text(
                    '$petShops pet shop',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NearestPanel extends StatelessWidget {
  const _NearestPanel({
    required this.isLocating,
    required this.isUsingGps,
    required this.selectedMahalle,
    required this.mahalleler,
    required this.onGps,
    required this.onMahalleChanged,
  });

  final bool isLocating;
  final bool isUsingGps;
  final String selectedMahalle;
  final List<String> mahalleler;
  final VoidCallback onGps;
  final ValueChanged<String?> onMahalleChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUsingGps
              ? const Color(0xFF7CB342).withValues(alpha: 0.5)
              : Theme.of(context).dividerColor.withValues(alpha: 0.08),
          width: isUsingGps ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.near_me_rounded,
                size: 18,
                color: isUsingGps ? const Color(0xFF7CB342) : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Yakınımdaki Veteriner',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedMahalle,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Mahalle merkezine göre',
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: mahalleler
                      .map((m) => DropdownMenuItem(value: m, child: Text(m, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: onMahalleChanged,
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: isUsingGps ? const Color(0xFF7CB342) : const Color(0xFF558B2F),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: isLocating ? null : onGps,
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: isLocating
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(
                            isUsingGps ? Icons.gps_fixed_rounded : Icons.my_location_rounded,
                            color: Colors.white,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: selected,
        showCheckmark: false,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: selected ? Colors.white : null)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected ? Colors.white.withValues(alpha: 0.25) : color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: selected ? Colors.white : color),
              ),
            ),
          ],
        ),
        selectedColor: color,
        backgroundColor: Theme.of(context).colorScheme.surface,
        side: BorderSide(color: selected ? color : Theme.of(context).dividerColor.withValues(alpha: 0.15)),
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _VetCard extends StatelessWidget {
  const _VetCard({
    required this.vet,
    required this.distanceKm,
    required this.isNearest,
    required this.isUsingGps,
    required this.isOpen,
    this.mahalleLabel,
  });

  final VeterinarianItem vet;
  final double? distanceKm;
  final bool isNearest;
  final bool isUsingGps;
  final bool isOpen;
  final String? mahalleLabel;

  Color get _typeColor {
    switch (vet.type) {
      case 'Klinik':
        return const Color(0xFF558B2F);
      case 'Pet Shop':
        return const Color(0xFF9CCC65);
      default:
        return const Color(0xFF689F38);
    }
  }

  IconData get _typeIcon {
    switch (vet.type) {
      case 'Klinik':
        return Icons.medical_services_rounded;
      case 'Pet Shop':
        return Icons.storefront_rounded;
      default:
        return Icons.pets_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    String? distanceText;
    if (distanceKm != null) {
      final min = ((distanceKm! / 40) * 60).round() + 1;
      if (isUsingGps) {
        distanceText = '${distanceKm!.toStringAsFixed(1)} km · yaklaşık $min dk';
      } else if (mahalleLabel != null) {
        distanceText = '$mahalleLabel merkezine ${distanceKm!.toStringAsFixed(1)} km';
      }
    }

    return PrimaryCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _typeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _typeColor.withValues(alpha: 0.2)),
                    ),
                    child: Icon(_typeIcon, color: _typeColor, size: 32),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        vet.neighborhood,
                        style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isNearest)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFB300).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'EN YAKIN',
                              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFFFF8F00)),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            vet.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                          ),
                        ),
                        FavoriteButton(id: 'vet_${vet.id}', category: FavoriteCategory.service, size: 20),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _Badge(text: vet.type, color: _typeColor),
                        const SizedBox(width: 6),
                        _Badge(
                          text: isOpen ? 'Muhtemelen açık' : 'Kapalı olabilir',
                          color: isOpen ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (vet.services.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: vet.services
                  .take(4)
                  .map((s) => Chip(
                        label: Text(s, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: BorderSide(color: _typeColor.withValues(alpha: 0.25)),
                      ))
                  .toList(),
            ),
          ],
          if (vet.workingHours != null && vet.workingHours!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 14, color: Theme.of(context).textTheme.bodySmall?.color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    vet.workingHours!,
                    style: TextStyle(fontSize: 11.5, color: Theme.of(context).textTheme.bodySmall?.color, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
          if (distanceText != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.directions_car_filled_outlined, size: 14, color: Color(0xFF7CB342)),
                const SizedBox(width: 4),
                Text(distanceText, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF558B2F))),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on_outlined, size: 15, color: Theme.of(context).textTheme.bodySmall?.color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  vet.address,
                  style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          if (vet.note != null) ...[
            const SizedBox(height: 6),
            Text(
              vet.note!,
              style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.8), fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (vet.hasPhone)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => LauncherUtils.callPhone(context, vet.phone!),
                    icon: const Icon(Icons.phone_rounded, size: 16),
                    label: Text(vet.phone!, style: const TextStyle(fontSize: 12)),
                    style: FilledButton.styleFrom(backgroundColor: _typeColor, padding: const EdgeInsets.symmetric(vertical: 10)),
                  ),
                ),
              if (vet.hasPhone) const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (vet.hasCoords) {
                      LauncherUtils.openMapsWithLatLng(context, vet.lat!, vet.lng!);
                    } else {
                      LauncherUtils.openMapsWithAddress(context, vet.address);
                    }
                  },
                  icon: const Icon(Icons.map_rounded, size: 16),
                  label: Text(vet.hasPhone ? 'Harita' : 'Haritada Ara', style: const TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _typeColor,
                    side: BorderSide(color: _typeColor.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              if (vet.hasPhone) ...[
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: () => LauncherUtils.openWhatsApp(context, vet.phone!, message: 'Merhaba, ${vet.name} hakkında bilgi almak istiyorum.'),
                  icon: const Icon(Icons.chat_rounded, size: 20),
                  style: IconButton.styleFrom(foregroundColor: const Color(0xFF25D366)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color)),
    );
  }
}
