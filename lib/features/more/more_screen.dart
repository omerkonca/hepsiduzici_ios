import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/color_utils.dart';
import '../../core/utils/icon_mapper.dart';
import '../../core/utils/target_router.dart';
import '../../data/models/city_content.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  static const List<MoreSectionItem> _defaults = [
    MoreSectionItem(
      title: 'Hızlı Erişim',
      tiles: [
        MoreTileItem(icon: 'article_rounded', title: 'Tüm Haberler', subtitle: 'Detaylı haber akışı', color: '#448AFF', target: 'screen:news'),
        MoreTileItem(icon: 'favorite_rounded', title: 'Favorilerim', subtitle: 'Kaydedilen haber, etkinlik ve mekanlar', color: '#E91E63', target: 'screen:favorites'),
        MoreTileItem(icon: 'calendar_month_rounded', title: 'Etkinlik Takvimim', subtitle: 'Favori ve hatırlatıcılar', color: '#FF5722', target: 'screen:calendar'),
        MoreTileItem(icon: 'local_pharmacy_rounded', title: 'Nöbetçi Eczane', subtitle: 'Tüm eczane listesi', color: '#009688', target: 'screen:pharmacy'),
        MoreTileItem(icon: 'mosque_rounded', title: 'Namaz Vakitleri', subtitle: 'Günün tüm vakitleri', color: '#43A047', target: 'screen:prayer'),
        MoreTileItem(icon: 'wb_sunny_rounded', title: 'Hava Durumu', subtitle: 'Anlık hava ve 5 günlük tahmin', color: '#039BE5', target: 'screen:weather'),
      ],
    ),
    MoreSectionItem(
      title: 'Araçlar',
      tiles: [
        MoreTileItem(icon: 'monetization_on_rounded', title: 'Piyasa Verileri', subtitle: 'Döviz, altın ve yerel fiyatlar', color: '#FB8C00', target: ''),
        MoreTileItem(icon: 'map_rounded', title: 'Ulaşım ve Yol', subtitle: 'Durak, rota ve yol bilgileri', color: '#3F51B5', target: ''),
      ],
    ),
    MoreSectionItem(
      title: 'Destek ve Ayarlar',
      tiles: [
        MoreTileItem(icon: 'support_agent_rounded', title: 'İletişim ve İş Birliği', subtitle: 'Bize ulaşın, sponsor olun', color: '#9C27B0', target: ''),
        MoreTileItem(icon: 'settings_rounded', title: 'Uygulama Ayarları', subtitle: 'Bildirim ve uyarı seçenekleri', color: '#616161', target: 'screen:notification_settings'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cityContentProvider);
    final sections = async.maybeWhen(
      data: (c) => c.moreSections.isNotEmpty ? c.moreSections : _defaults,
      orElse: () => _defaults,
    );
    final branding = ref.watch(brandingProvider);

    final slivers = <Widget>[
      SliverToBoxAdapter(
        child: _ProfileHeader(branding: branding)
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic),
      ),
    ];

    var delay = 100;
    for (var si = 0; si < sections.length; si++) {
      final section = sections[si];
      slivers.add(
        SliverToBoxAdapter(
          child: _SectionTitle(title: section.title)
              .animate(delay: delay.ms)
              .fadeIn(),
        ),
      );
      delay += 40;
      
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final tile = section.tiles[index];
                final widget = _MoreTile(
                  icon: IconMapper.fromName(tile.icon),
                  title: tile.title,
                  subtitle: tile.subtitle,
                  color: hexToColor(tile.color, AppColors.primary),
                  onTap: () => TargetRouter.handle(context, tile.target),
                ).animate(delay: delay.ms).fadeIn().slideX(begin: 0.03, end: 0);
                delay += 40;
                return widget;
              },
              childCount: section.tiles.length,
            ),
          ),
        ),
      );
    }
    slivers.add(SliverToBoxAdapter(child: _Footer(appName: branding?.appName)));

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: slivers,
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.branding});
  final BrandingInfo? branding;

  @override
  Widget build(BuildContext context) {
    final tagline = branding?.tagline?.isNotEmpty == true
        ? branding!.tagline!
        : 'Düziçi\'nin akıllı şehir rehberi';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark 
              ? [const Color(0xFF1E1E1E), const Color(0xFF121212)]
              : [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppColors.primary).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                ),
                child: const Center(
                  child: Icon(Icons.person_rounded, color: Colors.white, size: 40),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Misafir Kullanıcı',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tagline,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _HeaderAction(
                  icon: Icons.login_rounded,
                  label: 'Giriş Yap',
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeaderAction(
                  icon: Icons.person_add_rounded,
                  label: 'Kayıt Ol',
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              letterSpacing: 1.5,
              fontSize: 12,
            ),
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
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded, 
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2), 
                  size: 14
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({this.appName});
  final String? appName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 60),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.rocket_launch_rounded, 
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2), 
              size: 32
            ),
          ),
          const SizedBox(height: 20),
          Text(
            (appName ?? 'Hepsi Düziçi').toUpperCase(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Version 1.2.0 • Build 2024.1',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
