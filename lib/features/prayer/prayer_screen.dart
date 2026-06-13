import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/widgets/service_page_layout.dart';
import '../../data/models/prayer_times.dart';
import 'widgets/qibla_compass.dart';

class PrayerScreen extends ConsumerStatefulWidget {
  const PrayerScreen({super.key});

  @override
  ConsumerState<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends ConsumerState<PrayerScreen> {
  Timer? _timer;
  bool _showCompass = false;

  @override
  void initState() {
    super.initState();
    // Her saniye ekranı güncelleyerek canlı geri sayımı tetikleriz
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_showCompass) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  IconData _iconForPrayerName(String name) {
    switch (name.toLowerCase()) {
      case 'imsak':
        return Icons.nightlight_round;
      case 'güneş':
        return Icons.wb_twilight_rounded;
      case 'öğle':
        return Icons.wb_sunny_rounded;
      case 'ikindi':
        return Icons.wb_sunny_outlined;
      case 'akşam':
        return Icons.nights_stay_rounded;
      case 'yatsı':
        return Icons.bedtime_rounded;
      default:
        return Icons.mosque_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(prayerTimesProvider);

    return async.when(
      data: (PrayerTimes p) {
        final now = DateTime.now();
        final currentHourStr = now.hour.toString().padLeft(2, '0');
        final currentMinuteStr = now.minute.toString().padLeft(2, '0');
        final currentTime = '$currentHourStr:$currentMinuteStr';

        final times = p.allTimes;
        int nextIndex = -1;
        for (int i = 0; i < times.length; i++) {
          if (times[i].time.compareTo(currentTime) > 0) {
            nextIndex = i;
            break;
          }
        }

        int currentIdx = -1;
        if (nextIndex == -1) {
          currentIdx = 5; // Yatsı
        } else if (nextIndex == 0) {
          currentIdx = 5; // Yatsı (imsak öncesi gece vaktindeyiz)
        } else {
          currentIdx = nextIndex - 1;
        }

        final nextPrayerItem = nextIndex != -1 ? times[nextIndex] : times[0];
        final nextPrayerName = nextPrayerItem.name;
        final nextPrayerTime = nextPrayerItem.time;

        // Hedef DateTime hesabı
        final nextParts = nextPrayerTime.split(':');
        final nextHour = int.parse(nextParts[0]);
        final nextMinute = int.parse(nextParts[1]);

        DateTime nextDateTime = DateTime(now.year, now.month, now.day, nextHour, nextMinute);
        if (nextDateTime.isBefore(now)) {
          nextDateTime = nextDateTime.add(const Duration(days: 1));
        }

        // Başlangıç DateTime hesabı
        final startPrayerItem = times[currentIdx];
        final startParts = startPrayerItem.time.split(':');
        final startHour = int.parse(startParts[0]);
        final startMinute = int.parse(startParts[1]);

        DateTime startDateTime = DateTime(now.year, now.month, now.day, startHour, startMinute);
        if (startDateTime.isAfter(now)) {
          startDateTime = startDateTime.subtract(const Duration(days: 1));
        }

        final totalSecs = nextDateTime.difference(startDateTime).inSeconds;
        final elapsedSecs = now.difference(startDateTime).inSeconds;
        final progress = totalSecs > 0 ? (elapsedSecs / totalSecs).clamp(0.0, 1.0) : 0.0;

        final diff = nextDateTime.difference(now);
        final hoursStr = diff.inHours.toString().padLeft(2, '0');
        final minutesStr = (diff.inMinutes % 60).toString().padLeft(2, '0');
        final secondsStr = (diff.inSeconds % 60).toString().padLeft(2, '0');

        const Color themeColor = Color(0xFF00796B); // Premium yeşil/teal renk

        return ServicePageLayout(
          title: _showCompass ? 'Kıble Yönü' : 'Namaz Vakitleri',
          subtitle: _showCompass
              ? 'Telefonu yere paralel tutun; yeşil ok Kabe yönünü gösterir. Düziçi: ~168.5°.'
              : 'Düziçi namaz vakitleri — Diyanet İşleri Başkanlığı uyumlu.',
          icon: _showCompass ? 'navigation' : 'mosque',
          color: themeColor,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showCompass = !_showCompass;
                  });
                },
                icon: Icon(
                  _showCompass ? Icons.mosque_rounded : Icons.explore_rounded,
                  size: 20,
                ),
                label: Text(
                  _showCompass ? 'Namaz Vakitleri' : 'Kıble Yönü',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: themeColor,
                ),
              ),
            ),
          ],
          onRefresh: _showCompass
              ? null
              : () async {
                  ref.invalidate(prayerTimesProvider);
                  await ref.read(prayerTimesProvider.future);
                },
          child: _showCompass
              ? const SliverFillRemaining(
                  hasScrollBody: false,
                  child: QiblaCompass(),
                )
              : SliverList(
                  delegate: SliverChildListDelegate([
              // Kıble yönü
              Material(
                color: themeColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => setState(() => _showCompass = true),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: themeColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.explore_rounded,
                            color: themeColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kıble Yönünü Bul',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: themeColor,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Pusula ile Kabe yönünü göster',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF00695C),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: themeColor),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 350.ms),
              const SizedBox(height: 16),
              // Geri Sayım Hero Kartı
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00796B), Color(0xFF004D40)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.mosque_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SIRADAKİ VAKİT',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                nextPrayerName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            nextPrayerTime,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Center(
                      child: Column(
                        children: [
                          const Text(
                            'Ezana Kalan Süre',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildTimeUnit(hoursStr, 'SAAT'),
                              _buildTimeSeparator(),
                              _buildTimeUnit(minutesStr, 'DAKİKA'),
                              _buildTimeSeparator(),
                              _buildTimeUnit(secondsStr, 'SANİYE'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Geçen Süre: %${(progress * 100).toInt()}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Vakit Sonu: $nextPrayerTime',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
              const SizedBox(height: 24),
              // Vakitler Liste Başlığı
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  'Bugün Namaz Vakitleri',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                ),
              ).animate(delay: 100.ms).fadeIn(),
              // Vakit Kartları
              ...times.asMap().entries.map((entry) {
                final idx = entry.key;
                final t = entry.value;
                final isCurrent = (idx == currentIdx);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? themeColor.withValues(alpha: 0.08)
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isCurrent
                          ? themeColor.withValues(alpha: 0.3)
                          : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
                      width: isCurrent ? 2 : 1,
                    ),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: themeColor.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? themeColor.withValues(alpha: 0.12)
                                : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _iconForPrayerName(t.name),
                            color: isCurrent ? themeColor : Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                t.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w700,
                                  color: isCurrent ? themeColor : null,
                                ),
                              ),
                              if (isCurrent) ...[
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: themeColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'Şu Anki Vakit',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                                 .fadeIn(duration: 800.ms)
                                 .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05)),
                              ],
                            ],
                          ),
                        ),
                        Text(
                          t.time,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w700,
                            color: isCurrent ? themeColor : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate(delay: (150 + idx * 50).ms).fadeIn().slideX(begin: 0.04, end: 0, curve: Curves.easeOutCubic);
              }),
              const SizedBox(height: 16),
              // Bilgi / Kaynak Kartı
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Namaz vakitleri Diyanet İşleri Başkanlığı verilerinden alınmaktadır. Bulunduğunuz konuma göre milisaniyelik sapmalar olabilir.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate(delay: 500.ms).fadeIn(),
              const SizedBox(height: 24),
            ]),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF00796B),
          ),
        ),
      ),
      error: (e, _) => ServicePageLayout(
        title: 'Namaz Vakitleri',
        subtitle: 'Namaz vakitleri alınamadı.',
        icon: 'mosque',
        color: const Color(0xFF00796B),
        isEmpty: true,
        emptyMessage: 'Namaz vakitleri yüklenemedi: $e\nLütfen tekrar deneyin.',
        onRefresh: () async {
          ref.invalidate(prayerTimesProvider);
          await ref.read(prayerTimesProvider.future);
        },
        child: const SliverToBoxAdapter(child: SizedBox.shrink()),
      ),
    );
  }

  Widget _buildTimeUnit(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSeparator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        ':',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: Colors.white70,
        ),
      ),
    );
  }
}
