import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/utils/launcher_utils.dart';
import '../../core/utils/relative_time.dart';
import '../../core/widgets/service_page_layout.dart';
import '../../core/widgets/primary_card.dart';
import '../../data/models/city_content.dart';

class OutagesScreen extends ConsumerWidget {
  const OutagesScreen({super.key});

  static const _belediyeDuyurular = 'https://www.duzici.bel.tr/duyurular';
  static const _toroslarOnline = 'https://online.toroslaredas.com.tr';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(stampedOutagesProvider);

    return async.when(
      data: (stamped) => ServicePageLayout(
        title: 'Planlı Kesintiler',
        subtitle:
            'Düziçi Belediyesi duyurularından canlı çekilir; elektrik için Toroslar EDAŞ kaynağını da kontrol edin.',
        icon: 'block',
        color: const Color(0xFFE53935),
        onRefresh: () async => ref.invalidate(stampedOutagesProvider),
        isEmpty: stamped.data.isEmpty,
        emptyMessage:
            'Şu an belediye duyurularında aktif su/elektrik kesintisi yok. Elektrik için Toroslar EDAŞ sorgulamasını kullanın.',
        child: SliverMainAxisGroup(
          slivers: [
            if (stamped.data.isEmpty)
              SliverToBoxAdapter(child: _OfficialSourcesCard())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _OutageCard(outage: stamped.data[index], index: index),
                  childCount: stamped.data.length,
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: stamped.data.isEmpty ? 12 : 20, bottom: 8),
                child: _OfficialSourcesCard(compact: stamped.data.isNotEmpty),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Son kontrol: ${RelativeTime.format(stamped.fetchedAt)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Planlı Kesintiler')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Kesinti verisi alınamadı: $e', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(stampedOutagesProvider),
                  child: const Text('Tekrar dene'),
                ),
                const SizedBox(height: 20),
                const _OfficialSourcesCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OutageCard extends StatelessWidget {
  const _OutageCard({required this.outage, required this.index});

  final OutageItem outage;
  final int index;

  @override
  Widget build(BuildContext context) {
    final isWater = outage.type.toUpperCase() == 'SU';
    final isElectric = outage.type.toUpperCase().contains('ELEKTR');
    final isOngoing = outage.status == 'Devam Ediyor' || outage.status == 'Planlandı';
    final accent = isWater
        ? const Color(0xFF1E88E5)
        : isElectric
            ? const Color(0xFFF5A623)
            : const Color(0xFF8E24AA);

    return PrimaryCard(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isWater
                      ? Icons.water_drop_rounded
                      : isElectric
                          ? Icons.bolt_rounded
                          : Icons.info_outline_rounded,
                  color: accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      outage.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -0.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      outage.subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _StatusChip(status: outage.status, isOngoing: isOngoing),
              if (outage.source != null && outage.source!.isNotEmpty)
                Text(
                  outage.source!,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          if (outage.url != null && outage.url!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => LauncherUtils.openUrlExternal(context, outage.url!),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('Resmi duyuruyu aç'),
              ),
            ),
          ],
        ],
      ),
    ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: 0.05, end: 0);
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.isOngoing});

  final String status;
  final bool isOngoing;

  @override
  Widget build(BuildContext context) {
    final isPlanned = status == 'Planlandı';
    final bg = isOngoing
        ? const Color(0xFFFBAE3C).withValues(alpha: 0.18)
        : isPlanned
            ? const Color(0xFF1E88E5).withValues(alpha: 0.14)
            : const Color(0xFF43A047).withValues(alpha: 0.16);
    final fg = isOngoing
        ? const Color(0xFFD77700)
        : isPlanned
            ? const Color(0xFF1565C0)
            : const Color(0xFF2E7D32);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        status,
        style: TextStyle(fontSize: 12.5, color: fg, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _OfficialSourcesCard extends StatelessWidget {
  const _OfficialSourcesCard({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return PrimaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            compact ? 'Resmî kaynaklar' : 'Resmî kesinti kaynakları',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: compact ? 14 : 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 6),
            Text(
              'Liste yalnızca Düziçi Belediyesi duyurularından otomatik doldurulur. '
              'Elektrik kesintileri için dağıtım şirketini de kontrol edin.',
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
          const SizedBox(height: 12),
          _SourceButton(
            icon: Icons.account_balance_rounded,
            label: 'Düziçi Belediyesi Duyuruları',
            onTap: () => LauncherUtils.openUrlExternal(context, OutagesScreen._belediyeDuyurular),
          ),
          const SizedBox(height: 8),
          _SourceButton(
            icon: Icons.bolt_rounded,
            label: 'Toroslar EDAŞ — elektrik kesintisi',
            onTap: () => LauncherUtils.openUrlExternal(context, OutagesScreen._toroslarOnline),
          ),
        ],
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, textAlign: TextAlign.start),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}
