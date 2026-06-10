import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/premium_city_theme.dart';
import '../../core/utils/launcher_utils.dart';
import '../../core/utils/target_router.dart';
import '../../core/widgets/app_pressable.dart';

/// Google Play Haber politikası: kolay bulunur iletişim sayfası.
class ContactScreen extends ConsumerWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: PremiumCityTheme.canvas,
      appBar: AppBar(
        title: const Text('Bize Ulaşın'),
        backgroundColor: PremiumCityTheme.canvas,
        foregroundColor: PremiumCityTheme.ink,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _HeroCard(),
          const SizedBox(height: 16),
          _SectionTitle(title: 'İletişim Bilgileri'),
          const SizedBox(height: 10),
          _InfoTile(
            icon: Icons.person_rounded,
            label: 'Yayıncı / Geliştirici',
            value: AppConfig.publisherName,
          ),
          _InfoTile(
            icon: Icons.email_rounded,
            label: 'E-posta',
            value: AppConfig.contactEmail,
            onTap: () => LauncherUtils.openUrlExternal(
              context,
              'mailto:${AppConfig.contactEmail}',
            ),
          ),
          if (AppConfig.contactPhone.isNotEmpty)
            _InfoTile(
              icon: Icons.phone_rounded,
              label: 'Telefon',
              value: AppConfig.contactPhone,
              onTap: () => LauncherUtils.callPhone(
                context,
                AppConfig.contactPhone,
              ),
            ),
          _InfoTile(
            icon: Icons.language_rounded,
            label: 'Web sitesi',
            value: AppConfig.contactPageUrl,
            onTap: () => LauncherUtils.openUrlExternal(
              context,
              AppConfig.contactPageUrl,
            ),
          ),
          _InfoTile(
            icon: Icons.location_on_rounded,
            label: 'Konum',
            value: 'Düziçi, Osmaniye, Türkiye',
          ),
          const SizedBox(height: 20),
          _SectionTitle(title: 'Uygulama Hakkında'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: PremiumCityTheme.card(radius: 20),
            child: const Text(
              'Hepsi Düziçi, Düziçi ve Osmaniye bölgesine ait haberleri, '
              'etkinlikleri ve şehir hizmetlerini tek uygulamada sunan yerel bir '
              'haber ve şehir rehberi uygulamasıdır. Haber içerikleri bağımsız '
              'yayıncılardan toplanır; her makalenin kaynağı haber detayında '
              'gösterilir.',
              style: TextStyle(
                color: PremiumCityTheme.ink,
                fontSize: 14,
                height: 1.55,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ActionButton(
            icon: Icons.article_rounded,
            title: 'Haber Kaynakları',
            subtitle: 'İçerik sağlayıcı yayıncılar',
            onTap: () => TargetRouter.handle(context, 'screen:news_sources'),
          ),
          const SizedBox(height: 10),
          _ActionButton(
            icon: Icons.privacy_tip_rounded,
            title: 'Gizlilik Politikası',
            subtitle: 'Veri kullanımı ve haklarınız',
            onTap: () => LauncherUtils.openUrlExternal(
              context,
              AppConfig.privacyPolicyUrl,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: PremiumCityTheme.navyGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: PremiumCityTheme.softShadow(
          color: PremiumCityTheme.navy,
          alpha: 0.18,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: PremiumCityTheme.goldGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Bize Ulaşın',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Geri bildirim, iş birliği, içerik düzeltme veya gizlilik '
            'talepleriniz için aşağıdaki iletişim kanallarını kullanabilirsiniz.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 13.5,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: PremiumCityTheme.ink,
        fontSize: 17,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: PremiumCityTheme.card(radius: 18),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: PremiumCityTheme.gold.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: PremiumCityTheme.gold, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: PremiumCityTheme.muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: PremiumCityTheme.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(
              Icons.chevron_right_rounded,
              color: PremiumCityTheme.muted,
            ),
        ],
      ),
    );

    if (onTap == null) return child;
    return AppPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: child,
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: PremiumCityTheme.card(radius: 18),
        child: Row(
          children: [
            Icon(icon, color: PremiumCityTheme.navy, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: PremiumCityTheme.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: PremiumCityTheme.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: PremiumCityTheme.muted),
          ],
        ),
      ),
    );
  }
}
