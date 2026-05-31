import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/utils/launcher_utils.dart';
import '../../core/utils/relative_time.dart';
import '../../core/widgets/primary_card.dart';
import '../../core/widgets/service_page_layout.dart';
import '../../data/models/road_closure.dart';
import 'widgets/road_closure_map.dart';

class ClosedRoadsScreen extends ConsumerStatefulWidget {
  const ClosedRoadsScreen({super.key});

  @override
  ConsumerState<ClosedRoadsScreen> createState() => _ClosedRoadsScreenState();
}

class _ClosedRoadsScreenState extends ConsumerState<ClosedRoadsScreen> with WidgetsBindingObserver {
  String? _selectedId;
  String? _expandedId;
  bool _activeOnly = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pollTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (mounted) _forceRefresh();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _forceRefresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _forceRefresh();
  }

  Future<void> _forceRefresh() async {
    await ref.read(roadClosureServiceProvider).getStampedRoadClosures(forceRefresh: true);
    if (mounted) ref.invalidate(stampedRoadClosuresProvider);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(autoRefreshProvider);
    final async = ref.watch(stampedRoadClosuresProvider);

    return async.when(
      data: (stamped) {
        var list = stamped.data;
        if (_activeOnly) {
          list = list.where((c) => c.isActive).toList();
        }

        return ServicePageLayout(
          title: 'Kapalı Yollar',
          subtitle: 'Otomatik güncellenir: Düziçi Belediyesi duyuru ve yol çalışması haberleri. Yol açılınca listeden kalkar.',
          icon: 'block',
          color: const Color(0xFFE53935),
          onRefresh: () async => _forceRefresh(),
          isEmpty: list.isEmpty,
          emptyMessage: _activeOnly
              ? 'Şu an aktif kapalı yol kaydı yok.'
              : 'Kayıtlı yol kapanması bulunmuyor.',
          child: SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _MunicipalityBanner(
                  count: stamped.data.where((c) => c.isMunicipalityAnnouncement).length,
                  onOpenAll: () => LauncherUtils.openUrlExternal(
                    context,
                    'https://www.duzici.bel.tr/duyurular',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Sadece aktif'),
                      selected: _activeOnly,
                      onSelected: (v) => setState(() {
                        _activeOnly = v;
                        _selectedId = null;
                        _expandedId = null;
                      }),
                    ),
                    Flexible(
                      child: Text(
                        RelativeTime.format(stamped.fetchedAt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: RoadClosureMap(
                  closures: stamped.data,
                  selectedId: _selectedId,
                  onSelect: (c) => setState(() => _selectedId = c.id),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: const [
                    _LegendDot(color: Color(0xFFE53935), label: 'Tam kapalı'),
                    _LegendDot(color: Color(0xFFF5A623), label: 'Kısıtlı'),
                    _LegendDot(color: Color(0xFF43A047), label: 'Bakım bitti'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...list.asMap().entries.map((e) {
                final c = e.value;
                final selected = c.id == _selectedId;
                final expanded = _expandedId == c.id;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  child: _RoadClosureCard(
                    closure: c,
                    selected: selected,
                    expanded: expanded,
                    onTap: () {
                      setState(() {
                        _selectedId = c.id;
                        _expandedId = expanded ? null : c.id;
                      });
                    },
                  ).animate(delay: (e.key * 40).ms).fadeIn().slideY(begin: 0.04, end: 0),
                );
              }),
            ]),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Hata: $e'))),
    );
  }
}

class _MunicipalityBanner extends StatelessWidget {
  const _MunicipalityBanner({required this.count, required this.onOpenAll});

  final int count;
  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1565C0).withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onOpenAll,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _MunicipalityBadge(compact: false),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      count > 0
                          ? '$count resmî duyuru haritaya işlendi'
                          : 'Tüm duyurular duzici.bel.tr',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Icon(Icons.open_in_new_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _RoadClosureCard extends StatelessWidget {
  const _RoadClosureCard({
    required this.closure,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  final RoadClosure closure;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = closure.isActive ? const Color(0xFFE53935) : const Color(0xFF43A047);
    final severityLabel = switch (closure.severity) {
      'full' => 'Tam kapalı',
      'maintenance' => 'Bakım',
      _ => 'Kısıtlı geçiş',
    };

    return Container(
      decoration: selected
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: accent, width: 2),
            )
          : null,
      child: PrimaryCard(
        onTap: onTap,
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.alt_route_rounded, color: accent, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        closure.title,
                        maxLines: expanded ? 3 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: -0.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _StatusChip(label: closure.status, active: closure.isActive),
                          Text(
                            closure.roadCode,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                          if (closure.isMunicipalityAnnouncement)
                            const _MunicipalityBadge(compact: true),
                          _SeverityChip(label: severityLabel, color: accent),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 220),
                  turns: expanded ? 0.5 : 0,
                  child: Icon(
                    Icons.expand_more_rounded,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              closure.subtitle,
              maxLines: expanded ? null : 2,
              overflow: expanded ? null : TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
              ),
            ),
            if (expanded) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              _InfoRow(icon: Icons.info_outline_rounded, text: 'Neden: ${closure.reason}'),
              const SizedBox(height: 6),
              _InfoRow(icon: Icons.signpost_rounded, text: 'Alternatif: ${closure.alternativeRoute}'),
              if (closure.startAt != null) ...[
                const SizedBox(height: 6),
                _InfoRow(
                  icon: Icons.calendar_today_rounded,
                  text: _dateRange(closure.startAt!, closure.endAt),
                ),
              ],
              if (closure.source != null) ...[
                const SizedBox(height: 6),
                _InfoRow(icon: Icons.account_balance_rounded, text: 'Kaynak: ${closure.source}'),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () =>
                        LauncherUtils.openMapsWithLatLng(context, closure.lat, closure.lng),
                    icon: const Icon(Icons.map_rounded, size: 18),
                    label: const Text('Haritada'),
                  ),
                  FilledButton.icon(
                    onPressed: () => LauncherUtils.openMapsDirections(context, closure.address),
                    icon: const Icon(Icons.navigation_rounded, size: 18),
                    label: const Text('Yol tarifi'),
                  ),
                ],
              ),
              if (closure.announcementUrl != null && closure.announcementUrl!.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        LauncherUtils.openUrlExternal(context, closure.announcementUrl!),
                    icon: const Icon(Icons.campaign_rounded, size: 18),
                    label: const Text('Belediye duyurusunu oku'),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  static String _dateRange(String start, String? end) {
    final fmt = DateFormat('d MMM yyyy', 'tr_TR');
    try {
      final s = fmt.format(DateTime.parse(start));
      if (end == null || end.isEmpty) return 'Başlangıç: $s';
      final e = fmt.format(DateTime.parse(end));
      return 'Süre: $s – $e';
    } catch (_) {
      return end == null ? 'Başlangıç: $start' : '$start – $end';
    }
  }
}

class _MunicipalityBadge extends StatelessWidget {
  const _MunicipalityBadge({this.compact = true});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0).withValues(alpha: compact ? 0.12 : 1),
        borderRadius: BorderRadius.circular(compact ? 4 : 6),
        border: compact ? Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.35)) : null,
      ),
      child: Text(
        compact ? 'BELEDİYE' : 'BELEDİYE DUYURUSU',
        style: TextStyle(
          color: compact ? const Color(0xFF1565C0) : Colors.white,
          fontSize: compact ? 8 : 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _SeverityChip extends StatelessWidget {
  const _SeverityChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.active});
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFFFBAE3C).withValues(alpha: 0.18)
            : const Color(0xFF43A047).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: active ? const Color(0xFFD77700) : const Color(0xFF2E7D32),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
