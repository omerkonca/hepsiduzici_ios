import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/color_utils.dart';
import '../../../core/utils/icon_mapper.dart';
import '../../../core/utils/target_router.dart';
import '../../../data/models/city_content.dart';

/// Backend'den gelen `home.quickActions` listesini render eder.
/// Veri yoksa varsayilan butonlari gosterir (geriye uyum).
class QuickActionsRow extends ConsumerWidget {
  const QuickActionsRow({super.key});

  static const List<QuickActionItem> _defaults = [
    QuickActionItem(id: 'taksi', icon: 'local_taxi_rounded', label: 'Taksi', color: '#FFA726', target: 'screen:taxi'),
    QuickActionItem(id: 'acil', icon: 'emergency_rounded', label: 'Acil', color: '#E53935', target: 'screen:emergency'),
    QuickActionItem(id: 'belediye', icon: 'account_balance_rounded', label: 'Belediye', color: '#1976D2', target: 'screen:municipality'),
    QuickActionItem(id: 'ulasim', icon: 'bus_alert_rounded', label: 'Ulaşım', color: '#43A047', target: 'screen:transport'),
    QuickActionItem(id: 'harita', icon: 'map_rounded', label: 'Harita', color: '#8E24AA', target: 'url:https://maps.google.com/?q=D%C3%BCzi%C3%A7i'),
  ];

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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final item = actions[index];
          final color = hexToColor(item.color, AppColors.primary);
          final icon = IconMapper.fromName(item.icon);

          return _QuickActionTile(
            label: item.label,
            icon: icon,
            color: color,
            isDark: isDark,
            onTap: () => TargetRouter.handle(context, item.target),
          ).animate(delay: (index * 60).ms)
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic);
        },
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isDark
                      ? color.withValues(alpha: 0.15)
                      : color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? color.withValues(alpha: 0.25)
                        : color.withValues(alpha: 0.18),
                  ),
                ),
                child: Icon(
                  icon,
                  color: isDark
                      ? color.withValues(alpha: 0.9)
                      : color,
                  size: 26,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
