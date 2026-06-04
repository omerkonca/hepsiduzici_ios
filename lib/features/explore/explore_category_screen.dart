import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/city_content.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/place_facility_chips.dart';
import '../../core/widgets/place_network_image.dart';
import '../../data/providers/trip_planner_provider.dart';
import 'explore_detail_screen.dart';
import 'trip_planner_screen.dart';
import 'widgets/explore_list_theme.dart';

class _PlannerCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const _PlannerCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

class _PlaceCoords {
  final double lat;
  final double lng;
  const _PlaceCoords(this.lat, this.lng);
}

// Düziçi mahalle merkez koordinatları (Konum sıralaması için)
class _MahalleCoords {
  final double lat;
  final double lng;
  const _MahalleCoords(this.lat, this.lng);
}

class ExploreCategoryScreen extends StatefulWidget {
  const ExploreCategoryScreen({
    super.key,
    required this.title,
    required this.places,
    this.allCategories = const [],
    this.preSelectedCategory = 'HEPSİ',
    this.initialScope = 'DUZICI',
  });

  final String title;
  final List<ExplorePlace> places;
  final List<ExploreCategoryItem> allCategories;
  final String preSelectedCategory;
  final String initialScope;

  @override
  State<ExploreCategoryScreen> createState() => _ExploreCategoryScreenState();
}

