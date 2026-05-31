import 'package:flutter/material.dart';
import '../../../core/utils/weather_wmo_tr.dart';
import '../../../data/models/weather_report.dart';

/// Anlık Bilgiler hava kartının genişletilmiş gövdesi.
class WeatherExpandableDetails extends StatelessWidget {
  const WeatherExpandableDetails({
    super.key,
    required this.report,
    this.showLocationHeader = true,
  });

  final WeatherReport report;
  final bool showLocationHeader;

  @override
  Widget build(BuildContext context) {
    final current = report.current;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showLocationHeader) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.location,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    Text(
                      current.conditionText,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              WeatherAnimatedIcon(
                conditionCode: current.conditionCode,
                isDay: current.isDay,
                size: 44,
                color: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${current.temperature.round()}°',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.w900,
                height: 1.0,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (current.relativeHumidity != null)
                      _WeatherDetailItem(
                        icon: Icons.water_drop_rounded,
                        label: '%${current.relativeHumidity} Nem',
                      ),
                    if (current.windSpeed != null)
                      _WeatherDetailItem(
                        icon: Icons.air_rounded,
                        label: '${current.windSpeed?.round()} km/h Rüzgar',
                      ),
                  ],
                ),
              ),
            ),
            WeatherAnimatedIcon(
              conditionCode: current.conditionCode,
              isDay: current.isDay,
              size: 40,
              color: Colors.white,
            ),
          ],
        ),
        if (report.daily.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: report.daily.take(3).map((d) => _ForecastItem(daily: d)).toList(),
            ),
          ),
        ],
      ],
    );
  }
}

class _WeatherDetailItem extends StatelessWidget {
  const _WeatherDetailItem({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ForecastItem extends StatelessWidget {
  const _ForecastItem({required this.daily});
  final DailyForecast daily;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          _dayName(daily.date),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        WeatherAnimatedIcon(
          conditionCode: daily.conditionCode,
          size: 20,
          color: Colors.white,
        ),
        const SizedBox(height: 4),
        Text(
          '${daily.maxTemp.round()}° / ${daily.minTemp.round()}°',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  String _dayName(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day) return 'Bugün';
    if (date.day == now.add(const Duration(days: 1)).day) return 'Yarın';
    const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return days[date.weekday - 1];
  }
}
