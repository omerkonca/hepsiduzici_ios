import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/primary_card.dart';
import '../../core/widgets/service_page_layout.dart';
import '../../data/models/city_content.dart';

class AutoVehicle {
  const AutoVehicle({
    required this.id,
    required this.galleryName,
    required this.brand,
    required this.model,
    required this.year,
    required this.price,
    required this.km,
    required this.gearType, // 'Manuel' | 'Otomatik'
    required this.fuelType, // 'Benzin' | 'Dizel' | 'Benzin/LPG'
    required this.colorName,
    required this.imageUrl,
    required this.description,
  });

  final String id;
  final String galleryName;
  final String brand;
  final String model;
  final int year;
  final double price;
  final int km;
  final String gearType;
  final String fuelType;
  final String colorName;
  final String imageUrl;
  final String description;

  String get formattedPrice {
    final str = price.toStringAsFixed(0);
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count == 3 && i != 0) {
        buffer.write('.');
        count = 0;
      }
    }
    return '${buffer.toString().split('').reversed.join()} ₺';
  }

  String get formattedKm {
    final str = km.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count == 3 && i != 0) {
        buffer.write('.');
        count = 0;
      }
    }
    return '${buffer.toString().split('').reversed.join()} Km';
  }
}

// Düziçi Oto Galerileri Gerçekçi Araç Veri Seti
const _mockVehicles = <AutoVehicle>[
  AutoVehicle(
    id: 'car_1',
    galleryName: 'Coşkun Oto Galeri',
    brand: 'Fiat',
    model: 'Egea 1.3 M.Jet Easy',
    year: 2021,
    price: 695000,
    km: 92000,
    gearType: 'Manuel',
    fuelType: 'Dizel',
    colorName: 'Beyaz',
    imageUrl: 'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?w=600&auto=format&fit=crop&q=60',
    description: 'İlk sahibinden, yetkili servis bakımlı. Değişensiz, sadece sağ arka çamurlukta lokal boya mevcuttur. Lastikleri %85 durumdadır. İç döşemelerinde yanık yırtık yoktur. Düziçi içi takasa uygundur.',
  ),
  AutoVehicle(
    id: 'car_2',
    galleryName: 'Coşkun Oto Galeri',
    brand: 'Renault',
    model: 'Megane 1.5 dCi Touch',
    year: 2018,
    price: 820000,
    km: 145000,
    gearType: 'Otomatik',
    fuelType: 'Dizel',
    colorName: 'Platin Gri',
    imageUrl: 'https://images.unsplash.com/photo-1541899481282-d53bffe3c35d?w=600&auto=format&fit=crop&q=60',
    description: 'EDC şanzıman kusursuz geçişler. Tüm sıvı bakımları yeni yapılmıştır. Triger seti 120 binde değişmiştir. Ekspertiz raporu mevcuttur, kaput ve sol ön kapı boyalıdır, şaseler orijinaldir.',
  ),
  AutoVehicle(
    id: 'car_3',
    galleryName: 'Güzeller Oto Galeri',
    brand: 'Toyota',
    model: 'Corolla 1.5 Vision Multidrive S',
    year: 2022,
    price: 915000,
    km: 38000,
    gearType: 'Otomatik',
    fuelType: 'Benzin',
    colorName: 'Kar Beyazı',
    imageUrl: 'https://images.unsplash.com/photo-1605559424843-9e4c228bf1c2?w=600&auto=format&fit=crop&q=60',
    description: 'Hatasız, boyasız, tramer kayıtsız. Garantisi devam etmektedir. Yedek anahtarı ve kitapçıkları mevcuttur. Ekstra olarak çelik jant ve park sensörü takılmıştır. Sıfır ayarında aile aracı.',
  ),
  AutoVehicle(
    id: 'car_4',
    galleryName: 'Güzeller Oto Galeri',
    brand: 'Honda',
    model: 'Civic 1.6 i-VTEC Eco Executive',
    year: 2019,
    price: 1040000,
    km: 78000,
    gearType: 'Otomatik',
    fuelType: 'Benzin/LPG',
    colorName: 'Kristal Siyah',
    imageUrl: 'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?w=600&auto=format&fit=crop&q=60',
    description: 'Fabrikasyon LPG\'li, en dolu Executive paket. Hayalet ekran, koltuk ısıtma, geri görüş kamerası, sunroof mevcuttur. Sağ iki kapı çizik boyalıdır. Tramer sadece 2.500 ₺.',
  ),
  AutoVehicle(
    id: 'car_5',
    galleryName: 'Osmanlı Otomotiv',
    brand: 'Volkswagen',
    model: 'Passat 1.6 TDI Comfortline DSG',
    year: 2017,
    price: 1280000,
    km: 160000,
    gearType: 'Otomatik',
    fuelType: 'Dizel',
    colorName: 'Saf Beyaz',
    imageUrl: 'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?w=600&auto=format&fit=crop&q=60',
    description: 'Comfortline paket, DSG şanzıman kavraması yeni değişti. Ağır bakımları yeni yapılmıştır. Sadece sol çamurluk değişmiştir. Tramer kaydı yoktur. Alıcısına şimdiden hayırlı olsun.',
  ),
  AutoVehicle(
    id: 'car_6',
    galleryName: 'Osmanlı Otomotiv',
    brand: 'Ford',
    model: 'Focus 1.5 TDCi Trend X',
    year: 2018,
    price: 740000,
    km: 122000,
    gearType: 'Manuel',
    fuelType: 'Dizel',
    colorName: 'Derin Mavi',
    imageUrl: 'https://images.unsplash.com/photo-1511919884226-fd3cad34687c?w=600&auto=format&fit=crop&q=60',
    description: 'Hız sabitleyici, çelik jant, bluetooth. Yakıt cimrisi tam bir yol arkadaşı. Değişensiz, bagaj kapağında mikron boya vardır. Harici hatasızdır. Muayenesi yeni yapılmıştır.',
  ),
  AutoVehicle(
    id: 'car_7',
    galleryName: 'Koylu Auto',
    brand: 'Hyundai',
    model: 'i20 1.4 MPI Elite',
    year: 2020,
    price: 765000,
    km: 55000,
    gearType: 'Otomatik',
    fuelType: 'Benzin',
    colorName: 'Ateş Kırmızısı',
    imageUrl: 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=600&auto=format&fit=crop&q=60',
    description: 'Cam tavanlı Elite paket, orijinal 55 bin kilometrede. Boyasız, tramersiz, sıfır kokusu üzerinde. İçerisinde sigara içilmemiştir. Aküsü ve muayenesi yenidir.',
  ),
  AutoVehicle(
    id: 'car_8',
    galleryName: 'Koylu Auto',
    brand: 'Dacia',
    model: 'Duster 1.5 dCi Comfort 4x2',
    year: 2019,
    price: 890000,
    km: 110000,
    gearType: 'Manuel',
    fuelType: 'Dizel',
    colorName: 'Atacama Turuncusu',
    imageUrl: 'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?w=600&auto=format&fit=crop&q=60',
    description: 'Araziye çıkmamış, sadece şehir içinde kullanılmış Duster. Ezik çizik yoktur. Yakıtı oldukça ekonomiktir. Boyasız, hatasız aile aracıdır. Düziçi çevresi bağ bahçe takasına açıktır.',
  ),
];

