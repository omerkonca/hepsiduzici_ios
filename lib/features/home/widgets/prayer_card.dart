import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_card.dart';
import '../../../data/models/prayer_times.dart';

class PrayerCard extends ConsumerWidget {
  const PrayerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(prayerTimesProvider);
    return async.when(
      data: (PrayerTimes p) {
        final now = DateTime.now();
        final current = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        final next = p.nextPrayer(current) ?? p.allTimes.first;
        return PrimaryCard(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.mosque_rounded,
                  size: 36,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sıradaki vakit',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${next.name} · ${next.time}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => PrimaryCard(
        child: Row(
          children: [
            const SizedBox(
              width: 52,
              height: 52,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 16),
            Text(
              'Namaz vakitleri yükleniyor...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      error: (_, __) => PrimaryCard(
        child: Text(
          'Namaz vakitleri alınamadı',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
