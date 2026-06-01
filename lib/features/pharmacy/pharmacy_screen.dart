import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/launcher_utils.dart';
import '../../core/widgets/primary_card.dart';
import '../../core/widgets/service_page_layout.dart';
import '../../core/widgets/favorite_button.dart';
import '../../data/models/pharmacy.dart';
import '../../data/services/favorites_service.dart';

class _MahalleCoords {
  final double lat;
  final double lng;
  const _MahalleCoords(this.lat, this.lng);
}

class PharmacyScreen extends ConsumerStatefulWidget {
  const PharmacyScreen({super.key});

  @override
  ConsumerState<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends ConsumerState<PharmacyScreen> {
  String _searchQuery = '';
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
              const SnackBar(content: Text('Konum izni reddedildi. En yakın eczaneler otomatik sıralanamıyor.')),
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
        _selectedMahalle = 'Seçiniz...'; // Manuel seçimi sıfırla
        _isLocating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konumunuz başarıyla alındı! En yakın nöbetçi eczaneler üstte sıralandı.')),
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

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(pharmacyListProvider);
    final bool isUsingGps = _userLat != null && _userLng != null;

    return async.when(
      data: (List<Pharmacy> list) {
        // 1. Arama Filtreleme
        var pharmacies = list.where((p) {
          final query = _searchQuery.toLowerCase();
          return p.name.toLowerCase().contains(query) ||
              p.address.toLowerCase().contains(query);
        }).toList();

        // 2. Konum veya Mahalle Seçildiyse Koordinat Bazlı Mesafe Hesaplama ve Sıralama
        Map<String, double> calculatedDistances = {};
        final bool isUsingMahalle = _selectedMahalle != 'Seçiniz...';

        if (isUsingGps || isUsingMahalle) {
          final double refLat = isUsingGps ? _userLat! : _mahalleler[_selectedMahalle]!.lat;
          final double refLng = isUsingGps ? _userLng! : _mahalleler[_selectedMahalle]!.lng;

          for (final p in pharmacies) {
            if (p.lat != null && p.lng != null) {
              final dist = _calculateDistance(refLat, refLng, p.lat!, p.lng!);
              calculatedDistances[p.name] = dist;
            }
          }
          // En yakından uzağa doğru sırala
          pharmacies.sort((a, b) {
            final distA = calculatedDistances[a.name] ?? 999.0;
            final distB = calculatedDistances[b.name] ?? 999.0;
            return distA.compareTo(distB);
          });
        }

        return ServicePageLayout(
          title: 'Nöbetçi Eczane',
          subtitle: 'Bugün Düziçi genelinde hizmet veren onaylı nöbetçi eczanelerin canlı listesi.',
          icon: 'local_pharmacy',
          color: const Color(0xFF009688),
          onRefresh: () async => ref.invalidate(pharmacyListProvider),
          isEmpty: false, // Hata durumunu özel şık kartla SliverList içinde kendimiz yöneteceğiz
          child: SliverMainAxisGroup(
            slivers: [
              // --- ELEKTRONİK NOBET PANELİ ---
              SliverToBoxAdapter(
                child: Card(
                  color: Colors.teal.shade900.withValues(alpha: 0.95),
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
                            Icons.local_pharmacy_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NÖBET SÜRESİ VE DÜZENİ',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Nöbetler bugün saat 08:00\'de başlar, yarın sabah saat 08:00\'e kadar kesintisiz 24 saat sürer.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      height: 1.3,
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
                          const Icon(Icons.my_location_rounded, size: 20, color: Colors.teal),
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
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                                    ),
                                  ),
                                )
                              : IconButton.filled(
                                  style: IconButton.styleFrom(
                                    backgroundColor: isUsingGps
                                        ? Colors.teal
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
                          hintText: 'Eczane adı veya sokak ara...',
                          prefixIcon: const Icon(Icons.search_rounded, color: Colors.teal),
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
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.teal, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- BOŞ VEYA ÇEVRİMDIŞI DURUMDA ONUR/GÜVENLİK YÖNLENDİRMESİ ---
              if (list.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Card(
                      elevation: 0,
                      color: Colors.orange.shade900.withValues(alpha: 0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.wifi_off_rounded,
                                color: Colors.orange,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Canlı Nöbetçi Eczane Verisi Alınamadı',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.orange.shade400,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Eczaneler canlı veritabanı bağlantısı kurulamadığı için gösterilemiyor. Sağlığınız bizim için en hassas konu olduğundan, sizi yanıltabilecek tahmini veya eski bilgileri listelemiyoruz.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    height: 1.45,
                                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.85),
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 12),
                            Text(
                              'Resmi ve Onaylı Nöbetçileri Doğrudan Görün:',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.teal.shade700,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 44),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => LauncherUtils.openUrlExternal(
                                context,
                                'https://www.eczaneler.gen.tr/nobetci-osmaniye-duzici',
                              ),
                              icon: const Icon(Icons.open_in_browser_rounded),
                              label: const Text('Resmi Nöbetçi Eczane Sayfasını Aç'),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 44),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => LauncherUtils.openUrlExternal(
                                context,
                                'https://www.osmaniyeeyo.org.tr/',
                              ),
                              icon: const Icon(Icons.health_and_safety_rounded),
                              label: const Text('Osmaniye Eczacı Odası\'nı Aç'),
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 12),
                            Text(
                              'Onaylı bilgi almak için arayabileceğiniz birimler:',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                    onPressed: () => LauncherUtils.callPhone(context, '03288761010'),
                                    icon: const Icon(Icons.local_hospital_rounded, size: 16),
                                    label: const Text('Devlet Hast.'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                    onPressed: () => LauncherUtils.callPhone(context, '03288760001'),
                                    icon: const Icon(Icons.phone_rounded, size: 16),
                                    label: const Text('Belediye B.Masa'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // --- ECZANELER LİSTESİ ---
              if (list.isNotEmpty && pharmacies.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade600),
                          const SizedBox(height: 12),
                          Text(
                            'Kriterlere uygun nöbetçi eczane bulunamadı.',
                            style: TextStyle(color: Colors.grey.shade600),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              if (pharmacies.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final p = pharmacies[index];
                      final distance = calculatedDistances[p.name];

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

                      return PrimaryCard(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Eczane İkonu, Adı ve Canlı Nöbet Rozeti
                            Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF009688).withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.local_pharmacy_rounded,
                                    color: Color(0xFF00897B),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.name,
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
                                              color: Colors.green.shade900.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 6,
                                                  height: 6,
                                                  decoration: const BoxDecoration(
                                                    color: Colors.green,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                const Text(
                                                  'BUGÜN NÖBETÇİ (7/24)',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green,
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
                                FavoriteButton(
                                  id: p.name,
                                  category: FavoriteCategory.pharmacy,
                                  size: 22,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Adres Kartı
                            if (p.address.isNotEmpty) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on_rounded, size: 16, color: AppColors.textMuted),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      p.address,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppColors.textMuted,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            // Dinamik Mesafe Hesaplandıysa Gösterim
                            if (distanceText != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF009688).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.directions_car_rounded, size: 16, color: Color(0xFF009688)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        distanceText,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF00897B),
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 14),

                            // İşlem Butonları (Arama ve Harita)
                            if (p.phone.isNotEmpty) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(0xFF009688),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed: () => LauncherUtils.callPhone(context, p.phone),
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
                                        side: const BorderSide(color: Color(0xFF009688)),
                                        foregroundColor: const Color(0xFF00897B),
                                      ),
                                      onPressed: () {
                                        if (p.lat != null && p.lng != null) {
                                          LauncherUtils.openMapsWithLatLng(context, p.lat!, p.lng!);
                                        } else {
                                          LauncherUtils.openMapsWithAddress(context, p.address);
                                        }
                                      },
                                      icon: const Icon(Icons.directions_rounded, size: 18),
                                      label: const Text('Yol Tarifi'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ).animate(delay: (index * 60).ms).fadeIn().slideY(begin: 0.08, end: 0);
                    },
                    childCount: pharmacies.length,
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
              Text('Nöbetçi eczaneler yüklenemedi: $e'),
            ],
          ),
        ),
      ),
    );
  }
}
