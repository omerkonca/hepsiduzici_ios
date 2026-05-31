import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/utils/icon_mapper.dart';
import '../../core/utils/launcher_utils.dart';
import '../../core/widgets/primary_card.dart';
import '../../core/widgets/service_page_layout.dart';

class EmergencyNumbersScreen extends ConsumerWidget {
  const EmergencyNumbersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cityContentProvider);
    return async.when(
      data: (content) => ServicePageLayout(
        title: 'Acil Numaralar',
        subtitle: 'Acil durumlarda hızlı erişim için kritik yardım hatları.',
        icon: 'emergency',
        color: const Color(0xFFE53935),
        isEmpty: content.emergencyContacts.isEmpty,
        child: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final c = content.emergencyContacts[index];
              return PrimaryCard(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(IconMapper.fromName(c.icon), color: Colors.redAccent, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            c.number,
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: () => LauncherUtils.callPhone(context, c.number),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      child: const Text('Ara'),
                    ),
                  ],
                ),
              ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: 0.05, end: 0);
            },
            childCount: content.emergencyContacts.length,
          ),
        ),
      ),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Acil numaralar yuklenemedi: $e'))),
    );
  }
}
