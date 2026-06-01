import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/models/city_content.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/launcher_utils.dart';
import '../../core/utils/target_router.dart';
import '../../core/widgets/primary_card.dart';
import '../../core/widgets/service_page_layout.dart';

class TransportationScreen extends StatefulWidget {
  final TransportationData data;

  const TransportationScreen({super.key, required this.data});

  @override
  State<TransportationScreen> createState() => _TransportationScreenState();
}

class _TransportationScreenState extends State<TransportationScreen> {
  String _searchQuery = '';
  bool _faresExpanded = false; // Collapsible price fares to eliminate text clutter

  bool _isDolmusActive(String timesStr) {
    try {
      final regex = RegExp(r'(\d{2}):(\d{2})\s*-\s*(\d{2}):(\d{2})');
      final match = regex.firstMatch(timesStr);
      if (match != null) {
        final startHour = int.parse(match.group(1)!);
        final startMin = int.parse(match.group(2)!);
        final endHour = int.parse(match.group(3)!);
        final endMin = int.parse(match.group(4)!);

        final now = DateTime.now();
        final currentMinutes = now.hour * 60 + now.minute;
        final startMinutes = startHour * 60 + startMin;
        final endMinutes = endHour * 60 + endMin;

        return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
      }
    } catch (e) {
      // Fallback
    }
    return true;
  }

