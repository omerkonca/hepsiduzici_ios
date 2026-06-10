import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/launcher_utils.dart';
import '../../core/utils/target_router.dart';
import '../../core/widgets/primary_card.dart';
import '../../core/widgets/service_page_layout.dart';
import '../../data/models/city_content.dart';

class _MahalleCoords {
  final double lat;
  final double lng;
  const _MahalleCoords(this.lat, this.lng);
}

class HealthFacilitiesScreen extends ConsumerStatefulWidget {
  const HealthFacilitiesScreen({super.key});

  @override
  ConsumerState<HealthFacilitiesScreen> createState() => _HealthFacilitiesScreenState();
}

class _HealthFacilitiesScreenState extends ConsumerState<HealthFacilitiesScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'Hepsi'; // 'Hepsi', 'Hastaneler', 'Aile Sağlığı', 'Diş Sağlığı'
  String _selectedMahalle = 'Seçiniz...';

  // GPS Location variables
  double? _userLat;
  double? _userLng;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _getUserLocation());
  }

  // Düziçi neighborhood coordinates
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
    'Kuşçu Köyü / Haruniye': _MahalleCoords(37.2750, 36.4900),
  };

  // GPS geolocation fetch
  Future<void> _getUserLocation() async {
    setState(() {
      _isLocating = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Konum servisleri kapalı. Lütfen telefonunuzun GPS servisini açın.')),
          );
        }
        setState(() {
          _isLocating = false;
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Konum izni reddedildi. En yakın yerler otomatik sıralanamıyor.')),
            );
          }
          setState(() {
            _isLocating = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Konum izni kalıcı olarak reddedildi. Lütfen ayarlardan izin verin.')),
          );
        }
        setState(() {
          _isLocating = false;
        });
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
        _selectedMahalle = 'Seçiniz...'; // Reset manual neighborhood
        _isLocating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konumunuz başarıyla alındı! En yakın kurumlar en üstte sıralandı.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Konum bilgisi alınamadı: $e')),
        );
      }
      setState(() {
        _isLocating = false;
      });
    }
  }

  // Distance calculation using Haversine
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const p = 0.017453292519943295; // Pi / 180
    final a = 0.5 - math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) *
            (1 - math.cos((lng2 - lng1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a)); // 2 * R; R = 6371 km
  }

  // Active status calculation
  bool _isFacilityOpen(HealthFacilityItem f) {
    if (f.workingHours == '7/24 Açık') return true;

    final now = DateTime.now();
    // Closed on weekends (Saturday = 6, Sunday = 7)
    if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
      return false;
    }

    int startHour = 8;
    int startMinute = 0;
    int endHour = 17;
    int endMinute = 0;

    if (f.workingHours != null) {
      final match = RegExp(r'(\d{2}):(\d{2})\s*-\s*(\d{2}):(\d{2})').firstMatch(f.workingHours!);
      if (match != null) {
        startHour = int.tryParse(match.group(1) ?? '8') ?? 8;
        startMinute = int.tryParse(match.group(2) ?? '0') ?? 0;
        endHour = int.tryParse(match.group(3) ?? '17') ?? 17;
        endMinute = int.tryParse(match.group(4) ?? '0') ?? 0;
      }
    }

    final start = DateTime(now.year, now.month, now.day, startHour, startMinute);
    final end = DateTime(now.year, now.month, now.day, endHour, endMinute);

    return now.isAfter(start) && now.isBefore(end);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(cityContentProvider);
    final bool isUsingGps = _userLat != null && _userLng != null;

    return async.when(
      data: (content) {
        // 1. Search and category filters
        var facilities = content.healthFacilities.where((f) {
          final query = _searchQuery.toLowerCase();
          final matchesQuery = f.name.toLowerCase().contains(query) ||
              f.address.toLowerCase().contains(query) ||
              f.type.toLowerCase().contains(query);

          if (!matchesQuery) return false;

          if (_selectedCategory == 'Hastaneler') {
            return f.type.contains('Hastanesi');
          } else if (_selectedCategory == 'Aile Sağlığı') {
            return f.type.contains('Aile Sağlığı') || f.type.contains('ASM');
          } else if (_selectedCategory == 'Diş Sağlığı') {
            return f.type.contains('Diş');
          }
          return true;
        }).toList();

        // 2. Sort by distance if GPS or neighborhood selected
        Map<String, double> calculatedDistances = {};
        final bool isUsingMahalle = _selectedMahalle != 'Seçiniz...';

        if (isUsingGps || isUsingMahalle) {
          final double refLat = isUsingGps ? _userLat! : _mahalleler[_selectedMahalle]!.lat;
          final double refLng = isUsingGps ? _userLng! : _mahalleler[_selectedMahalle]!.lng;

          for (final f in facilities) {
            if (f.lat != null && f.lng != null) {
              final dist = _calculateDistance(refLat, refLng, f.lat!, f.lng!);
              calculatedDistances[f.name] = dist;
            }
          }
          // Sort nearest to farthest
          facilities.sort((a, b) {
            final distA = calculatedDistances[a.name] ?? 999.0;
            final distB = calculatedDistances[b.name] ?? 999.0;
            return distA.compareTo(distB);
          });
        } else {
          // Default sorting: Emergency available first (hospitals)
          facilities.sort((a, b) {
            final isEmergA = a.isEmergency ?? false;
            final isEmergB = b.isEmergency ?? false;
            if (isEmergA && !isEmergB) return -1;
            if (!isEmergA && isEmergB) return 1;
            return a.name.compareTo(b.name);
          });
        }

        return ServicePageLayout(
          title: 'Sağlık Kurumları',
          subtitle: '', // Removed generic top banner to eliminate text clutter
          icon: 'local_hospital',
          color: const Color(0xFF1E88E5),
          onRefresh: () async => ref.invalidate(cityContentProvider),
          isEmpty: facilities.isEmpty && _searchQuery.isEmpty,
          child: SliverMainAxisGroup(
            slivers: [
              // Sleek Screen Intro Description
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                  child: Text(
                    'Düziçi genelindeki sağlık merkezleri, hastaneler ve aile hekimlikleri. Konumunuza en yakın kurumları bulabilir ve tek tıkla arama yapabilirsiniz.',
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.45,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // Super Premium Combined Quick Access Row (112 Emergency Call + Duty Pharmacies)
              SliverToBoxAdapter(
                child: _QuickAccessRow(
                  onTapPharmacy: () => TargetRouter.handle(context, 'screen:pharmacy'),
                  onTapVeterinary: () => TargetRouter.handle(context, 'screen:veterinary'),
                ),
              ),

              // Super Sleek Search & Filter Panel (Collapses locating widgets inline)
              SliverToBoxAdapter(
                child: _SearchAndFilterPanel(
                  searchQuery: _searchQuery,
                  onSearchChanged: (val) => setState(() => _searchQuery = val),
                  selectedCategory: _selectedCategory,
                  onCategoryChanged: (cat) => setState(() => _selectedCategory = cat),
                  selectedMahalle: _selectedMahalle,
                  onMahalleChanged: (val) {
                    setState(() {
                      _selectedMahalle = val ?? 'Seçiniz...';
                      _userLat = null;
                      _userLng = null;
                    });
                  },
                  isLocating: _isLocating,
                  onGpsPressed: _getUserLocation,
                  isUsingGps: isUsingGps,
                  mahalleler: _mahalleler.keys.toList(),
                ),
              ),

              // List of Health Facilities
              facilities.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.search_off_rounded, size: 44, color: Colors.grey.shade500),
                              const SizedBox(height: 12),
                              Text(
                                'Arama kriterlerinize uygun sağlık kuruluşu bulunamadı.',
                                style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final f = facilities[index];
                          final isOpen = _isFacilityOpen(f);
                          final distance = calculatedDistances[f.name];

                          // Distance and driving time texts
                          String? distanceText;
                          if (distance != null) {
                            final min = ((distance / 45) * 60).round() + 1;
                            if (isUsingGps) {
                              distanceText = 'Konumunuza ${distance.toStringAsFixed(1)} km uzaklıkta (yaklaşık $min dk sürüş)';
                            } else {
                              distanceText = '$_selectedMahalle merkezine ${distance.toStringAsFixed(1)} km (yaklaşık $min dk sürüş)';
                            }
                          }

                          // Type based icon and color
                          IconData typeIcon = Icons.local_hospital_rounded;
                          Color typeColor = const Color(0xFF1E88E5);
                          if (f.type.contains('Diş')) {
                            typeIcon = Icons.medical_services_rounded;
                            typeColor = Colors.cyan.shade700;
                          } else if (f.type.contains('ASM') || f.type.contains('Aile Sağlığı')) {
                            typeIcon = Icons.home_repair_service_rounded;
                            typeColor = Colors.green.shade700;
                          }

                          return Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                            child: PrimaryCard(
                              margin: EdgeInsets.zero,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Card Title & Online Status
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: typeColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: typeColor.withValues(alpha: 0.15)),
                                        ),
                                        child: Icon(typeIcon, color: typeColor, size: 22),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              f.name,
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 15,
                                                    letterSpacing: -0.2,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: typeColor.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    f.type,
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w800,
                                                      color: typeColor,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),

                                                // Working Status Badge
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: isOpen
                                                        ? Colors.green.shade900.withValues(alpha: 0.12)
                                                        : Colors.red.shade900.withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        width: 5,
                                                        height: 5,
                                                        decoration: BoxDecoration(
                                                          color: isOpen ? Colors.green : Colors.red,
                                                          shape: BoxShape.circle,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        f.workingHours == '7/24 Açık'
                                                            ? '7/24 Açık (Acil)'
                                                            : (isOpen ? 'Açık' : 'Kapalı'),
                                                        style: TextStyle(
                                                          fontSize: 9,
                                                          fontWeight: FontWeight.w800,
                                                          color: isOpen ? Colors.green.shade600 : Colors.red.shade600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Address Info with location icon
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.location_on_outlined, size: 15, color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          f.address,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12.5,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  // Working Hours Info
                                  Row(
                                    children: [
                                      Icon(Icons.watch_later_outlined, size: 15, color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6)),
                                      const SizedBox(width: 6),
                                      Text(
                                        f.workingHours ?? 'Hafta içi 08:00 - 17:00',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12.5,
                                            ),
                                      ),
                                    ],
                                  ),

                                  // Calculated Distance Badge
                                  if (distanceText != null) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.directions_car_rounded, size: 15, color: AppColors.primary),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              distanceText,
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors.primary,
                                                    fontSize: 12,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 12),

                                  // Quick Action Buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: FilledButton.icon(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          onPressed: () => LauncherUtils.callPhone(context, f.phone),
                                          icon: const Icon(Icons.phone_rounded, size: 16),
                                          label: const Text('Hemen Ara'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          onPressed: () {
                                            if (f.lat != null && f.lng != null) {
                                              LauncherUtils.openMapsWithLatLng(context, f.lat!, f.lng!);
                                            } else {
                                              LauncherUtils.openMapsWithAddress(context, f.address);
                                            }
                                          },
                                          icon: const Icon(Icons.directions_rounded, size: 16),
                                          label: const Text('Yol Tarifi'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ).animate(delay: (index * 40).ms).fadeIn().slideY(begin: 0.04, end: 0, curve: Curves.easeOutCubic);
                        },
                        childCount: facilities.length,
                      ),
                    ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Sağlık verileri yüklenemedi: $e'),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAccessRow extends StatelessWidget {
  const _QuickAccessRow({
    required this.onTapPharmacy,
    required this.onTapVeterinary,
  });

  final VoidCallback onTapPharmacy;
  final VoidCallback onTapVeterinary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => LauncherUtils.callPhone(context, '112'),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE53935), Color(0xFFC62828)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE53935).withValues(alpha: 0.22),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.emergency_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text(
                          '112 Acil Ara',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13.5,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: onTapPharmacy,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00796B), Color(0xFF00695C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00796B).withValues(alpha: 0.22),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_pharmacy_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Nöbetçi Eczane',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13.5,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: InkWell(
              onTap: onTapVeterinary,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF558B2F), Color(0xFF7CB342)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7CB342).withValues(alpha: 0.22),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pets_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Yakınımdaki Veteriner',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13.5,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchAndFilterPanel extends StatelessWidget {
  const _SearchAndFilterPanel({
    required this.searchQuery,
    required this.onSearchChanged,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.selectedMahalle,
    required this.onMahalleChanged,
    required this.isLocating,
    required this.onGpsPressed,
    required this.isUsingGps,
    required this.mahalleler,
  });

  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;
  final String selectedMahalle;
  final ValueChanged<String?> onMahalleChanged;
  final bool isLocating;
  final VoidCallback onGpsPressed;
  final bool isUsingGps;
  final List<String> mahalleler;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Search Bar
          TextField(
            onChanged: onSearchChanged,
            controller: TextEditingController(text: searchQuery)..selection = TextSelection.fromPosition(TextPosition(offset: searchQuery.length)),
            decoration: InputDecoration(
              hintText: 'Kurum adı veya adres ara...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () => onSearchChanged(''),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            ),
          ),
          const SizedBox(height: 10),

          // 2. Category Selector (Choice Chips in horizontal scroll)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: ['Hepsi', 'Hastaneler', 'Aile Sağlığı', 'Diş Sağlığı'].map((cat) {
                final isSel = selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                        color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                    selected: isSel,
                    selectedColor: AppColors.primary,
                    backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                    onSelected: (selected) {
                      if (selected) onCategoryChanged(cat);
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSel
                            ? Colors.transparent
                            : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),

          // 3. Location Sort Selector Row
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedMahalle,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down_rounded),
                      dropdownColor: Theme.of(context).scaffoldBackgroundColor,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      items: mahalleler.map((String key) {
                        return DropdownMenuItem<String>(
                          value: key,
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: key == 'Seçiniz...' ? Colors.grey : AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(key),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: onMahalleChanged,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              isLocating
                  ? const SizedBox(
                      width: 40,
                      height: 40,
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Material(
                      color: isUsingGps
                          ? AppColors.primary
                          : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: onGpsPressed,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isUsingGps
                                  ? Colors.transparent
                                  : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.gps_fixed_rounded,
                            color: isUsingGps ? Colors.white : AppColors.primary,
                            size: 16,
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
