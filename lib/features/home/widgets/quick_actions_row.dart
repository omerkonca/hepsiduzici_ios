import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/icon_mapper.dart';
import '../../../core/utils/target_router.dart';
import '../../../data/models/city_content.dart';

final _quickActionEntryDuration = 320.ms;
const _quickActionEntryCurve = Curves.easeOutCubic;

class QuickActionsRow extends ConsumerWidget {
  const QuickActionsRow({super.key});

  static const List<QuickActionItem> _defaults = [
    QuickActionItem(
      id: 'taksi',
      icon: 'local_taxi_rounded',
      label: 'Taksi',
      subtitle: 'Çağır & ulaş',
      color: '#E65100',
      target: 'screen:taxi',
    ),
    QuickActionItem(
      id: 'ulasim',
      icon: 'directions_bus_rounded',
      label: 'Ulaşım',
      subtitle: 'Sefer & tarife',
      color: '#1B5E20',
      target: 'screen:transport',
    ),
    QuickActionItem(
      id: 'belediye',
      icon: 'account_balance_rounded',
      label: 'Belediye',
      subtitle: 'Hizmet & iletişim',
      color: '#0D47A1',
      target: 'screen:municipality',
    ),
    QuickActionItem(
      id: 'ihbar',
      icon: 'campaign_rounded',
      label: 'İhbar',
      subtitle: 'Sorun & öneri bildir',
      color: '#E65100',
      target: 'screen:citizen_report',
    ),
    QuickActionItem(
      id: 'haber',
      icon: 'newspaper_rounded',
      label: 'Haberler',
      subtitle: 'Düziçi & Osmaniye',
      color: '#4A148C',
      target: 'screen:news',
    ),
    QuickActionItem(
      id: 'gezi',
      icon: 'explore_rounded',
      label: 'Gezi',
      subtitle: 'Doğa · tarih · lezzet',
      color: '#004D40',
      target: 'explore_nature',
    ),
    QuickActionItem(
      id: 'acil',
      icon: 'emergency_rounded',
      label: 'Acil',
      subtitle: '112 · 155 · 110',
      color: '#B71C1C',
      target: 'screen:emergency',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cityContentProvider);
    final List<QuickActionItem> actions = async.maybeWhen(
      data: (c) {
        final active = c.quickActions.where((a) => a.isActive && a.label.isNotEmpty).toList();
        return active.isNotEmpty ? active : _defaults;
      },
      orElse: () => _defaults,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: actions.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.35,
        ),
        itemBuilder: (context, index) {
          final item = actions[index];
          return _QuickActionCard(item: item, index: index)
              .animate(delay: (index * 50).ms)
              .fadeIn(duration: _quickActionEntryDuration, curve: _quickActionEntryCurve)
              .slideY(
                begin: 0.08,
                end: 0,
                duration: _quickActionEntryDuration,
                curve: _quickActionEntryCurve,
              );
        },
      ),
    );
  }
}

class _QuickActionCard extends StatefulWidget {
  const _QuickActionCard({required this.item, required this.index});

  final QuickActionItem item;
  final int index;

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFFE3AF4C) : AppColors.primaryDark;
    final accentSoft = isDark ? const Color(0xFFB8872F) : const Color(0xFF9B7A2F);
    final icon = IconMapper.fromName(widget.item.icon);
    final subtitle = (widget.item.subtitle?.isNotEmpty == true) ? widget.item.subtitle! : '';

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        TargetRouter.handle(context, widget.item.target);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? AppColors.darkCardBorder
                  : accent.withValues(alpha: 0.18),
            ),
            boxShadow: _pressed
                ? []
                : [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.35)
                          : accent.withValues(alpha: 0.11),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: isDark ? 0.26 : 0.18),
                      accentSoft.withValues(alpha: isDark ? 0.18 : 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: accent.withValues(alpha: isDark ? 0.34 : 0.22),
                  ),
                ),
                child: Icon(icon, color: accent, size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkText : AppColors.textDark,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: accent.withValues(alpha: 0.62),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
