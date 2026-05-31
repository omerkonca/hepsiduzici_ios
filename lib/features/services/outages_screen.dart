import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/widgets/service_page_layout.dart';
import '../../core/widgets/primary_card.dart';

class OutagesScreen extends ConsumerWidget {
  const OutagesScreen({super.key, List<dynamic>? outages});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(stampedOutagesProvider);

    return async.when(
      data: (stamped) => ServicePageLayout(
        title: 'Planlı Kesintiler',
        subtitle: 'Su ve elektrik kesintileri — mahalle bazlı duyurular.',
        icon: 'block',
        color: const Color(0xFFE53935),
        onRefresh: () async => ref.invalidate(stampedOutagesProvider),
        isEmpty: stamped.data.isEmpty,
        emptyMessage: 'Şu an aktif bir kesinti bulunmamaktadır.',
        child: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final outage = stamped.data[index];
              final isWater = outage.type.toUpperCase() == 'SU';
              final isOngoing = outage.status == 'Devam Ediyor';
              final accent = isWater ? const Color(0xFF1E88E5) : const Color(0xFFF5A623);

              return PrimaryCard(
                margin: const EdgeInsets.only(bottom: 14),
                child: Row(
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
                        isWater ? Icons.water_drop_rounded : Icons.bolt_rounded,
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
                              fontSize: 18,
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: -0.25,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            outage.subtitle,
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isOngoing
                                  ? const Color(0xFFFBAE3C).withValues(alpha: 0.18)
                                  : const Color(0xFF43A047).withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              outage.status,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isOngoing ? const Color(0xFFD77700) : const Color(0xFF2E7D32),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: 0.05, end: 0);
            },
            childCount: stamped.data.length,
          ),
        ),
      ),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Hata: $e'))),
    );
  }
}

