import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../core/theme/premium_city_theme.dart';
import '../../core/widgets/primary_card.dart';
import '../../core/widgets/service_page_layout.dart';
import '../../data/models/obituary_item.dart';

class ObituaryScreen extends ConsumerStatefulWidget {
  const ObituaryScreen({super.key});

  @override
  ConsumerState<ObituaryScreen> createState() => _ObituaryScreenState();
}

class _ObituaryScreenState extends ConsumerState<ObituaryScreen> {
  ObituaryScope? _selectedScope;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(obituaryListProvider);

    return async.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => ServicePageLayout(
        title: 'Vefat Listesi',
        subtitle: 'Taziye duyuruları',
        icon: 'sentiment_very_dissatisfied',
        color: const Color(0xFF546E7A),
        isEmpty: true,
        emptyMessage: 'Vefat listesi yüklenemedi.\n$e',
        onRefresh: () async => ref.invalidate(obituaryListProvider),
        child: const SliverToBoxAdapter(child: SizedBox.shrink()),
      ),
      data: (items) {
        final filtered = _filter(items);
        return ServicePageLayout(
          title: 'Vefat Listesi',
          subtitle: 'Taziye duyuruları',
          icon: 'sentiment_very_dissatisfied',
          color: const Color(0xFF546E7A),
          isEmpty: filtered.isEmpty,
          emptyMessage:
              'Son 45 gün içinde güncel vefat kaydı bulunamadı.\n'
              'Belediye siteleri güncellenmemiş olabilir; '
              'cenaze hattını arayarak güncel bilgi alabilirsiniz.',
          onRefresh: () async => ref.invalidate(obituaryListProvider),
          child: SliverList(
            delegate: SliverChildListDelegate([
              _ScopeFilterBar(
                selected: _selectedScope,
                onChanged: (scope) => setState(() => _selectedScope = scope),
              ),
              const SizedBox(height: 10),
              _ShareAllButton(items: filtered),
              if (filtered.isNotEmpty) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${filtered.length} kayıt',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                ...filtered.asMap().entries.map(
                  (entry) => _ObituaryCard(
                    item: entry.value,
                    index: entry.key,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              ..._contactCards(),
              const SizedBox(height: 24),
            ]),
          ),
        );
      },
    );
  }

  List<ObituaryItem> _filter(List<ObituaryItem> items) {
    if (_selectedScope == null) return items;
    return items.where((e) => e.scope == _selectedScope).toList();
  }

  List<Widget> _contactCards() {
    return const [
      _ContactCard(
        title: 'Belediye Cenaze Hizmetleri',
        subtitle: 'www.duzici.bel.tr / Cenaze Bilgi Sistemi',
        phone: '0328 876 00 08',
      ),
      SizedBox(height: 10),
      _ContactCard(
        title: 'Düziçi Müftülüğü',
        subtitle: 'Cumhuriyet Mah., Düziçi',
        phone: '0328 876 10 20',
      ),
      SizedBox(height: 10),
      _ContactCard(
        title: 'Osmaniye Belediyesi Çağrı Merkezi',
        subtitle: 'Osmaniye geneli cenaze duyuruları',
        phone: '0328 440 00 80',
      ),
    ];
  }
}

class _ScopeFilterBar extends StatelessWidget {
  const _ScopeFilterBar({
    required this.selected,
    required this.onChanged,
  });

  final ObituaryScope? selected;
  final ValueChanged<ObituaryScope?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _FilterChip(
          label: 'Tümü',
          selected: selected == null,
          onTap: () => onChanged(null),
        ),
        _FilterChip(
          label: 'Düziçi',
          selected: selected == ObituaryScope.duzici,
          onTap: () => onChanged(ObituaryScope.duzici),
        ),
        _FilterChip(
          label: 'Osmaniye Geneli',
          selected: selected == ObituaryScope.osmaniye,
          onTap: () => onChanged(ObituaryScope.osmaniye),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? const Color(0xFF546E7A)
          : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? const Color(0xFF546E7A)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : PremiumCityTheme.ink,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _ShareAllButton extends StatelessWidget {
  const _ShareAllButton({required this.items});

  final List<ObituaryItem> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: OutlinedButton.icon(
        onPressed: items.isEmpty
            ? null
            : () {
                final text = items
                    .map((e) => e.toShareText())
                    .join('\n\n—\n\n');
                SharePlus.instance.share(ShareParams(text: text));
              },
        icon: const Icon(Icons.ios_share_rounded, size: 18),
        label: const Text('Listeyi Paylaş'),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.title,
    required this.subtitle,
    required this.phone,
  });

  final String title;
  final String subtitle;
  final String phone;

  @override
  Widget build(BuildContext context) {
    return PrimaryCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 15,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: FilledButton.icon(
              onPressed: () => _callPhone(phone),
              icon: const Icon(Icons.phone_rounded, size: 16),
              label: Text(phone, style: const TextStyle(fontSize: 13)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF546E7A),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:${phone.replaceAll(' ', '')}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _ObituaryCard extends StatelessWidget {
  const _ObituaryCard({
    required this.item,
    required this.index,
  });

  final ObituaryItem item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('d MMMM yyyy', 'tr_TR').format(item.deathDate);

    return PrimaryCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.fullName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _ScopeBadge(label: item.scopeLabel),
            ],
          ),
          if (item.age != null) ...[
            const SizedBox(height: 6),
            Text(
              'Yaş: ${item.age}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (item.locationLabel.isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.place_outlined,
              text: item.locationLabel,
            ),
          ],
          if (item.condolenceAddress.isNotEmpty) ...[
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.home_outlined,
              text: 'Taziye: ${item.condolenceAddress}',
            ),
          ],
          if (item.burialPlace.isNotEmpty) ...[
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.church_outlined,
              text: 'Defin: ${item.burialPlace}',
            ),
          ],
          if (item.detail.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.detail,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.45,
                  ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.source,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Paylaş',
                visualDensity: VisualDensity.compact,
                onPressed: () => SharePlus.instance.share(
                  ShareParams(text: item.toShareText()),
                ),
                icon: const Icon(Icons.ios_share_rounded, size: 20),
              ),
              if (item.sourceUrl.isNotEmpty)
                IconButton(
                  tooltip: 'Kaynak',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => launchUrl(
                    Uri.parse(item.detailUrl.isNotEmpty
                        ? item.detailUrl
                        : item.sourceUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 20),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScopeBadge extends StatelessWidget {
  const _ScopeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF546E7A).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF546E7A),
          fontWeight: FontWeight.w800,
          fontSize: 10.5,
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
        Icon(icon, size: 15, color: Theme.of(context).textTheme.bodySmall?.color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }
}