class AutoGalleryScreen extends StatefulWidget {
  const AutoGalleryScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.entries,
  });

  final String title;
  final String subtitle;
  final Color color;
  final List<DirectoryEntry> entries;

  @override
  State<AutoGalleryScreen> createState() => _AutoGalleryScreenState();
}

class _AutoGalleryScreenState extends State<AutoGalleryScreen> {
  // İş modeliniz için ilan vitrini özelliğini kapatma/açma bayrağı.
  // false olduğunda kullanıcıya ilan ekleme paket tanıtımı ve galeri telefon rehberini gösterir.
  static const bool enableMockShowroom = false;

  String _selectedGallery = 'Tümü';
  String _selectedBrand = 'Tümü';
  String _selectedGear = 'Tümü';
  String _searchQuery = '';

  late final List<String> _brands;

  @override
  void initState() {
    super.initState();
    final brandSet = _mockVehicles.map((e) => e.brand).toSet();
    _brands = ['Tümü', ...brandSet];
  }

  int _getVehicleCount(String galleryName) {
    if (galleryName == 'Tümü') return _mockVehicles.length;
    return _mockVehicles.where((v) => v.galleryName == galleryName).length;
  }

  int _getBrandCount(String brand) {
    var list = _mockVehicles;
    if (_selectedGallery != 'Tümü') {
      list = list.where((v) => v.galleryName == _selectedGallery).toList();
    }
    if (brand == 'Tümü') return list.length;
    return list.where((v) => v.brand == brand).length;
  }

