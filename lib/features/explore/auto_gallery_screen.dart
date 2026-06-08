import 'package:cached_network_image/cached_network_image.dart';
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

class AutoGalleryScreen extends StatefulWidget {
  const AutoGalleryScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.entries,
    this.autoVehicles = const [],
  });

  final String title;
  final String subtitle;
  final Color color;
  final List<DirectoryEntry> entries;
  final List<AutoVehicleItem> autoVehicles;

  @override
  State<AutoGalleryScreen> createState() => _AutoGalleryScreenState();
}

class _AutoGalleryScreenState extends State<AutoGalleryScreen> {
  String _selectedBrand = 'Tümü';
  String _selectedGear = 'Tümü';
  String _searchQuery = '';

  late final List<String> _brands;

  bool get _hasBackendVehicles => widget.autoVehicles.isNotEmpty;

  @override
  void initState() {
    super.initState();
    // Only active vehicles shown
    final activeVehicles = widget.autoVehicles.where((v) => v.isActive).toList();
    final brandSet = activeVehicles.map((e) => e.brand).where((b) => b.isNotEmpty).toSet();
    _brands = ['Tümü', ...brandSet];
  }

  List<AutoVehicleItem> get _activeVehicles =>
      widget.autoVehicles.where((v) => v.isActive).toList();

  int _getVehicleBrandCount(String brand) {
    if (brand == 'Tümü') return _activeVehicles.length;
    return _activeVehicles.where((v) => v.brand == brand).length;
  }

  List<AutoVehicleItem> get _filteredVehicles {
    return _activeVehicles.where((v) {
      final matchesBrand = _selectedBrand == 'Tümü' || v.brand == _selectedBrand;
      final gearLabel = _gearLabel(v.gearType ?? '');
      final matchesGear = _selectedGear == 'Tümü' || gearLabel == _selectedGear;
      final query = _searchQuery.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          v.brand.toLowerCase().contains(query) ||
          v.model.toLowerCase().contains(query) ||
          (v.year ?? '').toLowerCase().contains(query) ||
          (v.fuelType ?? '').toLowerCase().contains(query) ||
          v.title.toLowerCase().contains(query);
      return matchesBrand && matchesGear && matchesSearch;
    }).toList();
  }

  String _gearLabel(String raw) {
    switch (raw.toLowerCase()) {
      case 'otomatik': return 'Otomatik';
      case 'manuel': return 'Manuel';
      default: return raw.isNotEmpty ? raw : 'Manuel';
    }
  }

