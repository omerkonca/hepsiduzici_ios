import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/color_utils.dart';
import '../../../core/utils/icon_mapper.dart';
import '../../../core/utils/target_router.dart';
import '../../../data/models/city_content.dart';

class QuickActionsRow extends ConsumerWidget {
  const QuickActionsRow({super.key});

  static const List<QuickActionItem> _defaults = [
    QuickActionItem(id: 'taksi',    icon: 'local_taxi_rounded',        label: 'Taksi',    color: '#E65100', target: 'screen:taxi'),
    QuickActionItem(id: 'ulasim',   icon: 'directions_bus_rounded',    label: 'Ulaşım',   color: '#1B5E20', target: 'screen:transport'),
    QuickActionItem(id: 'belediye', icon: 'account_balance_rounded',   label: 'Belediye', color: '#0D47A1', target: 'screen:municipality'),
    QuickActionItem(id: 'acil',     icon: 'emergency_rounded',         label: 'Acil',     color: '#B71C1C', target: 'screen:emergency'),
    QuickActionItem(id: 'haber',    icon: 'newspaper_rounded',         label: 'Haberler', color: '#4A148C', target: 'screen:news'),
    QuickActionItem(id: 'gezi',     icon: 'explore_rounded',           label: 'Gezi',     color: '#004D40', target: 'explore_nature'),
  ];

  // Alt başlıklar (her id için)
  static const _subtitles = {
    'taksi':    'Çağır & Ulaş',
    'ulasim':   'Sefer & Tarife',
    'belediye': 'Hizmet & İletişim',
    'acil':     '112 · 155 · 110',
    'haber':    'Düziçi & Osmaniye',
    'gezi':     'Doğa · Tarih · Lezzet',
    'eczane':   'Nöbetçi Bul',
    'harita':   'Düziçi Haritası',
    'namaz':    'Günlük Vakitler',
    'finans':   'Döviz & Altın',
    'akaryakit':'Güncel Fiyatlar',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cityContentProvider);
    final List<QuickActionItem> actions = async.maybeWhen(
      data: (c) {
        final active = c.quickActions.where((a) => a.isActive).toList();
        return active.isNotEmpty ? active : _defaults;
      },
      orElse: () => _defaults,
    ) ?? _defaults;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _buildGrid(context, actions),
    );
  }

  Widget _buildGrid(BuildContext context, List<QuickActionItem> actions) {
    // 3 kolonlu grid
    final rows = <Widget>[];
    const cols = 3;
    final rowCount = (actions.length / cols).ceil();

    for (int r = 0; r < rowCount; r++) {
      final rowItems = <Widget>[];
      for (int c = 0; c < cols; c++) {
        final idx = r * cols + c;
        if (idx < actions.length) {
          final item = actions[idx];
          final sub = _subtitles[item.id] ?? '';
          rowItems.add(
            Expanded(
              child: _QuickTile(
                item: item,
                subtitle: sub,
                index: idx,
              ).animate(delay: (idx * 45).ms).fadeIn(duration: 280.ms).slideY(begin: 0.14, end: 0, curve: Curves.easeOutCubic),
            ),
          );
        } else {
          rowItems.add(const Expanded(child: SizedBox.shrink()));
        }
        if (c < cols - 1) rowItems.add(const SizedBox(width: 10));
      }
      rows.add(
        Row(children: rowItems),
      );
      if (r < rowCount - 1) rows.add(const SizedBox(height: 12));
    }

    return Column(children: rows);
  }
}

class _QuickTile extends StatefulWidget {
  const _QuickTile({required this.item, required this.subtitle, required this.index});
  final QuickActionItem item;
  final String subtitle;
  final int index;

  @override
  State<_QuickTile> createState() => _QuickTileState();
}

class _QuickTileState extends State<_QuickTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = hexToColor(widget.item.color, AppColors.primary);
    final light = Color.lerp(base, Colors.white, 0.28)!;
    final icon = IconMapper.fromName(widget.item.icon);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        TargetRouter.handle(context, widget.item.target);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Renkli kare ikon
            Container(
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [base.withValues(alpha: 0.70), base.withValues(alpha: 0.45)]
                      : [light, base],
                ),
                boxShadow: _pressed
                    ? []
                    : [
                        BoxShadow(
                          color: base.withValues(alpha: isDark ? 0.30 : 0.28),
                          blurRadius: 12,
                          spreadRadius: -3,
                          offset: const Offset(0, 5),
                        ),
                      ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Dekoratif daire sağ üst
                  Positioned(
                    top: -8,
                    right: -8,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Başlık (dışarıda)
            Text(
              widget.item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF1A1D2E),
                letterSpacing: -0.1,
              ),
            ),
            if (widget.subtitle.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                widget.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.45)
                      : const Color(0xFF78909C),
                  letterSpacing: -0.05,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
