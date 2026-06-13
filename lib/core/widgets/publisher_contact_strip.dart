import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../theme/premium_city_theme.dart';
import '../utils/launcher_utils.dart';
import '../utils/target_router.dart';
import 'app_pressable.dart';

/// Google Play Haber politikası: kolay bulunur yayıncı iletişimi + ihbar.
class PublisherContactStrip extends StatelessWidget {
  const PublisherContactStrip({
    super.key,
    this.compact = false,
    this.margin = const EdgeInsets.fromLTRB(14, 0, 14, 10),
  });

  final bool compact;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(compact ? 20 : 24);

    return Padding(
      padding: margin,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF173A61),
              Color(0xFF0B243F),
              Color(0xFF061522),
            ],
          ),
          borderRadius: radius,
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          boxShadow: PremiumCityTheme.softShadow(
            color: PremiumCityTheme.navy,
            alpha: 0.20,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(compact ? 4 : 5),
          child: Row(
            children: [
              Expanded(
                child: _StripZone(
                  compact: compact,
                  icon: Icons.campaign_rounded,
                  title: compact ? 'İhbar' : 'İhbar ve Öneri',
                  subtitle: compact ? 'Bildir' : 'Sorun & öneri',
                  accentColor: const Color(0xFFFFC857),
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(compact ? 16 : 19),
                  onTap: () =>
                      TargetRouter.handle(context, 'screen:citizen_report'),
                ),
              ),
              SizedBox(width: compact ? 5 : 7),
              Expanded(
                child: _StripZone(
                  compact: compact,
                  icon: Icons.support_agent_rounded,
                  title: 'Bize Ulaşın',
                  subtitle: AppConfig.contactEmail,
                  accentColor: const Color(0xFF6EE7F9),
                  backgroundColor: Colors.black.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(compact ? 16 : 19),
                  onTap: () => TargetRouter.handle(context, 'screen:contact'),
                  trailing:
                      compact ? null : _MailActionButton(compact: compact),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StripZone extends StatelessWidget {
  const _StripZone({
    required this.compact,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.borderRadius,
    required this.accentColor,
    required this.backgroundColor,
    this.trailing,
  });

  final bool compact;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final BorderRadius borderRadius;
  final Color accentColor;
  final Color backgroundColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      borderRadius: borderRadius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: compact ? 52 : 64),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 9 : 13,
              compact ? 8 : 12,
              compact ? 7 : 11,
              compact ? 8 : 12,
            ),
            child: Row(
              children: [
                _IconBadge(
                  icon: icon,
                  color: accentColor,
                  compact: compact,
                ),
                SizedBox(width: compact ? 8 : 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: compact ? 10.5 : 12,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 11.5 : 13.5,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  SizedBox(width: compact ? 2 : 4),
                  trailing!,
                ],
                SizedBox(width: compact ? 2 : 4),
                Container(
                  width: compact ? 20 : 24,
                  height: compact ? 20 : 24,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white.withValues(alpha: 0.72),
                    size: compact ? 16 : 19,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.color,
    required this.compact,
  });

  final IconData icon;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 30.0 : 36.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.34),
            color.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(compact ? 11 : 13),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: compact ? 17 : 20,
      ),
    );
  }
}

class _MailActionButton extends StatelessWidget {
  const _MailActionButton({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'E-posta gönder',
      onPressed: () => LauncherUtils.openUrlExternal(
        context,
        'mailto:${AppConfig.contactEmail}',
      ),
      icon: Icon(
        Icons.email_rounded,
        color: Colors.white.withValues(alpha: 0.94),
        size: compact ? 16 : 18,
      ),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(
        width: compact ? 28 : 32,
        height: compact ? 28 : 32,
      ),
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: Colors.white.withValues(alpha: 0.10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(compact ? 9 : 10),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
      ),
    );
  }
}
