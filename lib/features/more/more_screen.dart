import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/premium_city_theme.dart';
import '../../core/utils/color_utils.dart';
import '../../core/utils/icon_mapper.dart';
import '../../core/utils/target_router.dart';
import '../../core/widgets/app_pressable.dart';
import '../../data/models/city_content.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  static const List<MoreSectionItem> _defaults = [
    MoreSectionItem(
      title: 'Hızlı Erişim',
      tiles: [
        MoreTileItem(
          icon: 'article_rounded',
          title: 'Tüm Haberler',
          subtitle: 'Detaylı haber akışı',
          color: '#448AFF',
          target: 'screen:news',
        ),
        MoreTileItem(
          icon: 'favorite_rounded',
          title: 'Favorilerim',
          subtitle: 'Kaydedilen haber, etkinlik ve mekanlar',
          color: '#E91E63',
          target: 'screen:favorites',
        ),
        MoreTileItem(
          icon: 'calendar_month_rounded',
          title: 'Etkinlik Takvimim',
          subtitle: 'Favori ve hatırlatıcılar',
          color: '#FF5722',
          target: 'screen:calendar',
        ),
        MoreTileItem(
          icon: 'local_pharmacy_rounded',
          title: 'Nöbetçi Eczane',
          subtitle: 'Tüm eczane listesi',
          color: '#009688',
          target: 'screen:pharmacy',
        ),
        MoreTileItem(
          icon: 'mosque_rounded',
          title: 'Namaz Vakitleri',
          subtitle: 'Günün tüm vakitleri',
          color: '#43A047',
          target: 'screen:prayer',
        ),
        MoreTileItem(
          icon: 'wb_sunny_rounded',
          title: 'Hava Durumu',
          subtitle: 'Anlık hava ve 5 günlük tahmin',
          color: '#039BE5',
          target: 'screen:weather',
        ),
      ],
    ),
    MoreSectionItem(
      title: 'Araçlar',
      tiles: [
        MoreTileItem(
          icon: 'monetization_on_rounded',
          title: 'Piyasa Verileri',
          subtitle: 'Döviz, altın ve yerel fiyatlar',
          color: '#FB8C00',
          target: '',
        ),
        MoreTileItem(
          icon: 'map_rounded',
          title: 'Ulaşım ve Yol',
          subtitle: 'Durak, rota ve yol bilgileri',
          color: '#3F51B5',
          target: '',
        ),
      ],
    ),
    MoreSectionItem(
      title: 'Destek ve Ayarlar',
      tiles: [
        MoreTileItem(
          icon: 'campaign_rounded',
          title: 'İhbar ve Öneri',
          subtitle: 'Sorun, tavsiye paylaş — fotoğraf ekle',
          color: '#E65100',
          target: 'screen:citizen_report',
        ),
        MoreTileItem(
          icon: 'support_agent_rounded',
          title: 'Bize Ulaşın',
          subtitle: 'E-posta ve yayıncı bilgileri',
          color: '#9C27B0',
          target: 'screen:contact',
        ),
        MoreTileItem(
          icon: 'newspaper_rounded',
          title: 'Haber Kaynakları',
          subtitle: 'İçerik sağlayıcı yayıncılar',
          color: '#1565C0',
          target: 'screen:news_sources',
        ),
        MoreTileItem(
          icon: 'settings_rounded',
          title: 'Uygulama Ayarları',
          subtitle: 'Bildirim ve uyarı seçenekleri',
          color: '#616161',
          target: 'screen:notification_settings',
        ),
        MoreTileItem(
          icon: 'admin_panel_settings_rounded',
          title: 'Yayıncı Paneli',
          subtitle: 'Arka plan görselini güncelleyin',
          color: '#E53935',
          target: 'screen:admin_panel',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cityContentProvider);
    final sections = async.maybeWhen(
      data: (content) =>
          content.moreSections.isNotEmpty ? content.moreSections : _defaults,
      orElse: () => _defaults,
    );
    final branding = ref.watch(brandingProvider);

    return Container(
      color: PremiumCityTheme.canvas,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: _ProfileHero(branding: branding)
                .animate()
                .fadeIn(duration: 420.ms)
                .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
          ),
          SliverToBoxAdapter(
            child: _ProfileActions()
                .animate(delay: 80.ms)
                .fadeIn(duration: 420.ms)
                .slideY(begin: 0.04, end: 0),
          ),
          for (var sectionIndex = 0;
              sectionIndex < sections.length;
              sectionIndex++) ...[
            SliverToBoxAdapter(
              child: _MoreSectionHeader(title: sections[sectionIndex].title)
                  .animate(delay: (130 + sectionIndex * 45).ms)
                  .fadeIn(duration: 360.ms),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final tile = sections[sectionIndex].tiles[index];
                    return _MoreTile(
                      icon: IconMapper.fromName(tile.icon),
                      title: tile.title,
                      subtitle: tile.subtitle,
                      color: hexToColor(tile.color, AppColors.primary),
                      featured: sectionIndex == 0 && index == 0,
                      onTap: () => TargetRouter.handle(context, tile.target),
                    )
                        .animate(delay: (150 + index * 30).ms)
                        .fadeIn(duration: 360.ms)
                        .slideX(begin: 0.025, end: 0);
                  },
                  childCount: sections[sectionIndex].tiles.length,
                ),
              ),
            ),
          ],
          SliverToBoxAdapter(
            child: _Footer(
              appName: branding?.appName,
              onContactTap: () => TargetRouter.handle(context, 'screen:contact'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.branding});

  final BrandingInfo? branding;

  @override
  Widget build(BuildContext context) {
    final appName = branding?.appName?.isNotEmpty == true
        ? branding!.appName!
        : 'Hepsi Düziçi';
    final tagline = branding?.tagline?.isNotEmpty == true
        ? branding!.tagline!
        : 'Düziçi’nin akıllı şehir profili';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Container(
        height: 238,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: PremiumCityTheme.softShadow(
            color: PremiumCityTheme.navy,
            alpha: 0.20,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/karasu_selalesi.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: PremiumCityTheme.navyGradient,
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    PremiumCityTheme.navy.withValues(alpha: 0.12),
                    PremiumCityTheme.navy.withValues(alpha: 0.48),
                    PremiumCityTheme.navy.withValues(alpha: 0.92),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  _GlassPill(
                    icon: Icons.verified_rounded,
                    text: 'ŞEHİR PROFİLİ',
                    color: const Color(0xFF35D072),
                  ),
                  const Spacer(),
                  _CircleGlassButton(
                    icon: Icons.settings_rounded,
                    onTap: () => TargetRouter.handle(
                      context,
                      'screen:notification_settings',
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: PremiumCityTheme.goldGradient,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.72),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  PremiumCityTheme.gold.withValues(alpha: 0.32),
                              blurRadius: 22,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Misafir Kullanıcı',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  height: 1,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                tagline,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.78),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _HeroMetric(value: '24/7', label: 'Şehir akışı'),
                      const SizedBox(width: 8),
                      _HeroMetric(value: '19°', label: 'Hava'),
                      const SizedBox(width: 8),
                      _HeroMetric(value: appName, label: 'Uygulama'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.24),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 15),
              const SizedBox(width: 7),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleGlassButton extends StatelessWidget {
  const _CircleGlassButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: Icon(icon, color: Colors.white, size: 21),
          ),
        ),
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.66),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
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

class _ProfileActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Row(
        children: [
          _ProfileActionCard(
            icon: Icons.login_rounded,
            title: 'Giriş Yap',
            subtitle: 'Profilini bağla',
            color: PremiumCityTheme.gold,
            onTap: () {},
          ),
          const SizedBox(width: 10),
          _ProfileActionCard(
            icon: Icons.favorite_rounded,
            title: 'Favorilerim',
            subtitle: 'Kayıtlı içerikler',
            color: const Color(0xFFE84B5F),
            onTap: () => TargetRouter.handle(context, 'screen:favorites'),
          ),
          const SizedBox(width: 10),
          _ProfileActionCard(
            icon: Icons.notifications_active_rounded,
            title: 'Uyarılar',
            subtitle: 'Bildirim ayarları',
            color: const Color(0xFF1686C8),
            onTap: () =>
                TargetRouter.handle(context, 'screen:notification_settings'),
          ),
        ],
      ),
    );
  }
}

