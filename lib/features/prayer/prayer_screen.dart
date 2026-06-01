import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/primary_card.dart';
import '../../core/widgets/section_title.dart';
import '../../data/models/prayer_times.dart';

class PrayerScreen extends ConsumerWidget {
  const PrayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(prayerTimesProvider);
    return async.when(
      data: (PrayerTimes p) {
        return Scaffold(
          appBar: AppBar(title: const Text('Namaz Vakitleri')),
          body: RefreshIndicator(
          onRefresh: () async => ref.invalidate(prayerTimesProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle(title: 'Bugünkü namaz vakitleri'),
                ...p.allTimes.map((t) => PrimaryCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            t.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            t.time,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Namaz Vakitleri')),
        body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Vakitler yüklenemedi', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.invalidate(prayerTimesProvider),
              child: const Text('Tekrar dene'),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
