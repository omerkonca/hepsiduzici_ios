import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/launcher_utils.dart';
import '../../../core/widgets/primary_card.dart';
import '../../../data/models/pharmacy.dart';

class PharmacyCard extends ConsumerWidget {
  const PharmacyCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pharmacyListProvider);
    return async.when(
      data: (List<Pharmacy> list) {
        final first = list.isNotEmpty ? list.first : null;
        if (first == null) {
          return PrimaryCard(
            child: Text(
              'Bugün nöbetçi eczane bilgisi bulunamadı.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }
        return PrimaryCard(
          onTap: () => _launchPhone(context, first.phone),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.local_pharmacy_rounded,
                  size: 32,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nöbetçi Eczane',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      first.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (first.phone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        first.phone,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.phone_rounded,
                color: AppColors.primaryDark,
                size: 26,
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
              'Nöbetçi eczane yükleniyor...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      error: (_, __) => PrimaryCard(
        child: Text(
          'Nöbetçi eczane listesi alınamadı',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

  Future<void> _launchPhone(BuildContext context, String phone) async {
    await LauncherUtils.callPhone(context, phone);
  }
}