class _ProfileActionCard extends StatelessWidget {
  const _ProfileActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppPressable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 86,
          padding: const EdgeInsets.all(11),
          decoration: PremiumCityTheme.card(radius: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PremiumCityTheme.ink,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PremiumCityTheme.muted,
                  fontSize: 10.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreSectionHeader extends StatelessWidget {
  const _MoreSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 24,
            decoration: BoxDecoration(
              gradient: PremiumCityTheme.goldGradient,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: PremiumCityTheme.ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.featured,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool featured;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppPressable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(featured ? 28 : 22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          padding: EdgeInsets.all(featured ? 14 : 12),
          decoration: featured
              ? BoxDecoration(
                  gradient: PremiumCityTheme.navyGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: PremiumCityTheme.softShadow(
                    color: PremiumCityTheme.navy,
                    alpha: 0.16,
                  ),
                )
              : PremiumCityTheme.card(radius: 22),
          child: Row(
            children: [
              Container(
                width: featured ? 58 : 50,
                height: featured ? 58 : 50,
                decoration: BoxDecoration(
                  gradient: featured ? PremiumCityTheme.goldGradient : null,
                  color: featured ? null : color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(featured ? 20 : 17),
                  boxShadow: featured
                      ? [
                          BoxShadow(
                            color:
                                PremiumCityTheme.gold.withValues(alpha: 0.26),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  icon,
                  color: featured ? Colors.white : color,
                  size: featured ? 27 : 23,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: featured ? Colors.white : PremiumCityTheme.ink,
                        fontSize: featured ? 16.5 : 15,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: featured
                            ? Colors.white.withValues(alpha: 0.68)
                            : PremiumCityTheme.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: featured
                      ? Colors.white.withValues(alpha: 0.13)
                      : const Color(0xFFF6F8FB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: featured
                        ? Colors.white.withValues(alpha: 0.13)
                        : const Color(0xFFE8EDF3),
                  ),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: featured ? Colors.white : PremiumCityTheme.muted,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({this.appName, this.onContactTap});

  final String? appName;
  final VoidCallback? onContactTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 24, 14, 116),
      child: Column(
        children: [
          AppPressable(
            onTap: onContactTap,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: PremiumCityTheme.navyGradient,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Row(
                children: [
                  Icon(Icons.support_agent_rounded, color: Colors.white, size: 26),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bize Ulaşın',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'hepsiduzici@gmail.com',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: Colors.white),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: PremiumCityTheme.card(radius: 26),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: PremiumCityTheme.goldGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appName ?? 'Hepsi Düziçi',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: PremiumCityTheme.ink,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Sürüm 1.0.1',
                        style: TextStyle(
                          color: PremiumCityTheme.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
