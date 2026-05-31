import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/widgets/primary_card.dart';
import '../../core/widgets/service_page_layout.dart';
import '../../data/models/city_content.dart';

class DirectoryScreen extends StatelessWidget {
  const DirectoryScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.entries,
  });

  final String title;
  final String subtitle;
  final String icon;
  final Color color;
  final List<DirectoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    return ServicePageLayout(
      title: title,
      subtitle: subtitle,
      icon: icon,
      color: color,
      isEmpty: entries.isEmpty,
      child: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final entry = entries[index];
            return _DirectoryCard(
              entry: entry,
              color: color,
            ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: 0.04, end: 0);
          },
          childCount: entries.length,
        ),
      ),
    );
  }
}

class _DirectoryCard extends StatelessWidget {
  const _DirectoryCard({required this.entry, required this.color});

  final DirectoryEntry entry;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return PrimaryCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -0.3,
                ),
          ),
          if (entry.address.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 15, color: Theme.of(context).textTheme.bodySmall?.color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    entry.address,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
          ],
          if (entry.phone.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: FilledButton.icon(
                onPressed: () => _callPhone(context, entry.phone),
                icon: const Icon(Icons.phone_rounded, size: 16),
                label: Text(entry.phone, style: const TextStyle(fontSize: 13)),
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _callPhone(BuildContext context, String phone) async {
    final cleaned = phone.replaceAll(' ', '');
    final uri = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
