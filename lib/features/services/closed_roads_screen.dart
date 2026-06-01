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
import '../../data/models/stamped_data.dart';
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
          subtitle: '', // Removed generic text-heavy top banner for modern dashboard
          icon: 'block',
          color: const Color(0xFFE53935),
          onRefresh: () async => _forceRefresh(),
          isEmpty: list.isEmpty,
          emptyMessage: _activeOnly
              ? 'Şu an aktif kapalı yol kaydı yok.'
              : 'Kayıtlı yol kapanması bulunmuyor.',
          child: SliverList(
            delegate: SliverChildListDelegate([
              // Sleek, clean screen description
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text(
                  'Düziçi genelinde güncel kapalı ve kısıtlı yollar, yol çalışmaları ve resmi trafik komisyonu kararları.',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              // Premium 3-card Dashboard Overview
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _DashboardOverview(
                  stamped: stamped,
                  onTapAnnouncement: () => LauncherUtils.openUrlExternal(
                    context,
                    'https://www.duzici.bel.tr/duyurular',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Premium iOS-style Segment Selector & Last Refreshed
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _FilterSelector(
                        activeOnly: _activeOnly,
                        onChanged: (v) => setState(() {
                          _activeOnly = v;
                          _selectedId = null;
                          _expandedId = null;
                        }),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Güncelleme',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                            color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                          ),
                        ),
                        Text(
                          RelativeTime.format(stamped.fetchedAt),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Interactive Map with glassmorphic floating legends overlay
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Stack(
                  children: [
                    RoadClosureMap(
                      closures: stamped.data,
                      selectedId: _selectedId,
                      onSelect: (c) => setState(() => _selectedId = c.id),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.black.withValues(alpha: 0.72)
                              : Colors.white.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: const [
                            _LegendDot(color: Color(0xFFE53935), label: 'Tam Kapalı'),
                            _LegendDot(color: Color(0xFFF5A623), label: 'Kısıtlı'),
                            _LegendDot(color: Color(0xFF43A047), label: 'Bakım Bitti'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              
              // Cards List
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
                  ).animate(delay: (e.key * 45).ms).fadeIn().slideY(begin: 0.03, end: 0, curve: Curves.easeOutCubic),
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

class _DashboardOverview extends StatelessWidget {
  const _DashboardOverview({required this.stamped, required this.onTapAnnouncement});

  final Stamped<List<RoadClosure>> stamped;
  final VoidCallback onTapAnnouncement;

  @override
  Widget build(BuildContext context) {
    final totalFull = stamped.data.where((c) => c.isActive && c.severity == 'full').length;
    final totalRestricted = stamped.data.where((c) => c.isActive && c.severity != 'full' && c.severity != 'maintenance').length;
    final totalAnnouncements = stamped.data.where((c) => c.isMunicipalityAnnouncement).length;

    return Row(
      children: [
        _DashboardCard(
          count: totalFull,
          title: 'Tam Kapalı',
          icon: Icons.block_rounded,
          color: const Color(0xFFE53935),
        ),
        const SizedBox(width: 10),
        _DashboardCard(
          count: totalRestricted,
          title: 'Kısıtlı Ulaşım',
          icon: Icons.alt_route_rounded,
          color: const Color(0xFFF5A623),
        ),
        const SizedBox(width: 10),
        _DashboardCard(
          count: totalAnnouncements,
          title: 'Resmî Duyuru',
          icon: Icons.campaign_rounded,
          color: const Color(0xFF1565C0),
          onTap: onTapAnnouncement,
        ),
      ],
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.count,
    required this.title,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final int count;
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.08 : 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: isDark ? 0.15 : 0.1),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: color,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'İncele',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.open_in_new_rounded, size: 8, color: color),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterSelector extends StatelessWidget {
  const _FilterSelector({
    required this.activeOnly,
    required this.onChanged,
  });

  final bool activeOnly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03);
    
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentItem(
              label: 'Aktif Kapanışlar',
              selected: activeOnly,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _SegmentItem(
              label: 'Tüm Kayıtlar',
              selected: !activeOnly,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentItem extends StatelessWidget {
  const _SegmentItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: selected && !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 3,
                    offset: const Offset(0, 1.5),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected
                ? (isDark ? Colors.white : Colors.black87)
                : (isDark ? Colors.white54 : Colors.black54),
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
        const SizedBox(width: 5),
        Text(
          label, 
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 9.5,
          ),
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = closure.isActive ? const Color(0xFFE53935) : const Color(0xFF43A047);
    final severityLabel = switch (closure.severity) {
      'full' => 'Tam Kapalı',
      'maintenance' => 'Yol Çalışması',
      _ => 'Kısıtlı Ulaşım',
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
                // Modern Rounded Icon Container
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accent.withValues(alpha: 0.15)),
                  ),
                  child: Icon(
                    closure.severity == 'full'
                        ? Icons.block_rounded
                        : (closure.severity == 'maintenance'
                            ? Icons.construction_rounded
                            : Icons.alt_route_rounded),
                    color: accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        closure.title,
                        maxLines: expanded ? 3 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Location Text with Icon (instead of generic tag)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.65),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              closure.roadCode,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Expand Arrow
                AnimatedRotation(
                  duration: const Duration(milliseconds: 220),
                  turns: expanded ? 0.5 : 0,
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
            const SizedBox(height: 10),
            
            // Subtitle / Brief Description
            Text(
              closure.subtitle,
              maxLines: expanded ? null : 2,
              overflow: expanded ? null : TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                height: 1.35,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Clean Status Badges Row
            Row(
              children: [
                _StatusChip(label: closure.status, active: closure.isActive),
                const SizedBox(width: 6),
                _SeverityChip(label: severityLabel, color: accent),
                if (closure.isMunicipalityAnnouncement) ...[
                  const SizedBox(width: 6),
                  const _MunicipalityBadge(compact: true),
                ],
              ],
            ),
            
            if (expanded) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              _InfoRow(icon: Icons.info_outline_rounded, text: 'Neden: ${closure.reason}'),
              const SizedBox(height: 8),
              _InfoRow(icon: Icons.signpost_rounded, text: 'Alternatif: ${closure.alternativeRoute}'),
              if (closure.startAt != null) ...[
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.calendar_today_rounded,
                  text: _dateRange(closure.startAt!, closure.endAt),
                ),
              ],
              if (closure.source != null) ...[
                const SizedBox(height: 8),
                _InfoRow(icon: Icons.account_balance_rounded, text: 'Kaynak: ${closure.source}'),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          LauncherUtils.openMapsWithLatLng(context, closure.lat, closure.lng),
                      icon: const Icon(Icons.map_rounded, size: 16),
                      label: const Text('Haritada Göster'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => LauncherUtils.openMapsDirections(context, closure.address),
                      icon: const Icon(Icons.navigation_rounded, size: 16),
                      label: const Text('Yol Tarifi Al'),
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              if (closure.announcementUrl != null && closure.announcementUrl!.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        LauncherUtils.openUrlExternal(context, closure.announcementUrl!),
                    icon: const Icon(Icons.campaign_rounded, size: 16),
                    label: const Text('Belediye Duyurusunu Oku'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
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
          fontSize: 10.5,
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