  List<AutoVehicle> get _filteredVehicles {
    return _mockVehicles.where((v) {
      final matchesGallery = _selectedGallery == 'Tümü' || v.galleryName == _selectedGallery;
      final matchesBrand = _selectedBrand == 'Tümü' || v.brand == _selectedBrand;
      final matchesGear = _selectedGear == 'Tümü' || v.gearType == _selectedGear;
      
      final query = _searchQuery.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          v.brand.toLowerCase().contains(query) ||
          v.model.toLowerCase().contains(query) ||
          v.year.toString().contains(query) ||
          v.fuelType.toLowerCase().contains(query);

      return matchesGallery && matchesBrand && matchesGear && matchesSearch;
    }).toList();
  }

  Future<void> _callPhone(String phone) async {
    final cleaned = phone.replaceAll(' ', '');
    final uri = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openAdminWhatsApp() async {
    const cleanedPhone = '903288760001';
    final message = Uri.encodeComponent(
      'Merhaba, Hepsi Düziçi uygulamasında Oto Galeri kısmına esnaf olarak ücretli araç ilanlarımızı eklemek istiyoruz. Reklam ve ilan paketleri hakkında detaylı bilgi alabilir miyiz?',
    );
    final uri = Uri.parse('https://wa.me/$cleanedPhone?text=$message');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _callAdminPhone() async {
    final uri = Uri.parse('tel:03288760001');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _buildAdPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          // Göz Alıcı İlan Verme Çağrısı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF37474F), Color(0xFF546E7A), Color(0xFF78909C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star_rounded, color: Colors.amber, size: 40),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Esnaf İlan Vitrini Çok Yakında!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Düziçi\'nin en büyük mobil esnaf vitrininde yerinizi alın. Oto galeri esnaflarımıza özel ilan alanlarımız aktif edilmek üzeredir.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Avantajlar Listesi
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Neden Burada Yer Almalısınız?',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
          const SizedBox(height: 12),
          _buildFeatureRow(
            icon: Icons.ads_click_rounded,
            title: 'Müşterileriniz Doğrudan Size Ulaşsın',
            desc: 'Araç detay sayfasındaki WhatsApp ve Telefon butonları sayesinde alıcılar tek tıkla sizinle iletişim kursun.',
          ),
          _buildFeatureRow(
            icon: Icons.photo_library_rounded,
            title: 'Lüks ve Detaylı Dijital Showroom',
            desc: 'Araçlarınızın fotoğraflarını, tramer, boya ve tüm teknik detaylarını en prestijli tasarım eşliğinde sergileyin.',
          ),
          _buildFeatureRow(
            icon: Icons.trending_up_rounded,
            title: 'Düziçi Geneli Geniş Kitle',
            desc: 'Uygulamayı kullanan binlerce Düziçiliye ve çevre ilçelerdeki potansiyel müşterilere doğrudan erişin.',
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          
          // İletişim Butonları
          const Text(
            'İlan Ekleme ve Detaylı Reklam Paket Bilgisi İçin',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openAdminWhatsApp(),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: const Text('WhatsApp Bilgi', style: TextStyle(fontWeight: FontWeight.w800)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _callAdminPhone(),
                  icon: const Icon(Icons.phone_rounded, size: 18),
                  label: const Text('Doğrudan Ara', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Düziçi Oto Galerileri',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ),
          ...widget.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PrimaryCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.storefront_rounded, color: widget.color, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.name,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.address,
                            style: TextStyle(fontSize: 11.5, color: Theme.of(context).textTheme.bodySmall?.color),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _callPhone(entry.phone),
                      icon: Icon(Icons.phone_in_talk_rounded, color: widget.color),
                      tooltip: 'Galeriyi Ara',
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFeatureRow({required IconData icon, required String title, required String desc}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: widget.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final galleries = ['Tümü', ...widget.entries.map((e) => e.name)];

    return ServicePageLayout(
      title: widget.title,
      subtitle: enableMockShowroom 
          ? 'Düziçi yerel oto galerilerinin güncel araç stokları ve iletişim bilgileri.'
          : 'Düziçi yerel oto galerilerinin iletişim adresleri ve esnaf ilan alanı.',
      icon: 'directions_car',
      color: widget.color,
      child: SliverList(
        delegate: SliverChildListDelegate([
          if (!enableMockShowroom) ...[
            _buildAdPlaceholder(),
          ] else ...[
            // === Arama Çubuğu ===
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Marka, model veya yıl arayın...',
                  prefixIcon: Icon(Icons.search_rounded, color: widget.color),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: widget.color, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
                  filled: true,
                ),
              ),
            ),

            // === Galeriler Filtresi ===
            const _FilterTitle(title: 'Galeriler'),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: galleries.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final gal = galleries[i];
                  final isSel = _selectedGallery == gal;
                  final count = _getVehicleCount(gal);

                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(gal),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSel ? Colors.white24 : widget.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            count.toString(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: isSel ? Colors.white : widget.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    selected: isSel,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedGallery = gal;
                          _selectedBrand = 'Tümü'; // Reset brand on gallery switch to avoid empty states
                        });
                      }
                    },
                    selectedColor: widget.color,
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  );
                },
              ),
            ),

            // === Markalar Filtresi ===
            const _FilterTitle(title: 'Markalar'),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _brands.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final b = _brands[i];
                  final isSel = _selectedBrand == b;
                  final count = _getBrandCount(b);

                  if (count == 0 && b != 'Tümü') return const SizedBox.shrink();

                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(b),
                        const SizedBox(width: 4),
                        Text(
                          '($count)',
                          style: TextStyle(
                            fontSize: 10,
                            color: isSel ? Colors.white70 : Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                    selected: isSel,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedBrand = b);
                      }
                    },
                    selectedColor: widget.color.withValues(alpha: 0.8),
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  );
                },
              ),
            ),

            // === Vites Filtresi ===
            const _FilterTitle(title: 'Şanzıman'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: ['Tümü', 'Manuel', 'Otomatik'].map((gear) {
                  final isSel = _selectedGear == gear;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: OutlinedButton(
                        onPressed: () => setState(() => _selectedGear = gear),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isSel ? widget.color : Colors.transparent,
                          foregroundColor: isSel ? Colors.white : widget.color,
                          side: BorderSide(color: widget.color),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Text(gear, style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // === Araç Sayısı ve Sonuç Grid / Listesi ===
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bulunan Araçlar (${_filteredVehicles.length})',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  Icon(Icons.directions_car_filled_outlined, color: widget.color, size: 20),
                ],
              ),
            ),

            if (_filteredVehicles.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
                child: Column(
                  children: [
                    Icon(Icons.directions_car_rounded, size: 64, color: Theme.of(context).dividerColor),
                    const SizedBox(height: 16),
                    const Text(
                      'Kriterlerinize uygun araç bulunamadı.',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Lütfen filtreleri sıfırlamayı veya farklı kelimeler aramayı deneyin.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.18,
                  ),
                  itemCount: _filteredVehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = _filteredVehicles[index];
                    final directoryEntry = widget.entries.firstWhere(
                      (e) => e.name == vehicle.galleryName,
                      orElse: () => DirectoryEntry(name: vehicle.galleryName, phone: '0328 876 0000', address: 'Düziçi Merkez'),
                    );

                    return _ShowroomCarCard(
                      vehicle: vehicle,
                      color: widget.color,
                      entry: directoryEntry,
                    ).animate(delay: (index * 60).ms).fadeIn().scale(begin: const Offset(0.97, 0.97));
                  },
                ),
              ),
            const SizedBox(height: 60),
          ],
        ]),
      ),
    );
  }
}

