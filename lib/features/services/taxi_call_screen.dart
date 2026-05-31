import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../app/providers.dart';
import '../../core/utils/launcher_utils.dart';
import '../../core/widgets/primary_card.dart';
import '../../core/widgets/service_page_layout.dart';
import '../../data/models/city_content.dart';
import 'transportation_screen.dart';
import 'widgets/taxi_stand_map.dart';

const _taxiColor = Color(0xFFFFA726);

class TaxiCallScreen extends ConsumerStatefulWidget {
  const TaxiCallScreen({super.key, required this.stands, this.fares});

  final List<TaxiStandItem> stands;
  final TaxiFareGuide? fares;

  @override
  ConsumerState<TaxiCallScreen> createState() => _TaxiCallScreenState();
}

class _TaxiCallScreenState extends ConsumerState<TaxiCallScreen> {
  String? _selectedId;
  String? _expandedId;
  double? _userLat;
  double? _userLng;
  bool _isLocating = false;

  List<TaxiStandItem> get _sorted {
    final list = List<TaxiStandItem>.from(widget.stands);
    if (_userLat == null || _userLng == null) return list;
    list.sort((a, b) {
      final da = _distanceKm(a);
      final db = _distanceKm(b);
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });
    return list;
  }

  TaxiStandItem? get _nearest {
    final s = _sorted;
    return s.isEmpty ? null : s.first;
  }