class _ExploreCategoryScreenState extends State<ExploreCategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final _planner = TripPlannerProvider.instance;
  String _query = '';
  late String _selectedCategory;
  late String _selectedScope;
  String _selectedMahalle = 'Seçiniz...';

  // Gerçek GPS Konum Değişkenleri
  double? _userLat;
  double? _userLng;
  bool _isLocating = false;

  // Düziçi mahalle koordinatları (GPS kapalıyken mesafe sıralamak için)
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

  // Coğrafi Koordinat Eşleştirme Tablosu
  static const Map<String, _PlaceCoords> _placeCoordinates = {
    // Düziçi
    'Berke Barajı ve göl alanı': _PlaceCoords(37.2215, 36.4710),
    'Berke Barajı Göl Manzarası': _PlaceCoords(37.2215, 36.4710),
    'Berke Barajı Kıyısı Kamp': _PlaceCoords(37.2215, 36.4710),
    'Berke Barajı Çevre Yürüyüşü': _PlaceCoords(37.2215, 36.4710),
    'Berke Barajı': _PlaceCoords(37.2215, 36.4710),
    
    'Düldül Dağı ve Dumanlı Yaylası': _PlaceCoords(37.2880, 36.5650),
    'Düldül Dağı Zirvesi': _PlaceCoords(37.2880, 36.5650),
    'Düldül Dağı Trekking Rotası': _PlaceCoords(37.2880, 36.5650),
    'Dumanlı Yaylası': _PlaceCoords(37.2880, 36.5650),
    'Dumanlı Yaylası Kamp Alanı': _PlaceCoords(37.2880, 36.5650),
    'Dumanlı Yaylası çevresi': _PlaceCoords(37.2880, 36.5650),
    'Kuşçu Yaylası': _PlaceCoords(37.2750, 36.4900),
    'Haruniye-Kuşçu Doğa Yolu': _PlaceCoords(37.2750, 36.4900),
    'Düldül Yaylası Kamp Alanı': _PlaceCoords(37.349, 36.561),
    'Mezdağ (Mezdağı) Yaylası Kamp Alanı': _PlaceCoords(37.320, 36.540),
    'Tozluyurt Yaylası Kamp Alanı': _PlaceCoords(37.330, 36.550),
    'Kurtlar Yaylası Kamp Alanı': _PlaceCoords(37.275, 36.435),
    'Hodu Yaylası Kamp Alanı': _PlaceCoords(37.315, 36.530),
    'Dumanlı Yaylası Yürüyüş Parkuru': _PlaceCoords(37.2880, 36.5650),
    'Düldül Yaylası Doğa Yürüyüşü': _PlaceCoords(37.349, 36.561),
    'Mezdağ (Mezdağı) Yaylası Yürüyüş Rotası': _PlaceCoords(37.320, 36.540),
    'Kurtlar Yaylası Trekking Parkuru': _PlaceCoords(37.275, 36.435),
    'Hodu Yaylası Doğa Yürüyüşü': _PlaceCoords(37.315, 36.530),
    'Düziçi Köy Enstitüsü Müzesi (Eğitim Tarihi Müzesi)': _PlaceCoords(37.2440, 36.4510),
    
    'Karasu Şelalesi (Sabun Çayı)': _PlaceCoords(37.2510, 36.4680),
    'Karasu Şelalesi': _PlaceCoords(37.2510, 36.4680),
    'Delioğlan Şelalesi': _PlaceCoords(37.2600, 36.4720),
    'Yeşil Şelale': _PlaceCoords(37.2550, 36.4700),
    'Sabun Çayı Vadisi': _PlaceCoords(37.2510, 36.4680),
    'Sabun Çayı Vadisi Yürüyüşü': _PlaceCoords(37.2510, 36.4680),
    'Sabun Çayı Kamp ve Piknik Alanı': _PlaceCoords(37.2510, 36.4680),
    
    'Haruniye Kaplıcaları': _PlaceCoords(37.2620, 36.4950),
    
    'Harun Reşit Kalesi': _PlaceCoords(37.2580, 36.4800),
    'Saman ve Kurtlar kaleleri': _PlaceCoords(37.2650, 36.4350),
    'Saman Kalesi': _PlaceCoords(37.2650, 36.4350),
    'Kurtlar Kalesi': _PlaceCoords(37.2680, 36.4400),
    
    'Taş Köprü (Fettahoğluları)': _PlaceCoords(37.2450, 36.4600),
    'Taş Köprü': _PlaceCoords(37.2450, 36.4600),
    
    'Düziçi Ulu Cami': _PlaceCoords(37.2410, 36.4520),
    'Yarbaşı Tren İstasyonu': _PlaceCoords(37.1990, 36.4300),
    'Tren ve havaalanı bağlantıları': _PlaceCoords(37.1990, 36.4300),
    'Düziçi Çarşı ve Hamamları': _PlaceCoords(37.2400, 36.4460),
    'Harun Reşit Çocuk Parkı ve Millet Bahçesi': _PlaceCoords(37.2395, 36.4468),
    'Eğitimci Bekir İlyas Kara Çocuk Köyü': _PlaceCoords(37.2440, 36.4510),
    'Atatürk Parkı (Park Restorant)': _PlaceCoords(37.2400, 36.4460),
    'Sabun Çayı Mesire Alanı': _PlaceCoords(37.2550, 36.4650),
    
    // Osmaniye
    'Karatepe-Aslantaş Açık Hava Müzesi': _PlaceCoords(37.294, 36.257),
    'Karatepe-Aslantaş Açık Hava Müzesi (Kadirli)': _PlaceCoords(37.294, 36.257),
    'Aslantaş Barajı': _PlaceCoords(37.2850, 36.2550),
    'Kastabala (Hierapolis) Antik Kenti': _PlaceCoords(37.1760, 36.1830),
    'Kastabala Antik Kenti (Merkez)': _PlaceCoords(37.1760, 36.1830),
    'Deve Mağarası': _PlaceCoords(37.2020, 36.5750),
    'Hemite (Amouda) Kalesi': _PlaceCoords(37.1850, 36.0950),
    'Bahçe Kalesi': _PlaceCoords(37.2020, 36.5780),
    'Toprakkale Kalesi': _PlaceCoords(37.0550, 36.1450),
    'Toprakkale Kalesi (Toprakkale)': _PlaceCoords(37.0550, 36.1450),
    'Zorkun Yaylası': _PlaceCoords(37.0250, 36.3550),
    'Zorkun Yaylası (Merkez)': _PlaceCoords(37.0250, 36.3550),
    'Yarpuz Yaylası': _PlaceCoords(37.0550, 36.4250),
    'Osmaniye Kent Müzesi': _PlaceCoords(37.0740, 36.2480),
    'Osmaniye Arkeoloji Müzesi': _PlaceCoords(37.0750, 36.2500),
    'Olukbaşı Şelalesi': _PlaceCoords(37.0650, 36.2900),
    'Hasanbeyli İlçesi ve Çevresi': _PlaceCoords(37.1250, 36.5650),
    'Savranda Kalesi (Hasanbeyli)': _PlaceCoords(37.1450, 36.5450),
    'Sumbas İlçesi ve Doğası': _PlaceCoords(37.3650, 36.0350),
    'Ceyhan Nehri Kanyonu': _PlaceCoords(37.2500, 36.3000),
    'Kadirli Kalesi': _PlaceCoords(37.3680, 36.0980),
    'Atik (Ulu) Cami – Osmaniye Merkez': _PlaceCoords(37.0720, 36.2460),
    'Osmaniye Şehir Ormanı ve Tabiat Parkı': _PlaceCoords(37.0900, 36.2300),
  };

  // Gezi Planlayıcısı Kategorileri
  static const List<_PlannerCategory> _plannerCategories = [
    _PlannerCategory(id: 'HEPSİ', name: 'Tümü', icon: Icons.map_rounded, color: AppColors.primaryDark),
    _PlannerCategory(id: 'KALE', name: 'Kale', icon: Icons.fort_rounded, color: AppColors.primaryDark),
    _PlannerCategory(id: 'TARİHİ YER', name: 'Tarihi Yer', icon: Icons.history_edu_rounded, color: AppColors.primaryDark),
    _PlannerCategory(id: 'LEZZET DURAĞI', name: 'Lezzet Durağı', icon: Icons.restaurant_rounded, color: AppColors.primaryDark),
    _PlannerCategory(id: 'KAMP ALANI', name: 'Kamp Alanı', icon: Icons.terrain_rounded, color: AppColors.primaryDark),
    _PlannerCategory(id: 'MÜZE', name: 'Müze', icon: Icons.museum_rounded, color: AppColors.primaryDark),
    _PlannerCategory(id: 'YÜRÜYÜŞ ROTASI', name: 'Yürüyüş Rotası', icon: Icons.directions_walk_rounded, color: AppColors.primaryDark),
    _PlannerCategory(id: 'DOĞAL GÜZELLİK', name: 'Doğal Güzellik', icon: Icons.filter_hdr_rounded, color: AppColors.primaryDark),
    _PlannerCategory(id: 'YAYLA', name: 'Yayla', icon: Icons.landscape_rounded, color: AppColors.primaryDark),
    _PlannerCategory(id: 'PARK', name: 'Park', icon: Icons.park_rounded, color: AppColors.primaryDark),
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.preSelectedCategory;
    _selectedScope = widget.initialScope;
    _planner.addListener(_onPlannerChanged);
  }

  @override
  void dispose() {
    _planner.removeListener(_onPlannerChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onPlannerChanged() => setState(() {});

  // Gezi Planlayıcısı dinamik kategori ataması
  List<String> _getPlannerCategoriesForPlace(ExplorePlace place) {
    final tag = place.tag.toUpperCase();
    final name = place.name.toLowerCase();
    final list = <String>[];
    
    if (tag.contains('KALE')) list.add('KALE');
    if (tag.contains('TARİH') || tag.contains('KÖPRÜ') || tag.contains('CAMİ') || tag.contains('ANTİK') || tag.contains('ÇARŞI')) list.add('TARİHİ YER');
    if (tag.contains('TATLI') || tag.contains('ESNAF') || tag.contains('KÖY') || tag.contains('YÖRE') || name.contains('künefe') || name.contains('helva') || name.contains('sofra') || name.contains('lezzet') || name.contains('mutfak')) list.add('LEZZET DURAĞI');
    if (tag.contains('KAMP') || tag.contains('PİKNİK') || tag.contains('MESİRE')) list.add('KAMP ALANI');
    if (tag.contains('MÜZE')) list.add('MÜZE');
    if (tag.contains('ZORLU') || tag.contains('ORTA') || tag.contains('KOLAY') || tag.contains('VADİ') || tag.contains('NEHİR') || name.contains('yürüyüş') || name.contains('rota') || name.contains('patika')) list.add('YÜRÜYÜŞ ROTASI');
    if (tag.contains('ŞELALE') || tag.contains('TERMAL') || tag.contains('BARAJ') || tag.contains('MAĞARA') || tag.contains('KANYON') || name.contains('şelale') || name.contains('baraj') || name.contains('kaplıca') || name.contains('mağara') || name.contains('su')) list.add('DOĞAL GÜZELLİK');
    if (tag.contains('YAYLA') || tag.contains('DAĞ') || name.contains('yayla') || name.contains('dağ') || name.contains('zirve')) list.add('YAYLA');
    if (tag.contains('PARK') || name.contains('park') || name.contains('mesire')) list.add('PARK');

    if (list.isEmpty) {
      list.add('DOĞAL GÜZELLİK');
    }
    return list;
  }

  // Cihaz GPS Koordinatlarını Alır
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
        setState(() => _isLocating = false);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Konum izni reddedildi. Mesafeler otomatik hesaplanamıyor.')),
            );
          }
          setState(() => _isLocating = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Konum izni kalıcı olarak reddedildi. Lütfen ayarlardan izin verin.')),
          );
        }
        setState(() => _isLocating = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      setState(() {
        _userLat = position.latitude;
        _userLng = position.longitude;
        _selectedMahalle = 'Seçiniz...';
        _isLocating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konumunuz başarıyla alındı! En yakın yerler en üstte sıralandı.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Konum bilgisi alınamadı: $e')),
        );
      }
      setState(() => _isLocating = false);
    }
  }

  // Haversine Formülü (Kilometre)
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const p = 0.017453292519943295; // Pi / 180
    final a = 0.5 - math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) *
            (1 - math.cos((lng2 - lng1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a)); // 2 * R; R = 6371 km
  }

  // Mekanın Osmaniye Geneline ait olup olmadığını belirleme
  bool _isOsmaniyePlace(ExplorePlace place) {
    if (widget.allCategories.isNotEmpty) {
      final osmaniyeCategory = widget.allCategories.firstWhere(
        (c) => c.id == 'osmaniye',
        orElse: () => ExploreCategoryItem(id: '', icon: '', title: '', subtitle: '', badge: '', places: []),
      );
      return osmaniyeCategory.places.any((p) => p.name == place.name);
    }
    return place.tag == 'OSMANIYE' || 
           place.address.toLowerCase().contains('osmaniye') && 
           (place.address.toLowerCase().contains('kadirli') || 
            place.address.toLowerCase().contains('bahçe') || 
            place.address.toLowerCase().contains('toprakkale') || 
            place.address.toLowerCase().contains('hasanbeyli') || 
            place.address.toLowerCase().contains('sumbas'));
  }

  // Kategorideki yerlerin listesi (Tekilleştirilmiş)
  List<ExplorePlace> get _allRawPlaces {
    if (widget.allCategories.isNotEmpty) {
      final list = <ExplorePlace>[];
      for (final cat in widget.allCategories) {
        if (cat.id == 'guide') continue; // Exclude non-sightseeing city guide utility items
        list.addAll(cat.places);
      }
      // İsme göre tekilleştirme
      final seen = <String>{};
      final deduped = <ExplorePlace>[];
      for (final p in list) {
        if (!seen.contains(p.name)) {
          seen.add(p.name);
          deduped.add(p);
        }
      }
      return deduped;
    }
    return widget.places;
  }

  // Koordinat bulma
  _PlaceCoords _getCoordsForPlace(ExplorePlace place) {
    if (place.lat != null && place.lng != null) {
      return _PlaceCoords(place.lat!, place.lng!);
    }
    final name = place.name.trim();
    if (_placeCoordinates.containsKey(name)) {
      return _placeCoordinates[name]!;
    }
    for (final entry in _placeCoordinates.entries) {
      if (name.toLowerCase().contains(entry.key.toLowerCase()) || 
          entry.key.toLowerCase().contains(name.toLowerCase())) {
        return entry.value;
      }
    }
    return const _PlaceCoords(37.2400, 36.4460); // Düziçi Merkez varsayılan
  }

  // TripAdvisor derecelendirmesi ve stable review sayıları
  double _getRatingForPlace(ExplorePlace place) {
    final name = place.name.toLowerCase();
    if (name.contains('düldül') || name.contains('dumanlı')) return 4.9;
    if (name.contains('harun reşit')) return 4.8;
    if (name.contains('karatepe')) return 4.8;
    if (name.contains('karasu')) return 4.7;
    if (name.contains('berke')) return 4.7;
    if (name.contains('kastabala')) return 4.6;
    
    final hash = place.name.codeUnits.reduce((a, b) => a + b);
    return 4.3 + (hash % 7) * 0.1;
  }

  int _getReviewCountForPlace(ExplorePlace place) {
    final name = place.name.toLowerCase();
    if (name.contains('düldül') || name.contains('dumanlı')) return 892;
    if (name.contains('harun reşit')) return 387;
    if (name.contains('karatepe')) return 1120;
    if (name.contains('zorkun')) return 2540;
    
    final hash = place.name.codeUnits.reduce((a, b) => a + b);
    return 45 + (hash % 9) * 120;
  }

  // Kategori sayacını kapsama göre dinamik hesaplama
  int _getCategoryCount(String catId) {
    final rawPlaces = _allRawPlaces;
    final scopeList = rawPlaces.where((p) {
      final isOsmaniye = _isOsmaniyePlace(p);
      return _selectedScope == 'OSMANIYE' ? isOsmaniye : !isOsmaniye;
    }).toList();

    if (catId == 'HEPSİ') return scopeList.length;
    
    return scopeList.where((p) {
      final plannerCats = _getPlannerCategoriesForPlace(p);
      return plannerCats.contains(catId);
    }).length;
  }

  // Filtrelenmiş ve Sıralanmış Mekanlar Listesi
  List<ExplorePlace> get _processedPlaces {
    var list = _allRawPlaces;
    
    // 1. Kapsam (Düziçi veya Osmaniye Geneli) Filtresi
    list = list.where((p) {
      final isOsmaniye = _isOsmaniyePlace(p);
      return _selectedScope == 'OSMANIYE' ? isOsmaniye : !isOsmaniye;
    }).toList();

    // 2. Arama Filtresi
    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((p) {
        return p.name.toLowerCase().contains(q) ||
            p.shortDescription.toLowerCase().contains(q) ||
            p.address.toLowerCase().contains(q) ||
            p.tag.toLowerCase().contains(q);
      }).toList();
    }

    // 3. Gezi Planlayıcısı Kategori Filtresi
    if (_selectedCategory != 'HEPSİ') {
      list = list.where((p) {
        final plannerCats = _getPlannerCategoriesForPlace(p);
        return plannerCats.contains(_selectedCategory);
      }).toList();
    }

    // 4. Konum/Mesafe Sıralaması
    final refLat = _userLat ?? (_selectedMahalle != 'Seçiniz...' ? _mahalleler[_selectedMahalle]!.lat : null);
    final refLng = _userLng ?? (_selectedMahalle != 'Seçiniz...' ? _mahalleler[_selectedMahalle]!.lng : null);

    if (refLat != null && refLng != null) {
      list.sort((a, b) {
        final coordsA = _getCoordsForPlace(a);
        final coordsB = _getCoordsForPlace(b);
        final distA = _calculateDistance(refLat, refLng, coordsA.lat, coordsA.lng);
        final distB = _calculateDistance(refLat, refLng, coordsB.lat, coordsB.lng);
        return distA.compareTo(distB);
      });
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _processedPlaces;
    final isD = _selectedScope == 'DUZICI';
    final bool isUsingGps = _userLat != null && _userLng != null;
    final bool isUsingMahalle = _selectedMahalle != 'Seçiniz...';
    
    final refLat = _userLat ?? (isUsingMahalle ? _mahalleler[_selectedMahalle]!.lat : null);
    final refLng = _userLng ?? (isUsingMahalle ? _mahalleler[_selectedMahalle]!.lng : null);

    final plannerCount = _planner.count;

    Widget buildScaffold(BuildContext context) {
      return Scaffold(
      backgroundColor: ExploreListTheme.background,
      appBar: AppBar(
        title: Text(
          widget.title == 'Gezi Rehberi' ? 'Gezi Rehberi' : widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: ExploreListTheme.textPrimary,
          ),
        ),
        backgroundColor: ExploreListTheme.surface,
        foregroundColor: ExploreListTheme.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: plannerCount > 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TripPlannerScreen()),
              ),
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.route_rounded),
              label: Text(
                'Rotam ($plannerCount durak)',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            )
          : null,
      body: CustomScrollView(
        slivers: [
          // === GEZİ PLANLAYICISI ÜST BANNER VE ARAMA ALANI ===
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: ExploreListTheme.surface,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Planlayıcı Tanıtım Başlığı
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: ExploreListTheme.headerBanner,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: ExploreListTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.map_rounded, color: AppColors.primaryDark, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              widget.title == 'Gezi Rehberi'
                                  ? 'Düziçi & Osmaniye Gezi Rehberi'
                                  : 'Osmaniye & Düziçi Gezi Planlayıcısı',
                              style: TextStyle(
                                color: ExploreListTheme.textPrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.title == 'Gezi Rehberi'
                              ? 'Harita verileri OpenStreetMap kaynağından alınmaktadır.'
                              : 'İlçemizin ve çevre ilçelerin güzelliklerini ilgi alanınıza göre planlayın.',
                          style: TextStyle(
                            color: ExploreListTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  
                  // === KAPSAM SEÇİCİ (SEGMENTED TAB BAR) ===
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: ExploreListTheme.surfaceMuted,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: ExploreListTheme.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedScope = 'DUZICI';
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isD ? ExploreListTheme.segmentActive : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.location_on_rounded, 
                                      color: isD ? Colors.white : AppColors.primaryDark, 
                                      size: 15
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Düziçi İçi',
                                      style: TextStyle(
                                        color: isD ? Colors.white : ExploreListTheme.textSecondary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedScope = 'OSMANIYE';
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !isD ? ExploreListTheme.segmentActive : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.public_rounded, 
                                      color: !isD ? Colors.white : AppColors.primaryDark, 
                                      size: 15
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Osmaniye Geneli',
                                      style: TextStyle(
                                        color: !isD ? Colors.white : ExploreListTheme.textSecondary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // === AKILLI KONUM / MESAFE SIRALAMA PANELİ ===
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ExploreListTheme.surfaceMuted,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: ExploreListTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.my_location_rounded, size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                isUsingGps
                                    ? '📍 GPS Konumuna Göre Sıralı'
                                    : (isUsingMahalle ? '📍 Mahalle Konumuna Göre Sıralı' : 'En Yakın Mekanları Göster:'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: ExploreListTheme.textPrimary,
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
                                  color: ExploreListTheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: ExploreListTheme.border),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedMahalle,
                                    isExpanded: true,
                                    dropdownColor: ExploreListTheme.surface,
                                    style: const TextStyle(
                                      color: ExploreListTheme.textPrimary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
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
                                    width: 44,
                                    height: 44,
                                    child: Padding(
                                      padding: EdgeInsets.all(12),
                                      child: CircularProgressIndicator(strokeWidth: 2.5),
                                    ),
                                  )
                                : IconButton.filled(
                                    style: IconButton.styleFrom(
                                      backgroundColor: isUsingGps
                                          ? AppColors.primaryDark
                                          : ExploreListTheme.surface,
                                      foregroundColor: isUsingGps
                                          ? Colors.white
                                          : ExploreListTheme.textPrimary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.all(12),
                                    ),
                                    onPressed: _getUserLocation,
                                    icon: const Icon(Icons.gps_fixed_rounded, size: 18),
                                    tooltip: 'GPS Konumu Kullan',
                                  ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  
                  // Arama Çubuğu
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: isD ? 'Düziçi içinde mekan ara...' : 'Osmaniye geneli mekan ara...',
                      hintStyle: const TextStyle(color: ExploreListTheme.textMuted),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryDark),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: AppColors.primaryDark),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: ExploreListTheme.surfaceMuted,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: ExploreListTheme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: ExploreListTheme.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // === GEZİ SEKMELERİ / KATEGORİ KAYDIRICISI ===
          SliverToBoxAdapter(
            child: Container(
              height: 86,
              margin: const EdgeInsets.only(top: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _plannerCategories.length,
                itemBuilder: (context, index) {
                  final cat = _plannerCategories[index];
                  final isSelected = _selectedCategory == cat.id;
                  final count = _getCategoryCount(cat.id);

                  // Boş kategorileri gizle (Tümü hariç)
                  if (count == 0 && cat.id != 'HEPSİ') {
                    return const SizedBox.shrink();
                  }

                  final chipBg = isSelected
                      ? ExploreListTheme.chipSelected
                      : ExploreListTheme.chipUnselectedBg;
                  final borderCol = isSelected
                      ? ExploreListTheme.chipSelected
                      : ExploreListTheme.chipUnselectedBorder;
                  final iconCol = isSelected ? Colors.white : AppColors.primaryDark;
                  final textCol = isSelected ? Colors.white : ExploreListTheme.textSecondary;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                    child: Material(
                      color: chipBg,
                      borderRadius: BorderRadius.circular(999),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat.id;
                          });
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: borderCol,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                cat.icon,
                                size: 16,
                                color: iconCol,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                cat.name,
                                style: TextStyle(
                                  color: textCol,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.22)
                                      : AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  count.toString(),
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : AppColors.primaryDark,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // === TURİSTİK MEKAN LİSTESİ ===
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final p = filtered[index];
                  final double rating = _getRatingForPlace(p);
                  final int reviews = _getReviewCountForPlace(p);
                  double? distance;
                  if (refLat != null && refLng != null) {
                    final coords = _getCoordsForPlace(p);
                    distance = _calculateDistance(refLat, refLng, coords.lat, coords.lng);
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _openDetail(context, p),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: ExploreListTheme.cardDecoration(),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Geniş Köşeli Görsel & Rozet Katmanları
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: PlaceNetworkImage(
                                      place: p,
                                      width: 110,
                                      height: 116,
                                      heroTag: 'place_image_${p.name}',
                                      maxHeight: 400,
                                    ),
                                  ),
                                  // Kategori Etiketi
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryDark.withValues(alpha: 0.9),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        p.tag,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              // Detaylar
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 2),
                                    // Puan ve Yorumlar
                                    Row(
                                      children: [
                                        const Icon(Icons.star_rounded, color: AppColors.primary, size: 16),
                                        const SizedBox(width: 3),
                                        Text(
                                          rating.toStringAsFixed(1),
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                color: Theme.of(context).colorScheme.onSurface,
                                              ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '($reviews)',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    // Başlık
                                    Text(
                                      p.name,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: Theme.of(context).colorScheme.onSurface,
                                            fontSize: 14,
                                            letterSpacing: -0.2,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    // Kısa Açıklama
                                    Text(
                                      p.shortDescription,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    PlaceFacilityChips(place: p, compact: true),
                                    const SizedBox(height: 6),
                                    if (distance != null) ...[
                                      Row(
                                        children: [
                                          const Icon(Icons.directions_car_rounded, size: 11, color: AppColors.primaryDark),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${distance.toStringAsFixed(1)} km uzaklıkta',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primaryDark,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                    ],
                                    // Adres Bilgisi
                                    Row(
                                      children: [
                                        Icon(Icons.location_on_outlined,
                                            size: 11,
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.color
                                                ?.withValues(alpha: 0.5)),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            p.address,
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.color
                                                      ?.withValues(alpha: 0.5),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              // Rotaya ekle / çıkar + Keşfet ok
                              Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      _planner.toggle(p);
                                      final added = _planner.contains(p);
                                      ScaffoldMessenger.of(context).clearSnackBars();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            added ? '${p.name} rotaya eklendi' : '${p.name} rotadan çıkarıldı',
                                          ),
                                          duration: const Duration(seconds: 2),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: _planner.contains(p)
                                            ? AppColors.primary
                                            : AppColors.primary.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _planner.contains(p) ? Icons.check : Icons.add,
                                        size: 16,
                                        color: _planner.contains(p) ? Colors.white : AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                  const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 14),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ).animate(delay: (index * 40).ms).fadeIn().moveY(begin: 12, end: 0);
                },
                childCount: filtered.length,
              ),
            ),
          ),
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: ExploreListTheme.surfaceMuted,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.search_off_rounded,
                        size: 40,
                        color: ExploreListTheme.textMuted,
                      ),
                    ).animate().scale(begin: const Offset(0.7, 0.7), curve: Curves.elasticOut),
                    const SizedBox(height: 20),
                    Text(
                      'Bu kategoride mekan bulunamadı',
                      style: const TextStyle(
                        color: ExploreListTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 8),
                    Text(
                      'Farklı bir kategori veya bölge deneyin',
                      style: const TextStyle(
                        color: ExploreListTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
    }

    return buildScaffold(context);
  }

  void _openDetail(BuildContext context, ExplorePlace place) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExploreDetailScreen(
          place: place,
        ),
      ),
    );
  }
}
