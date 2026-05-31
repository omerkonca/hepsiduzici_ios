import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/launcher_utils.dart';
import '../../core/widgets/primary_card.dart';
import '../../core/widgets/service_page_layout.dart';

class MunicipalityUnitsScreen extends ConsumerWidget {
  const MunicipalityUnitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cityContentProvider);
    return async.when(
      data: (content) => ServicePageLayout(
        title: 'Belediye Birimleri',
        subtitle: 'İlçemizdeki müdürlükler ve birimler ile iletişim hatları.',
        icon: 'account_balance',
        color: AppColors.accentBlue,
        isEmpty: content.municipalityUnits.isEmpty,
        child: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final u = content.municipalityUnits[index];
              return PrimaryCard(
                margin: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.accentBlue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(Icons.apartment_rounded, color: AppColors.accentBlue),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            u.title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Text(
                      u.subtitle,
                      style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      u.phone,
                      style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: () => LauncherUtils.callPhone(context, u.phone),
                      icon: const Icon(Icons.phone_rounded, size: 18),
                      label: const Text('Ara'),
                    ),
                  ],
                ),
              ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: 0.05, end: 0);
            },
            childCount: content.municipalityUnits.length,
          ),
        ),
      ),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Belediye verisi yuklenemedi: $e'))),
    );
  }
}
