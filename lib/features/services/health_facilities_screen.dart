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

  // Gerçek GPS Konum Değişkenleri
  double? _userLat;
  double? _userLng;
  bool _isLocating = false;

  // Düziçi mahalle merkez koordinatları (Kuş uçuşu mesafe hesaplama için)
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

  // GPS Üzerinden Konum Alma Fonksiyonu
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
        _selectedMahalle = 'Seçiniz...'; // Manuel mahalle seçimini sıfırla
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

  // Haversine Formülü ile iki koordinat arası km hesaplama
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const p = 0.017453292519943295; // Pi / 180
    final a = 0.5 - math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) *
            (1 - math.cos((lng2 - lng1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a)); // 2 * R; R = 6371 km
  }

  // Canlı Açık/Kapalı Durum Hesaplama
  bool _isFacilityOpen(HealthFacilityItem f) {
    if (f.workingHours == '7/24 Açık') return true;

    final now = DateTime.now();
    // Hafta sonu kapalı (Cumartesi = 6, Pazar = 7)
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
        // 1. Arama ve Kategoriye Göre Filtreleme
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

        // 2. Konum veya Mahalle Seçildiyse Koordinat Bazlı Mesafe Hesaplama ve Sıralama
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
          // En yakından uzağa doğru sırala
          facilities.sort((a, b) {
            final distA = calculatedDistances[a.name] ?? 999.0;
            final distB = calculatedDistances[b.name] ?? 999.0;
            return distA.compareTo(distB);
          });
        } else {
          // Varsayılan sıralama: Önce acil servisi olanlar (hastaneler)
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
          subtitle: 'İlçemizdeki temel sağlık noktaları, çalışma saatleri, konum sıralaması ve tek tıkla arama.',
          icon: 'local_hospital',
          color: const Color(0xFF1E88E5),
          onRefresh: () async => ref.invalidate(cityContentProvider),
          isEmpty: facilities.isEmpty && _searchQuery.isEmpty,
          child: SliverMainAxisGroup(
            slivers: [
              // --- 112 ACİL BANNER ---
              SliverToBoxAdapter(
                child: Card(
                  color: Colors.red.shade900.withValues(alpha: 0.95),
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.emergency_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                         .scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15), duration: 1000.ms),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'HAYATİ ACİL DURUM (112)',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Ciddi hayati tehlike durumlarında hiç vakit kaybetmeden 112\'yi arayın.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      height: 1.3,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.red.shade900,
                          ),
                          onPressed: () => LauncherUtils.callPhone(context, '112'),
                          icon: const Icon(Icons.phone_in_talk_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // --- FİLTRE VE KONUM SEÇİCİ PANEL ---
              SliverToBoxAdapter(
                child: PrimaryCard(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mahalle Seçimi ve GPS Konum Butonu
                      Row(
                        children: [
                          const Icon(Icons.my_location_rounded, size: 20, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isUsingGps
                                  ? 'Otomatik Konum Sıralaması Etkin'
                                  : 'En Yakını Bul (Mahalle Seçin):',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey.shade900
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedMahalle,
                                  isExpanded: true,
                                  dropdownColor: Theme.of(context).scaffoldBackgroundColor,
                                  items: _mahalleler.keys.map((String key) {
                                    return DropdownMenuItem<String>(
                                      value: key,
                                      child: Text(key),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedMahalle = val ?? 'Seçiniz...';
                                      _userLat = null; // Manuel seçilirse GPS sıfırlansın
                                      _userLng = null;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _isLocating
                              ? const SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(strokeWidth: 2.5),
                                  ),
                                )
                              : IconButton.filled(
                                  style: IconButton.styleFrom(
                                    backgroundColor: isUsingGps
                                        ? AppColors.primary
                                        : (Theme.of(context).brightness == Brightness.dark
                                            ? Colors.grey.shade800
                                            : Colors.grey.shade200),
                                    foregroundColor: isUsingGps
                                        ? Colors.white
                                        : (Theme.of(context).brightness == Brightness.dark
                                            ? Colors.white
                                            : Colors.grey.shade800),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.all(12),
                                  ),
                                  onPressed: _getUserLocation,
                                  icon: const Icon(Icons.gps_fixed_rounded),
                                  tooltip: 'Anlık Konumumu Kullan',
                                ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Arama Çubuğu
                      TextField(
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Kurum adı veya adres ara...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Kategori Çipleri
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['Hepsi', 'Hastaneler', 'Aile Sağlığı', 'Diş Sağlığı'].map((cat) {
                            final isSel = _selectedCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(cat),
                                selected: isSel,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedCategory = cat;
                                    });
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- NÖBETÇİ ECZANE YÖNLENDİRME BANNERI ---
              SliverToBoxAdapter(
                child: Card(
                  color: Colors.teal.shade800.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: Colors.teal.withValues(alpha: 0.3),
                    ),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: InkWell(
                    onTap: () => TargetRouter.handle(context, 'screen:pharmacy'),
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.teal.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.local_pharmacy_rounded,
                              color: Colors.teal,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  Text(
                                    'Nöbetçi Eczaneleri Gör',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.teal.shade400,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Bugün açık olan nöbetçi eczaneleri görmek için tıklayın.',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.teal.shade300,
                                        ),
                                  ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.teal,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // --- SAĞLIK KURUMLARI LİSTESİ ---
              facilities.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade600),
                              const SizedBox(height: 12),
                              Text(
                                'Kriterlere uygun sağlık kuruluşu bulunamadı.',
                                style: TextStyle(color: Colors.grey.shade600),
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

                          // Mesafe ve tahmini süre metni
                          String? distanceText;
                          if (distance != null) {
                            final min = ((distance / 45) * 60).round() + 1; // 45 km/h ortalama hız
                            if (isUsingGps) {
                              distanceText = 'Size ${distance.toStringAsFixed(1)} km uzaklıkta (yaklaşık $min dk sürüş)';
                            } else {
                              distanceText = '$_selectedMahalle merkezine ${distance.toStringAsFixed(1)} km (yaklaşık $min dk sürüş)';
                            }
                          }

                          // Tipe göre ikon seçimi
                          IconData typeIcon = Icons.local_hospital_rounded;
                          Color typeColor = AppColors.primary;
                          if (f.type.contains('Diş')) {
                            typeIcon = Icons.medical_services_rounded;
                            typeColor = Colors.cyan;
                          } else if (f.type.contains('ASM') || f.type.contains('Aile Sağlığı')) {
                            typeIcon = Icons.home_repair_service_rounded;
                            typeColor = Colors.green;
                          }

                          return PrimaryCard(
                            margin: const EdgeInsets.only(bottom: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Kart Başlığı ve Canlı Durum
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(11),
                                      decoration: BoxDecoration(
                                        color: typeColor.withValues(alpha: 0.16),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        typeIcon,
                                        color: typeColor,
                                      ),
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
                                                  letterSpacing: -0.3,
                                                ),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: typeColor.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  f.type,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: typeColor,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),

                                              // Çalışma Durumu Rozeti
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isOpen
                                                      ? Colors.green.shade900.withValues(alpha: 0.15)
                                                      : Colors.red.shade900.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      width: 6,
                                                      height: 6,
                                                      decoration: BoxDecoration(
                                                        color: isOpen ? Colors.green : Colors.red,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      f.workingHours == '7/24 Açık'
                                                          ? '7/24 Açık (Acil)'
                                                          : (isOpen ? 'Şu An Açık' : 'Şu An Kapalı'),
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: isOpen ? Colors.green.shade400 : Colors.red.shade400,
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

                                // Adres Bilgisi
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.location_on_rounded, size: 16, color: AppColors.textMuted),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        f.address,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: AppColors.textMuted,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),

                                // Çalışma Saatleri Bilgisi
                                Row(
                                  children: [
                                    const Icon(Icons.watch_later_rounded, size: 16, color: AppColors.textMuted),
                                    const SizedBox(width: 6),
                                    Text(
                                      f.workingHours ?? 'Hafta içi 08:00 - 17:00',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppColors.textMuted,
                                          ),
                                    ),
                                  ],
                                ),

                                // Dinamik Mesafe Hesaplandıysa Gösterim
                                if (distanceText != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.directions_car_rounded, size: 16, color: AppColors.primary),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            distanceText,
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primary,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 14),

                                // Butonlar
                                Row(
                                  children: [
                                    Expanded(
                                      child: FilledButton.icon(
                                        style: FilledButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        onPressed: () => LauncherUtils.callPhone(context, f.phone),
                                        icon: const Icon(Icons.phone_rounded, size: 18),
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
                                        icon: const Icon(Icons.directions_rounded, size: 18),
                                        label: const Text('Yol Tarifi'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ).animate(delay: (index * 60).ms).fadeIn().slideY(begin: 0.08, end: 0);
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
