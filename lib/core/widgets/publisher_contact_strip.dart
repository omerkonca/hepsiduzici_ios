import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../theme/premium_city_theme.dart';
import '../utils/launcher_utils.dart';
import '../utils/target_router.dart';
import 'app_pressable.dart';

/// Google Play Haber politikası: kolay bulunur yayıncı iletişimi.
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
    return Padding(
      padding: margin,
      child: AppPressable(
        onTap: () => TargetRouter.handle(context, 'screen:contact'),
        borderRadius: BorderRadius.circular(compact ? 14 : 18),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: compact ? 10 : 14,
          ),
          decoration: BoxDecoration(
            gradient: PremiumCityTheme.navyGradient,
            borderRadius: BorderRadius.circular(compact ? 14 : 18),
            boxShadow: PremiumCityTheme.softShadow(
              color: PremiumCityTheme.navy,
              alpha: 0.14,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.support_agent_rounded,
                color: Colors.white.withValues(alpha: 0.95),
                size: compact ? 22 : 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bize Ulaşın',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: compact ? 11 : 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _contactLine(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 13 : 14.5,
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'E-posta gönder',
                onPressed: () => LauncherUtils.openUrlExternal(
                  context,
                  'mailto:${AppConfig.contactEmail}',
                ),
                icon: const Icon(Icons.email_rounded, color: Colors.white),
                visualDensity: VisualDensity.compact,
              ),
              if (AppConfig.contactPhone.isNotEmpty)
                IconButton(
                  tooltip: 'Telefon',
                  onPressed: () =>
                      LauncherUtils.callPhone(context, AppConfig.contactPhone),
                  icon: const Icon(Icons.phone_rounded, color: Colors.white),
                  visualDensity: VisualDensity.compact,
                ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.85),
                size: compact ? 20 : 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _contactLine() {
    if (AppConfig.contactPhone.isNotEmpty) {
      return '${AppConfig.contactEmail} · ${AppConfig.contactPhone}';
    }
    return AppConfig.contactEmail;
  }
}