  void _showDolmusDetailsSheet(BuildContext context, DolmusItem dolmus) {
    final bool isActive = _isDolmusActive(dolmus.schedule);
    final stopsList = dolmus.firstBus.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF43A047).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.directions_bus_rounded, color: Color(0xFF43A047), size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dolmus.route,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? const Color(0xFF43A047).withValues(alpha: 0.15)
                                        : Colors.grey.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: isActive ? const Color(0xFF4CAF50) : Colors.grey,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isActive ? 'Şu An Aktif' : 'Sefer Dışı',
                                        style: TextStyle(
                                          color: isActive ? const Color(0xFF2E7D32) : Colors.grey.shade600,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Hat Rehberi',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (dolmus.fareSummary != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF43A047).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.payments_rounded, color: Color(0xFF2E7D32), size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dolmus.fareSummary!,
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                                ),
                                if (dolmus.fareNote != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    dolmus.fareNote!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).textTheme.bodySmall?.color,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 24),
                  ],
                  if (dolmus.operator != null && dolmus.operator!.isNotEmpty) ...[
                    Text(
                      'İŞLETMECİ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(dolmus.operator!, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                  ],
                  const Divider(height: 32),
                  // Sefer bilgisi
                  Text(
                    'SEFER SAATLERİ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_filled_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                           child: Text(
                            dolmus.schedule,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Durak Zaman Çizelgesi (Visual Timeline Stepper)
                  Text(
                    'GÜZERGAH VE DURAKLAR',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (stopsList.isEmpty)
                    const Text('Durak bilgisi bulunmamaktadır.')
                  else
                    ...stopsList.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final stop = entry.value;
                      final isFirst = idx == 0;
                      final isLast = idx == stopsList.length - 1;

                      return IntrinsicHeight(
                        child: Row(
                          children: [
                            // Sol Rota Zaman Çizgisi
                            Column(
                              children: [
                                // Çizginin üst parçası
                                Container(
                                  width: 2,
                                  height: 12,
                                  color: isFirst
                                      ? Colors.transparent
                                      : Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                                ),
                                // Durak Yuvarlağı
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: isFirst
                                        ? const Color(0xFF4CAF50)
                                        : isLast
                                            ? const Color(0xFFE53935)
                                            : Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isFirst
                                                ? const Color(0xFF4CAF50)
                                                : isLast
                                                    ? const Color(0xFFE53935)
                                                    : Theme.of(context).colorScheme.primary)
                                            .withValues(alpha: 0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                                // Çizginin alt parçası
                                Expanded(
                                  child: Container(
                                    width: 2,
                                    color: isLast
                                        ? Colors.transparent
                                        : Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            // Durak Adı
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      stop,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: (isFirst || isLast) ? FontWeight.w800 : FontWeight.w600,
                                        color: (isFirst || isLast)
                                            ? Theme.of(context).colorScheme.onSurface
                                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                                      ),
                                    ),
                                    if (isFirst)
                                      const Text(
                                        'Başlangıç Noktası',
                                        style: TextStyle(fontSize: 11, color: Color(0xFF4CAF50), fontWeight: FontWeight.bold),
                                      )
                                    else if (isLast)
                                      const Text(
                                        'Son Durak',
                                        style: TextStyle(fontSize: 11, color: Color(0xFFE53935), fontWeight: FontWeight.bold),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 24),
                  // Genel İpuçları
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB300).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFFB300).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Color(0xFFE65100), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Yolcu Bilgilendirme',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFE65100),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          '• Saatler trafik ve yol durumuna göre değişebilir.\n'
                          '• Dolmuş ödemelerinizi nakit veya temassız banka/kredi kartıyla yapabilirsiniz.\n'
                          '• İndirimli binişler için öğrenci kimlik belgenizi göstermeniz rica olunur.',
                          style: TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Search and filter
    bool matches(DolmusItem d) {
      final q = _searchQuery.toLowerCase();
      if (q.isEmpty) return true;
      return d.route.toLowerCase().contains(q) ||
          d.firstBus.toLowerCase().contains(q) ||
          (d.operator ?? '').toLowerCase().contains(q);
    }

    final intercity = widget.data.dolmus.where((d) => d.isIntercity && matches(d)).toList();
    final local = widget.data.dolmus.where((d) => !d.isIntercity && matches(d)).toList();

    return ServicePageLayout(
      title: 'Ulaşım Rehberi',
      subtitle: '', // Removed generic top banner to eliminate text clutter
      icon: 'directions_bus_rounded',
      color: const Color(0xFF4CAF50),
      child: SliverList(
        delegate: SliverChildListDelegate([
          // Sleek Screen Intro Description
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
            child: Text(
              'Düziçi şehir içi dolmuş hatları, güzergahları, güncel ücret tarifeleri ve şehirlerarası otogar & taksi çağrı merkezi.',
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.75),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Super Premium Quick Access Row (Taksi Çağır + Otogar Danışma)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                // Call Taxi Link
                Expanded(
                  child: InkWell(
                    onTap: () => TargetRouter.handle(context, 'screen:taxi'),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFA726), Color(0xFFFB8C00)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFA726).withValues(alpha: 0.22),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.local_taxi_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Taksi Çağır',
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
                // Call Otogar Information
                Expanded(
                  child: InkWell(
                    onTap: () => LauncherUtils.callPhone(context, '03288761230'),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7E57C2), Color(0xFF5E35B1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7E57C2).withValues(alpha: 0.22),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.domain_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Otogar Danışma',
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
          ),
          const SizedBox(height: 12),

          // Sleek Düziçi Otogar Information Card (Simplified)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: PrimaryCard(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(4),
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
                            color: const Color(0xFF7E57C2).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF7E57C2).withValues(alpha: 0.15)),
                          ),
                          child: const Icon(Icons.domain_rounded, color: Color(0xFF7E57C2), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Düziçi Şehirlerarası Otogar',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                  color: Theme.of(context).colorScheme.onSurface,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined, size: 13, color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Karacaören Mah., Çevre Yolu Üzeri, Düziçi',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.015),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.directions_bus_rounded, color: const Color(0xFF7E57C2), size: 14),
                              const SizedBox(width: 6),
                              const Text(
                                'Aktif Otobüs Firmaları:',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF7E57C2),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: const [
                              _BusCompanyChip(name: 'Düziçi Koop'),
                              _BusCompanyChip(name: 'Düziçi Seyahat'),
                              _BusCompanyChip(name: 'Metro Turizm'),
                              _BusCompanyChip(name: 'Seç Turizm'),
                              _BusCompanyChip(name: 'Has Turizm'),
                              _BusCompanyChip(name: 'Ak Akdeniz'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Collapsible Premium Fares Panel
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: PrimaryCard(
              margin: EdgeInsets.zero,
              onTap: () => setState(() => _faresExpanded = !_faresExpanded),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.payments_rounded, color: Color(0xFF4CAF50), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Yolculuk Ücret Tarifeleri',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _faresExpanded ? 'Detayları gizlemek için tıklayın' : 'İlçe içi ve ilçeler arası ücretleri gör',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        duration: const Duration(milliseconds: 220),
                        turns: _faresExpanded ? 0.5 : 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.expand_more_rounded,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_faresExpanded) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Text(
                      'İLÇE İÇİ DOLMUŞ HATLARI',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: _FareChip(label: 'İndi-Bindi', amount: '20 ₺')),
                        const SizedBox(width: 8),
                        Expanded(child: _FareChip(label: 'Tam Bilet', amount: '25 ₺')),
                        const SizedBox(width: 8),
                        Expanded(child: _FareChip(label: 'Öğrenci', amount: '15 ₺')),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      'İLÇELER ARASI MİNİBÜS (DÜZİÇİ ↔ OSMANİYE / ADANA)',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _FareChip(label: 'Düziçi–Osmaniye', amount: '100 ₺')),
                        const SizedBox(width: 8),
                        Expanded(child: _FareChip(label: 'Öğrenci', amount: '85 ₺')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _FareChip(label: 'Düziçi–Kanlı Geçit', amount: '50 ₺')),
                        const SizedBox(width: 8),
                        Expanded(child: _FareChip(label: 'Kanlı Geçit–Osmaniye', amount: '50 ₺')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _FareChip(label: 'Düziçi–Adana', amount: '180 ₺')),
                        const SizedBox(width: 8),
                        Expanded(child: _FareChip(label: 'Öğrenci', amount: '150 ₺')),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '* Resmi kooperatif ve hat işletmecisi kararlarına göre otobüs firmalarında farklı tarifeler geçerli olabilir.',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Durak veya mahalle adı ile hat ara...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // List headers and entries
          if (local.isEmpty && intercity.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.directions_bus_filled_outlined, size: 44, color: Colors.grey.shade500),
                    const SizedBox(height: 12),
                    Text(
                      'Aradığınız güzergaha giden dolmuş hattı bulunamadı.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13.5, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else ...[
            if (local.isNotEmpty) ...[
              const _SectionHeader(title: 'İlçe İçi Dolmuş Hatları', icon: Icons.route_rounded),
              ...local.asMap().entries.map((e) => _buildDolmusCard(context, e.value, e.key)),
            ],
            if (intercity.isNotEmpty) ...[
              const _SectionHeader(title: 'İlçeler Arası Minibüs Seferleri', icon: Icons.swap_horiz_rounded),
              ...intercity.asMap().entries.map((e) => _buildDolmusCard(context, e.value, 100 + e.key, isIntercity: true)),
            ],
          ],
        ]),
      ),
    );
  }

  Widget _buildDolmusCard(BuildContext context, DolmusItem dolmus, int animIndex, {bool isIntercity = false}) {
    final isActive = _isDolmusActive(dolmus.schedule);
    final accent = isIntercity ? const Color(0xFF1565C0) : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: PrimaryCard(
        margin: EdgeInsets.zero,
        onTap: () => _showDolmusDetailsSheet(context, dolmus),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modern Rounded Icon Container
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accent.withValues(alpha: 0.15)),
                  ),
                  child: Icon(
                    isIntercity ? Icons.swap_horiz_rounded : Icons.route_rounded,
                    color: accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Route Name
                      Text(
                        dolmus.route,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Operator
                      if (dolmus.operator != null)
                        Text(
                          dolmus.operator!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Fare Price tag or Active chip
                if (dolmus.fareFull != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF43A047).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF43A047).withValues(alpha: 0.15)),
                    ),
                    child: Text(
                      dolmus.fareFull!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF4CAF50).withValues(alpha: 0.12)
                          : Colors.grey.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isActive ? 'Aktif' : 'Pasif',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isActive ? const Color(0xFF2E7D32) : Colors.grey.shade600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(icon: Icons.schedule_rounded, label: 'Seferler:', value: dolmus.schedule),
            const SizedBox(height: 6),
            _InfoRow(icon: Icons.place_rounded, label: 'Güzergah:', value: dolmus.firstBus),
            if (dolmus.fareStudent != null) ...[
              const SizedBox(height: 6),
              _InfoRow(icon: Icons.school_rounded, label: 'Öğrenci:', value: dolmus.fareStudent!),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Detaylı Rota & Tarifeler',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 13, color: accent),
              ],
            ),
          ],
        ),
      ),
    ).animate(delay: (animIndex * 40).ms).fadeIn().slideY(begin: 0.04, end: 0, curve: Curves.easeOutCubic);
  }
}

class _BusCompanyChip extends StatelessWidget {
  final String name;

  const _BusCompanyChip({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _FareChip extends StatelessWidget {
  final String label;
  final String amount;

  const _FareChip({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7), size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  letterSpacing: 0.3,
                ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6)),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12.5, color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.75), fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 12.5, color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500, height: 1.3),
          ),
        ),
      ],
    );
  }
}
