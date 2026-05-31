import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/utils/launcher_utils.dart';
import '../../core/utils/relative_time.dart';
import '../../core/widgets/primary_card.dart';
import '../../core/widgets/service_page_layout.dart';
import '../../data/models/fuel_price.dart';
import 'widgets/fuel_station_map.dart';

const _fuelColor = Color(0xFFF4511E);

class FuelPricesScreen extends ConsumerStatefulWidget {
  const FuelPricesScreen({super.key});

  @override
  ConsumerState<FuelPricesScreen> createState() => _FuelPricesScreenState();
}

class _FuelPricesScreenState extends ConsumerState<FuelPricesScreen> {
  final _litersController = TextEditingController(text: '40');
  String? _selectedStationId;

  @override
  void dispose() {
    _litersController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await ref.read(fuelServiceProvider).getStampedPrices(forceRefresh: true);
    ref.invalidate(stampedFuelProvider);
  }

  double get _liters {
    final v = double.tryParse(_litersController.text.replaceAll(',', '.'));
    if (v == null || v <= 0) return 40;
    return v;
  }

  FuelPrice? _find(List<FuelPrice> list, String code) {
    for (final p in list) {
      if (p.code.toUpperCase() == code.toUpperCase()) return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final fuelAsync = ref.watch(stampedFuelProvider);
    final cityAsync = ref.watch(cityContentProvider);

    return fuelAsync.when(
      data: (stamped) {
        final prices = stamped.data;
        final info = cityAsync.maybeWhen(data: (c) => c.fuel, orElse: () => null);
        final diesel = _find(prices, 'DIESEL');
        final region = info?.region ?? 'Osmaniye / Düziçi';

        return ServicePageLayout(
          title: 'Akaryakıt Fiyatları',
          subtitle: '$region güncel pompa fiyatları — otomatik yenilenir.',
          icon: 'local_gas_station',
          color: _fuelColor,
          onRefresh: _refresh,
          isEmpty: prices.isEmpty,
          emptyMessage: 'Fiyat verisi alınamadı. Yenilemeyi deneyin.',
          floatingActionButton: prices.isEmpty
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _sharePrices(prices, stamped.fetchedAt, region),
                  backgroundColor: _fuelColor,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.ios_share_rounded),
                  label: const Text('Fiyatları paylaş'),
                ),
          child: SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: _HeroPriceCard(
                  diesel: diesel,
                  gasoline: _find(prices, 'GASOLINE'),
                  lpg: _find(prices, 'LPG'),
                  fetchedAt: stamped.fetchedAt,
                  source: stamped.source,
                  region: region,
                ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.04, end: 0),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Row(
                  children: [
                    Text(
                      'Pompa fiyatları',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const Spacer(),
                    Text(
                      RelativeTime.format(stamped.fetchedAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              ..._orderedPrices(prices).asMap().entries.map((e) {
                final p = e.value;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: _FuelPriceCard(price: p, liters: _liters)
                      .animate(delay: (e.key * 45).ms)
                      .fadeIn()
                      .slideX(begin: 0.03, end: 0),
                );
              }),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: _CalculatorCard(
                  controller: _litersController,
                  prices: prices,
                  liters: _liters,
                  onChanged: () => setState(() {}),
                ),
              ),
              if (info != null && info.stations.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Text(
                    'Yakıt istasyonları',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: FuelStationMap(
                    stations: info.stations,
                    selectedId: _selectedStationId,
                    onSelect: (s) => setState(() => _selectedStationId = s.id),
                  ),
                ),
                const SizedBox(height: 12),
                ...info.stations.map(
                  (s) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: _StationCard(
                      station: s,
                      selected: _selectedStationId == s.id,
                      onTap: () => setState(() {
                        _selectedStationId = _selectedStationId == s.id ? null : s.id;
                      }),
                    ),
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 88),
                child: _FooterPanel(
                  info: info,
                  onOpenSource: (url) => LauncherUtils.openUrlExternal(context, url),
                ),
              ),
            ]),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Akaryakıt fiyatları yüklenemedi: $e'),
                const SizedBox(height: 16),
                FilledButton(onPressed: _refresh, child: const Text('Yeniden dene')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<FuelPrice> _orderedPrices(List<FuelPrice> prices) {
    const order = ['DIESEL', 'GASOLINE', 'LPG'];
    final sorted = <FuelPrice>[];
    for (final code in order) {
      final p = _find(prices, code);
      if (p != null) sorted.add(p);
    }
    for (final p in prices) {
      if (!sorted.contains(p)) sorted.add(p);
    }
    return sorted;
  }

  void _sharePrices(List<FuelPrice> prices, DateTime fetchedAt, String region) {
    final lines = prices.map((p) => '${p.name}: ₺${p.price.toStringAsFixed(2)} / L').join('\n');
    final text = 'Düziçi Akaryakıt ($region)\n$lines\n\n${RelativeTime.format(fetchedAt)} — Hepsi Düziçi';
    LauncherUtils.shareText(text, subject: 'Akaryakıt fiyatları');
  }
}

class _HeroPriceCard extends StatelessWidget {
  const _HeroPriceCard({
    required this.diesel,
    required this.gasoline,
    required this.lpg,
    required this.fetchedAt,
    required this.source,
    required this.region,
  });

  final FuelPrice? diesel;
  final FuelPrice? gasoline;
  final FuelPrice? lpg;
  final DateTime fetchedAt;
  final String? source;
  final String region;

  @override
  Widget build(BuildContext context) {
    final main = diesel ?? gasoline ?? lpg;
    final priceStr = main != null ? '₺${main.price.toStringAsFixed(2)}' : '—';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE64A19), Color(0xFFFF7043)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _fuelColor.withValues(alpha: 0.35),
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
                child: const Icon(Icons.local_gas_station_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      region,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      main?.name ?? 'Akaryakıt',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              if (source != null && source!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _sourceLabel(source!),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            priceStr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          Text(
            'Litre başına · ${RelativeTime.format(fetchedAt)}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
          ),
          if (gasoline != null && lpg != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _MiniChip(label: 'Benzin', value: gasoline!.price),
                const SizedBox(width: 8),
                _MiniChip(label: 'LPG', value: lpg!.price),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _sourceLabel(String source) {
    if (source.contains('doviz')) return 'doviz.com';
    if (source.contains('goyakit')) return 'goyakit';
    if (source.contains('akaryakit')) return 'akaryakit.org';
    if (source == 'admin') return 'Yerel';
    if (source == 'fallback') return 'Tahmini';
    return source;
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label ₺${value.toStringAsFixed(2)}',
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _FuelPriceCard extends StatelessWidget {
  const _FuelPriceCard({required this.price, required this.liters});

  final FuelPrice price;
  final double liters;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(price.code);
    final total = price.price * liters;

    return PrimaryCard(
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(_iconFor(price.code), color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(price.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                const SizedBox(height: 2),
                Text(
                  '${liters.toStringAsFixed(0)} L depo ≈ ₺${total.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₺${price.price.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color),
              ),
              if (price.hasChange) _ChangeBadge(change: price.change!),
              Text(price.unit, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Theme.of(context).textTheme.bodySmall?.color)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChangeBadge extends StatelessWidget {
  const _ChangeBadge({required this.change});

  final double change;

  @override
  Widget build(BuildContext context) {
    final up = change > 0;
    final color = up ? const Color(0xFFE53935) : const Color(0xFF43A047);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(up ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded, size: 18, color: color),
          Text(
            '₺${change.abs().toStringAsFixed(2)}',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}

class _CalculatorCard extends StatelessWidget {
  const _CalculatorCard({
    required this.controller,
    required this.prices,
    required this.liters,
    required this.onChanged,
  });

  final TextEditingController controller;
  final List<FuelPrice> prices;
  final double liters;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _fuelColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Depo maliyeti hesapla',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              labelText: 'Litre',
              suffixText: 'L',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [20, 40, 50, 60].map((l) {
              return ActionChip(
                label: Text('$l L'),
                onPressed: () {
                  controller.text = '$l';
                  onChanged();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          ...prices.map((p) {
            final total = p.price * liters;
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Expanded(child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                  Text('₺${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StationCard extends StatelessWidget {
  const _StationCard({
    required this.station,
    required this.selected,
    required this.onTap,
  });

  final FuelStationItem station;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PrimaryCard(
      margin: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _fuelColor.withValues(alpha: selected ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: selected ? Border.all(color: _fuelColor, width: 2) : null,
                ),
                child: const Icon(Icons.local_gas_station_rounded, color: Color(0xFFE64A19)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(station.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(
                      station.brand,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFE65100)),
                    ),
                  ],
                ),
              ),
              if (station.hours != null)
                Text(
                  station.hours!,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodySmall?.color),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(station.address, style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color)),
          if (selected) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => station.hasCoords
                      ? LauncherUtils.openMapsWithLatLng(context, station.lat!, station.lng!)
                      : LauncherUtils.openMapsWithAddress(context, station.address),
                  icon: const Icon(Icons.map_rounded, size: 18),
                  label: const Text('Haritada'),
                ),
                OutlinedButton.icon(
                  onPressed: () => LauncherUtils.openMapsDirections(context, station.address),
                  icon: const Icon(Icons.directions_rounded, size: 18),
                  label: const Text('Yol tarifi'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FooterPanel extends StatelessWidget {
  const _FooterPanel({required this.info, required this.onOpenSource});

  final FuelInfo? info;
  final void Function(String url) onOpenSource;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall?.color;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bilgi', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            info?.disclaimer ??
                'Fiyatlar bilgilendirme amaçlıdır. İstasyonlar arasında küçük farklılıklar olabilir.',
            style: TextStyle(fontSize: 13, color: muted, height: 1.4),
          ),
          if (info != null && info!.tips.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...info!.tips.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: muted)),
                    Expanded(child: Text(t, style: TextStyle(fontSize: 12, color: muted, height: 1.3))),
                  ],
                ),
              ),
            ),
          ],
          if (info != null && info!.sourceLinks.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Kaynaklar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: muted)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: info!.sourceLinks
                  .map(
                    (l) => ActionChip(
                      label: Text(l.name),
                      onPressed: l.url.isEmpty ? null : () => onOpenSource(l.url),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

Color _colorFor(String code) {
  switch (code.toUpperCase()) {
    case 'GASOLINE':
      return const Color(0xFFF9A825);
    case 'DIESEL':
      return const Color(0xFF546E7A);
    case 'LPG':
      return const Color(0xFF1E88E5);
    default:
      return _fuelColor;
  }
}

IconData _iconFor(String code) {
  switch (code.toUpperCase()) {
    case 'GASOLINE':
      return Icons.local_gas_station_rounded;
    case 'DIESEL':
      return Icons.oil_barrel_rounded;
    case 'LPG':
      return Icons.propane_tank_rounded;
    default:
      return Icons.local_gas_station_rounded;
  }
}