  double? _distanceKm(TaxiStandItem stand) {
    if (_userLat == null || _userLng == null || !stand.hasCoords) return null;
    const r = 6371.0;
    final dLat = _deg2rad(stand.lat! - _userLat!);
    final dLng = _deg2rad(stand.lng! - _userLng!);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(_userLat!)) *
            math.cos(_deg2rad(stand.lat!)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  double _deg2rad(double deg) => deg * (math.pi / 180);

  Future<void> _locateNearest() async {
    setState(() => _isLocating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('GPS kapalı. Duraklar varsayılan sırayla listeleniyor.')),
          );
        }
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Konum izni yok. En yakın durak otomatik seçilemedi.')),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      if (!mounted) return;
      setState(() {
        _userLat = pos.latitude;
        _userLng = pos.longitude;
        final near = _nearest;
        if (near != null) _selectedId = near.id;
      });
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _locateNearest());
  }

  @override
  Widget build(BuildContext context) {
    final stands = _sorted;
    final nearest = _nearest;

    return ServicePageLayout(
      title: 'Taksi Çağır',
      subtitle: 'Resmî taksi durakları — tek dokunuşla arayın veya konum paylaşın.',
      icon: 'local_taxi',
      color: _taxiColor,
      onRefresh: _locateNearest,
      isEmpty: stands.isEmpty,
      emptyMessage: 'Taksi durağı bilgisi henüz eklenmedi.',
      floatingActionButton: nearest == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => LauncherUtils.callPhone(context, nearest.phone),
              backgroundColor: _taxiColor,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.phone_in_talk_rounded),
              label: const Text('Hemen ara'),
            ),
      child: SliverList(
        delegate: SliverChildListDelegate([
          if (nearest != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: _HeroCard(
                stand: nearest,
                distanceKm: _distanceKm(nearest),
                isLocating: _isLocating,
                onCall: () => LauncherUtils.callPhone(context, nearest.phone),
                onLocate: _locateNearest,
              ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.04, end: 0),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TaxiStandMap(
              stands: stands,
              selectedId: _selectedId,
              onSelect: (s) => setState(() {
                _selectedId = s.id;
                _expandedId = s.id;
              }),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Tüm duraklar',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const Spacer(),
                if (_isLocating)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  TextButton.icon(
                    onPressed: _locateNearest,
                    icon: const Icon(Icons.my_location_rounded, size: 18),
                    label: const Text('Konumum'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...stands.asMap().entries.map((e) {
            final stand = e.value;
            final expanded = _expandedId == stand.id;
            final selected = _selectedId == stand.id;
            final dist = _distanceKm(stand);
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: _TaxiStandCard(
                stand: stand,
                distanceKm: dist,
                selected: selected,
                expanded: expanded,
                onTap: () => setState(() {
                  _selectedId = stand.id;
                  _expandedId = expanded ? null : stand.id;
                }),
              ).animate(delay: (e.key * 40).ms).fadeIn().slideX(begin: 0.03, end: 0),
            );
          }),
          if (widget.fares != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: _FareGuideCard(fares: widget.fares!).animate().fadeIn(delay: 120.ms),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 88),
            child: _InfoPanel(
              fares: widget.fares,
              onOpenTransport: () async {
                final content = await ref.read(cityContentProvider.future);
                if (!context.mounted) return;
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TransportationScreen(data: content.transportation),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.stand,
    required this.distanceKm,
    required this.isLocating,
    required this.onCall,
    required this.onLocate,
  });

  final TaxiStandItem stand;
  final double? distanceKm;
  final bool isLocating;
  final VoidCallback onCall;
  final VoidCallback onLocate;

  @override
  Widget build(BuildContext context) {
    final distLabel = distanceKm == null
        ? 'Konumunuza göre sıralama için GPS kullanın'
        : '${distanceKm!.toStringAsFixed(1)} km — size en yakın durak';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _taxiColor,
            _taxiColor.withValues(alpha: 0.82),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _taxiColor.withValues(alpha: 0.35),
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
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.local_taxi_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stand.tag != null ? '${stand.tag} · Önerilen' : 'Önerilen durak',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      stand.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            distLabel,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 13),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onCall,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _taxiColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.phone_rounded),
                  label: Text(stand.phone, style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: isLocating ? null : onLocate,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.22),
                  foregroundColor: Colors.white,
                ),
                icon: isLocating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.my_location_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaxiStandCard extends StatelessWidget {
  const _TaxiStandCard({
    required this.stand,
    required this.distanceKm,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  final TaxiStandItem stand;
  final double? distanceKm;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall?.color;

    return PrimaryCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _taxiColor.withValues(alpha: selected ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: selected ? Border.all(color: _taxiColor, width: 2) : null,
                  ),
                  child: const Icon(Icons.local_taxi_rounded, color: Color(0xFFF57C00)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              stand.name,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                          ),
                          if (stand.tag != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _taxiColor.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                stand.tag!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFE65100),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stand.location,
                        maxLines: expanded ? 4 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: muted, fontSize: 13),
                      ),
                      if (distanceKm != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${distanceKm!.toStringAsFixed(1)} km uzaklıkta',
                          style: const TextStyle(
                            color: Color(0xFFE65100),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: muted,
                ),
              ],
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (stand.hours != null)
                    _DetailRow(icon: Icons.schedule_rounded, label: 'Çalışma', value: stand.hours!),
                  _DetailRow(icon: Icons.phone_rounded, label: 'Telefon', value: stand.phone),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: () => LauncherUtils.callPhone(context, stand.phone),
                        icon: const Icon(Icons.phone_rounded, size: 18),
                        label: const Text('Ara'),
                        style: FilledButton.styleFrom(backgroundColor: _taxiColor),
                      ),
                      if (stand.isMobileLine)
                        OutlinedButton.icon(
                          onPressed: () => LauncherUtils.openWhatsApp(
                            context,
                            stand.phone,
                            message: 'Merhaba, Düziçi’nde taksi çağırıyorum. Konumum: ',
                          ),
                          icon: const Icon(Icons.chat_rounded, size: 18),
                          label: const Text('WhatsApp'),
                        ),
                      OutlinedButton.icon(
                        onPressed: () => stand.hasCoords
                            ? LauncherUtils.openMapsWithLatLng(context, stand.lat!, stand.lng!)
                            : LauncherUtils.openMapsWithAddress(context, stand.location),
                        icon: const Icon(Icons.map_rounded, size: 18),
                        label: const Text('Haritada'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Theme.of(context).textTheme.bodySmall?.color)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _FareGuideCard extends StatelessWidget {
  const _FareGuideCard({required this.fares});

  final TaxiFareGuide fares;

  bool get _isNightNow {
    final h = DateTime.now().hour;
    return h >= 0 && h < 6;
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall?.color;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _taxiColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isNightNow ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                color: _isNightNow ? const Color(0xFF5C6BC0) : _taxiColor,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Ücret rehberi',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              if (_isNightNow)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5C6BC0).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Gece tarifesi',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF3949AB)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _FareRow(label: 'Açılış', value: fares.openingFee, highlight: false),
          _FareRow(label: 'Gündüz (km)', value: fares.dayPerKm, highlight: !_isNightNow),
          _FareRow(label: 'Gece (km)', value: fares.nightPerKm, highlight: _isNightNow),
          _FareRow(label: 'Gece saatleri', value: fares.nightHours, highlight: false),
          _FareRow(label: 'Asgari ücret', value: fares.minimumFare, highlight: false),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.celebration_rounded, size: 18, color: Color(0xFFE65100)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fares.bayramNote,
                    style: const TextStyle(fontSize: 12, height: 1.35, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            fares.disclaimer,
            style: TextStyle(fontSize: 11, color: muted, height: 1.35, fontStyle: FontStyle.italic),
          ),
          if (fares.tips.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...fares.tips.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
                    Expanded(
                      child: Text(t, style: TextStyle(fontSize: 12, color: muted, height: 1.3)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FareRow extends StatelessWidget {
  const _FareRow({required this.label, required this.value, required this.highlight});

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: highlight ? const Color(0xFFE65100) : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.onOpenTransport, this.fares});

  final VoidCallback onOpenTransport;
  final TaxiFareGuide? fares;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bilgi',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            fares == null
                ? 'Ücretler sürücü ile görüşülür. Dolmuş güzergâhları için ulaşım rehberine bakın.'
                : 'Yukarıdaki tarifeler bilgilendirme amaçlıdır. Dolmuş güzergâhları için ulaşım rehberine bakın.',
            style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color, height: 1.4),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onOpenTransport,
            icon: const Icon(Icons.directions_bus_rounded),
            label: const Text('Dolmuş saatleri'),
          ),
        ],
      ),
    );
  }
}
