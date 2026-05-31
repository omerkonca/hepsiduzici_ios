import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/intl.dart';



import '../../../app/providers.dart';
import '../../../core/utils/weather_wmo_tr.dart';

import '../../../core/widgets/primary_card.dart';

import '../../../data/models/stamped_data.dart';

import '../../../data/models/weather_report.dart';



class WeatherCard extends ConsumerWidget {

  const WeatherCard({super.key});



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final async = ref.watch(stampedWeatherProvider);

    final dayFmt = DateFormat('EEE d MMM', 'tr_TR');



    return async.when(

      data: (Stamped<WeatherReport> s) {

        final r = s.data;

        final w = r.current;

        final humid = w.relativeHumidity;



        final theme = weatherVisualTheme(w.conditionCode);
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.gradientStart.withValues(alpha: isDark ? 0.25 : 0.9),
                theme.gradientEnd.withValues(alpha: isDark ? 0.15 : 0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: theme.gradientStart.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: theme.accent.withValues(alpha: 0.1)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                // Decorative circles for professional look
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.accent.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Düziçi, Osmaniye',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white70 : theme.accent.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                w.conditionLabel,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : theme.accent,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          WeatherAnimatedIcon(
                            conditionCode: w.conditionCode,
                            isDay: w.isDay,
                            size: 64,
                            color: isDark ? Colors.white : theme.accent,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${w.temperature.round()}°',
                            style: TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : theme.accent,
                              height: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.air_rounded, size: 14, color: isDark ? Colors.white70 : theme.accent.withValues(alpha: 0.7)),
                                    const SizedBox(width: 4),
                                    Text(
                                      windSummaryTr(w.windSpeed, w.windGust),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white70 : theme.accent.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                                if (humid != null) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(Icons.water_drop_rounded, size: 14, color: isDark ? Colors.white70 : theme.accent.withValues(alpha: 0.7)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Nem %$humid',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white70 : theme.accent.withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const SizedBox(height: 24),
                      if (r.daily.isNotEmpty) ...[
                        Text(
                          '5 Günlük Tahmin',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : theme.accent,
                          ),
                        ),
                        const SizedBox(height: 14),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: r.daily.map((d) {
                              return _DayChip(
                                dayLabel: dayFmt.format(d.date),
                                conditionCode: d.conditionCode,
                                max: d.maxTemp,
                                min: d.minTemp,
                                accentColor: isDark ? Colors.white : theme.accent,
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
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

              'Hava yükleniyor...',

              style: Theme.of(context).textTheme.bodyMedium,

            ),

          ],

        ),

      ),

      error: (_, __) => PrimaryCard(

        child: Text(

          'Hava durumu alınamadı',

          style: Theme.of(context).textTheme.bodyMedium,

        ),

      ),

    );

  }

}



class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.dayLabel,
    required this.conditionCode,
    required this.max,
    required this.min,
    required this.accentColor,
  });

  final String dayLabel;
  final int conditionCode;
  final double max;
  final double min;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(
            dayLabel.split(' ')[0], // Sadece gün ismi
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: accentColor.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          WeatherAnimatedIcon(
            conditionCode: conditionCode,
            size: 28,
            color: accentColor,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${max.round()}°',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: accentColor,
                ),
              ),
              Text(
                ' ${min.round()}°',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: accentColor.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}