  String _formatPrice(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final num = double.tryParse(raw.replaceAll('.', '').replaceAll(',', '.'));
    if (num == null) return '$raw ₺';
    final str = num.toStringAsFixed(0);
    final buf = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buf.write(str[i]);
      count++;
      if (count == 3 && i != 0) { buf.write('.'); count = 0; }
    }
    return '${buf.toString().split('').reversed.join()} ₺';
  }

  String _formatKm(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final num = int.tryParse(raw.replaceAll('.', ''));
    if (num == null) return '$raw km';
    final str = num.toString();
    final buf = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buf.write(str[i]);
      count++;
      if (count == 3 && i != 0) { buf.write('.'); count = 0; }
    }
    return '${buf.toString().split('').reversed.join()} km';
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
    return ServicePageLayout(
      title: widget.title,
      subtitle: _hasBackendVehicles
          ? 'Düziçi yerel oto galerilerinin güncel araç stokları ve iletişim bilgileri.'
          : 'Düziçi yerel oto galerilerinin iletişim adresleri ve esnaf ilan alanı.',
      icon: 'directions_car',
      color: widget.color,
      child: SliverList(
        delegate: SliverChildListDelegate([
          if (!_hasBackendVehicles) ...[
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
                  final count = _getVehicleBrandCount(b);
                  if (count == 0 && b != 'Tümü') return const SizedBox.shrink();
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(b),
                        const SizedBox(width: 4),
                        Text('($count)', style: TextStyle(fontSize: 10, color: isSel ? Colors.white70 : Theme.of(context).textTheme.bodySmall?.color)),
                      ],
                    ),
                    selected: isSel,
                    onSelected: (selected) { if (selected) setState(() => _selectedBrand = b); },
                    selectedColor: widget.color.withValues(alpha: 0.8),
                    labelStyle: TextStyle(color: isSel ? Colors.white : Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600),
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
                    return _BackendVehicleCard(
                      vehicle: vehicle,
                      color: widget.color,
                      formatPrice: _formatPrice,
                      formatKm: _formatKm,
                      gearLabel: _gearLabel,
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

// Backend'den gelen AutoVehicleItem verisini gösteren kart widget'i
class _BackendVehicleCard extends StatelessWidget {
  const _BackendVehicleCard({
    required this.vehicle,
    required this.color,
    required this.formatPrice,
    required this.formatKm,
    required this.gearLabel,
  });

  final AutoVehicleItem vehicle;
  final Color color;
  final String Function(String?) formatPrice;
  final String Function(String?) formatKm;
  final String Function(String) gearLabel;

  Future<void> _callPhone(BuildContext context) async {
    final phone = (vehicle.contact ?? '').replaceAll(' ', '');
    if (phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final raw = (vehicle.contact ?? '').replaceAll(' ', '').replaceAll('+', '');
    if (raw.isEmpty) return;
    final cleanedPhone = raw.startsWith('0') ? '90${raw.substring(1)}' : raw;
    final message = Uri.encodeComponent(
      'Merhaba, ${vehicle.sellerName ?? 'Galeri'}\'ndeki ${vehicle.year ?? ''} model ${vehicle.brand} ${vehicle.model} araç ilanınız hakkında bilgi alabilir miyim?',
    );
    final uri = Uri.parse('https://wa.me/$cleanedPhone?text=$message');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WhatsApp uygulaması açılamadı.')));
    }
  }

  void _showDetailSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(20, 10, 20, MediaQuery.of(ctx).viewInsets.bottom + 30),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Theme.of(ctx).dividerColor, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              if (vehicle.isPaid)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFf59e0b), Color(0xFFd97706)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('Öne Çıkan İlan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                    ],
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.title,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.3),
                        ),
                        if ((vehicle.sellerName ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('🏢 ${vehicle.sellerName}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
                          ),
                      ],
                    ),
                  ),
                  if ((vehicle.price ?? '').isNotEmpty)
                    Text(formatPrice(vehicle.price), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              const Text('Teknik Detaylar', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              const SizedBox(height: 8),
              Table(
                border: TableBorder.all(
                  color: Theme.of(ctx).dividerColor.withValues(alpha: 0.4),
                  width: 1,
                  borderRadius: BorderRadius.circular(8),
                ),
                children: [
                  if ((vehicle.year ?? '').isNotEmpty)
                    _tableRow(ctx, 'Yıl / Model Yılı', vehicle.year!),
                  if ((vehicle.km ?? '').isNotEmpty)
                    _tableRow(ctx, 'Kilometre (Km)', formatKm(vehicle.km)),
                  if ((vehicle.gearType ?? '').isNotEmpty)
                    _tableRow(ctx, 'Şanzıman / Vites', gearLabel(vehicle.gearType!)),
                  if ((vehicle.fuelType ?? '').isNotEmpty)
                    _tableRow(ctx, 'Yakıt Tipi', vehicle.fuelType!),
                  if ((vehicle.color ?? '').isNotEmpty)
                    _tableRow(ctx, 'Renk', vehicle.color!),
                  if ((vehicle.bodyType ?? '').isNotEmpty)
                    _tableRow(ctx, 'Kasa Tipi', vehicle.bodyType!),
                ],
              ),
              if ((vehicle.description ?? '').isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Açıklama', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                const SizedBox(height: 6),
                Text(vehicle.description!, style: const TextStyle(fontSize: 13, height: 1.45)),
              ],
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  if ((vehicle.contact ?? '').isNotEmpty) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openWhatsApp(ctx),
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
                        onPressed: () => _callPhone(ctx),
                        icon: const Icon(Icons.phone_rounded, size: 18),
                        label: const Text('Satıcıyı Ara', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ] else
                    Expanded(
                      child: Text('Bu ilan için iletişim bilgisi bulunmuyor.', style: TextStyle(color: Theme.of(ctx).colorScheme.outline, fontSize: 13), textAlign: TextAlign.center),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _tableRow(BuildContext context, String label, String value) {
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.all(10), child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        Padding(padding: const EdgeInsets.all(10), child: Text(value, style: const TextStyle(fontSize: 12))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final thumb = vehicle.thumbnailUrl;
    return PrimaryCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: thumb != null && thumb.startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: thumb,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          height: 180,
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          child: const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          height: 180,
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: Icon(Icons.directions_car_rounded, size: 48, color: color.withValues(alpha: 0.4)),
                        ),
                      )
                    : Container(
                        height: 180,
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.directions_car_rounded, size: 64, color: color.withValues(alpha: 0.3)),
                      ),
              ),
              if ((vehicle.price ?? '').isNotEmpty)
                Positioned(
                  bottom: 12, right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: Text(formatPrice(vehicle.price), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14)),
                  ),
                ),
              if ((vehicle.year ?? '').isNotEmpty)
                Positioned(
                  top: 12, left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.65), borderRadius: BorderRadius.circular(6)),
                    child: Text(vehicle.year!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ),
              if (vehicle.isPaid)
                Positioned(
                  top: 12, right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFf59e0b), Color(0xFFd97706)]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, color: Colors.white, size: 11),
                        SizedBox(width: 3),
                        Text('ÖNE ÇIKAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 9)),
                      ],
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
                    Expanded(
                      child: Text(
                        '${vehicle.brand} ${vehicle.model}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.3),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if ((vehicle.sellerName ?? '').isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.store_rounded, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(vehicle.sellerName!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.outline)),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if ((vehicle.km ?? '').isNotEmpty)
                      _SpecBadge(icon: Icons.speed_rounded, label: formatKm(vehicle.km)),
                    if ((vehicle.km ?? '').isNotEmpty) const SizedBox(width: 8),
                    if ((vehicle.gearType ?? '').isNotEmpty)
                      _SpecBadge(icon: Icons.settings_input_component_rounded, label: gearLabel(vehicle.gearType!)),
                    if ((vehicle.gearType ?? '').isNotEmpty) const SizedBox(width: 8),
                    if ((vehicle.fuelType ?? '').isNotEmpty)
                      _SpecBadge(icon: Icons.local_gas_station_rounded, label: vehicle.fuelType!),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showDetailSheet(context),
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
}