class _FilterTitle extends StatelessWidget {
  const _FilterTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.outline,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ShowroomCarCard extends StatelessWidget {
  const _ShowroomCarCard({
    required this.vehicle,
    required this.color,
    required this.entry,
  });

  final AutoVehicle vehicle;
  final Color color;
  final DirectoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return PrimaryCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  vehicle.imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 180,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Icon(Icons.directions_car_rounded, size: 48, color: color.withValues(alpha: 0.4)),
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    vehicle.formattedPrice,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    vehicle.year.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${vehicle.brand} ${vehicle.model}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.3),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.store_rounded, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          vehicle.galleryName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _SpecBadge(icon: Icons.speed_rounded, label: vehicle.formattedKm),
                    const SizedBox(width: 8),
                    _SpecBadge(icon: Icons.settings_input_component_rounded, label: vehicle.gearType),
                    const SizedBox(width: 8),
                    _SpecBadge(icon: Icons.local_gas_station_rounded, label: vehicle.fuelType),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showDetailBottomSheet(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: color,
                          side: BorderSide(color: color.withValues(alpha: 0.4)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text('Detaylar & İncele', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${vehicle.brand} ${vehicle.model}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.4),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '📍 ${vehicle.galleryName}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
                      ),
                    ],
                  ),
                  Text(
                    vehicle.formattedPrice,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              const Text('Teknik Detaylar', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              const SizedBox(height: 8),
              Table(
                border: TableBorder.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.4), width: 1, borderRadius: BorderRadius.circular(8)),
                children: [
                  _tableRow('Yıl / Model Yılı', vehicle.year.toString()),
                  _tableRow('Kilometre (Km)', vehicle.formattedKm),
                  _tableRow('Şanzıman / Vites', vehicle.gearType),
                  _tableRow('Yakıt Tipi', vehicle.fuelType),
                  _tableRow('Renk', vehicle.colorName),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Açıklama', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              const SizedBox(height: 6),
              Text(
                vehicle.description,
                style: const TextStyle(fontSize: 13, height: 1.45),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openWhatsApp(context),
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                      label: const Text('WhatsApp Sor', style: TextStyle(fontWeight: FontWeight.w800)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _callPhone(context, entry.phone),
                      icon: const Icon(Icons.phone_rounded, size: 18),
                      label: const Text('Galeriyi Ara', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (entry.address.isNotEmpty)
                Center(
                  child: TextButton.icon(
                    onPressed: () => _openMap(context, entry.address),
                    icon: Icon(Icons.map_rounded, size: 16, color: color),
                    label: Text(
                      'Konumu Haritada Göster',
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  TableRow _tableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(value, style: const TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  Future<void> _callPhone(BuildContext context, String phone) async {
    final cleaned = phone.replaceAll(' ', '');
    final uri = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final phone = entry.phone.replaceAll(' ', '').replaceAll('+', '');
    final cleanedPhone = phone.startsWith('0') ? '90${phone.substring(1)}' : phone;
    final message = Uri.encodeComponent(
      'Merhaba, ${vehicle.galleryName}\'ndaki ${vehicle.year} model ${vehicle.brand} ${vehicle.model} aracınız hakkında bilgi alabilir miyim?',
    );
    final uri = Uri.parse('https://wa.me/$cleanedPhone?text=$message');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp uygulaması açılamadı.')),
        );
      }
    }
  }

  Future<void> _openMap(BuildContext context, String address) async {
    final query = Uri.encodeComponent('$address, Düziçi, Osmaniye');
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _SpecBadge extends StatelessWidget {
  const _SpecBadge({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
