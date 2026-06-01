import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Open-Meteo / WMO weather_code için Türkçe kısa açıklama.
String weatherCodeLabelTr(int code) {
  return switch (code) {
    0 => 'Açık',
    1 => 'Çoğunlukla açık',
    2 => 'Parçalı bulutlu',
    3 => 'Kapalı',
    45 => 'Sisli',
    48 => 'Donlu sis',
    51 => 'Hafif çisenti',
    53 => 'Orta çisenti',
    55 => 'Yoğun çisenti',
    56 => 'Donan çisenti',
    57 => 'Yoğun donan çisenti',
    61 => 'Hafif yağmurlu',
    63 => 'Yağmurlu',
    65 => 'Kuvvetli yağmurlu',
    66 => 'Donan yağmur',
    67 => 'Kuvvetli donan yağmur',
    71 => 'Hafif kar',
    73 => 'Karlı',
    75 => 'Yoğun kar',
    77 => 'Kar taneleri',
    80 => 'Hafif sağanak',
    81 => 'Sağanak yağmur',
    82 => 'Kuvvetli sağanak',
    85 => 'Hafif kar sağanağı',
    86 => 'Kar sağanağı',
    95 => 'Gök gürültülü',
    96 => 'Doluyla gök gürültülü',
    97 => 'Gök gürültülü',
    99 => 'Şiddetli doluyla fırtına',
    _ => 'Değişken',
  };
}

IconData weatherCodeIcon(int code, {bool isDay = true}) {
  if (code == 0) {
    return isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round;
  }
  if (code == 1 || code == 2) {
    return isDay ? Icons.wb_cloudy_rounded : Icons.nightlight_round;
  }
  if (code == 3) return Icons.cloud_rounded; // Kapalı
  if (code == 45 || code == 48) return Icons.foggy;
  if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
    return Icons.grain_rounded; // Yağmurlu
  }
  if ((code >= 71 && code <= 77) || code == 85 || code == 86) {
    return Icons.ac_unit_rounded; // Karlı
  }
  if (code >= 95) return Icons.thunderstorm_rounded;
  return Icons.cloud_rounded;
}

/// km/h — özet cümle (rüzgarlı mı, şiddetli mi).
String windSummaryTr(double? windKmh, double? gustKmh) {
  final w = windKmh ?? 0;
  final g = gustKmh ?? 0;
  final peak = math.max(w, g);
  if (peak < 5) return 'Rüzgar çok hafif';
  if (peak < 15) return 'Hafif rüzgar';
  if (peak < 30) return 'Orta şiddette rüzgar';
  if (peak < 45) return 'Rüzgarlı';
  if (peak < 60) return 'Kuvvetli rüzgar';
  if (peak < 75) return 'Şiddetli rüzgar';
  return 'Çok şiddetli rüzgar / fırtına riski';
}

/// Gösterim için sayısal özet.
String windSpeedLineTr(double? windKmh, double? gustKmh) {
  if (windKmh == null && gustKmh == null) return '';
  final w = windKmh?.round();
  final g = gustKmh?.round();
  if (w != null && g != null && g > w + 5) {
    return 'Rüzgar ~$w km/h · ani $g km/h';
  }
  if (w != null) return 'Rüzgar ~$w km/h';
  return 'Ani rüzgar ~${g ?? 0} km/h';
}

enum WeatherVisualType { sunny, cloudy, rainy, snowy, stormy, foggy }

WeatherVisualType weatherVisualType(int code) {
  if (code == 0 || code == 1) return WeatherVisualType.sunny;
  if (code >= 2 && code <= 3) return WeatherVisualType.cloudy;
  if (code == 45 || code == 48) return WeatherVisualType.foggy;
  if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
    return WeatherVisualType.rainy;
  }
  if ((code >= 71 && code <= 77) || code == 85 || code == 86) {
    return WeatherVisualType.snowy;
  }
  if (code >= 95) return WeatherVisualType.stormy;
  return WeatherVisualType.cloudy;
}

class WeatherVisualTheme {
  const WeatherVisualTheme({
    required this.gradientStart,
    required this.gradientEnd,
    required this.accent,
    required this.iconBackground,
  });

  final Color gradientStart;
  final Color gradientEnd;
  final Color accent;
  final Color iconBackground;
}

WeatherVisualTheme weatherVisualTheme(int code, {bool isDay = true}) {
  final type = weatherVisualType(code);
  if (!isDay && type == WeatherVisualType.sunny) {
    return const WeatherVisualTheme(
      gradientStart: Color(0xFF1B2A47),
      gradientEnd: Color(0xFF0D172A),
      accent: Color(0xFF7DD3FC),
      iconBackground: Color(0x337DD3FC),
    );
  }
  switch (type) {
    case WeatherVisualType.sunny:
      return const WeatherVisualTheme(
        gradientStart: Color(0xFFFFA726),
        gradientEnd: Color(0xFFFFEB3B),
        accent: Color(0xFF9A4A00),
        iconBackground: Color(0x40FFF8E1),
      );
    case WeatherVisualType.cloudy:
      return const WeatherVisualTheme(
        gradientStart: Color(0xFF5BA5E2),
        gradientEnd: Color(0xFF7AB9EF),
        accent: Color(0xFFE3F2FD),
        iconBackground: Color(0x33E3F2FD),
      );
    case WeatherVisualType.foggy:
      return const WeatherVisualTheme(
        gradientStart: Color(0xFF90A4AE),
        gradientEnd: Color(0xFFB0BEC5),
        accent: Color(0xFFECEFF1),
        iconBackground: Color(0x33ECEFF1),
      );
    case WeatherVisualType.rainy:
      return const WeatherVisualTheme(
        gradientStart: Color(0xFF2F6BAB),
        gradientEnd: Color(0xFF4E86C4),
        accent: Color(0xFF0F2D4A),
        iconBackground: Color(0x3A1C3D5F),
      );
    case WeatherVisualType.snowy:
      return const WeatherVisualTheme(
        gradientStart: Color(0xFF7E9BC6),
        gradientEnd: Color(0xFFA7BEDF),
        accent: Color(0xFFF5F8FF),
        iconBackground: Color(0x33E1F5FE),
      );
    case WeatherVisualType.stormy:
      return const WeatherVisualTheme(
        gradientStart: Color(0xFF455A64),
        gradientEnd: Color(0xFF607D8B),
        accent: Color(0xFFFFF59D),
        iconBackground: Color(0x33FFF59D),
      );
  }
}

class WeatherAnimatedIcon extends StatefulWidget {
  const WeatherAnimatedIcon({
    super.key,
    required this.conditionCode,
    this.isDay = true,
    this.size = 22,
    this.color = Colors.white,
  });

  final int conditionCode;
  final bool isDay;
  final double size;
  final Color color;

  @override
  State<WeatherAnimatedIcon> createState() => _WeatherAnimatedIconState();
}

class _WeatherAnimatedIconState extends State<WeatherAnimatedIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _animationDurationForCode(widget.conditionCode),
  )..repeat();

  @override
  void didUpdateWidget(covariant WeatherAnimatedIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conditionCode != widget.conditionCode) {
      _controller.duration = _animationDurationForCode(widget.conditionCode);
      _controller
        ..reset()
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = weatherVisualType(widget.conditionCode);
    final icon = weatherCodeIcon(widget.conditionCode, isDay: widget.isDay);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final rainIntensity = _rainIntensityForCode(widget.conditionCode);
          final snowIntensity = _snowIntensityForCode(widget.conditionCode);
          final stormIntensity = _stormIntensityForCode(widget.conditionCode);
          final bob = math.sin(t * math.pi * 2) * 1.2;
          final stormFlash = (math.sin(tau(t) * 2.7) + 1) / 2;
          final stormAlpha = type == WeatherVisualType.stormy
              ? (stormFlash > 0.82 ? ((stormFlash - 0.82) / 0.18) * (0.30 + 0.15 * stormIntensity) : 0.0)
              : 0.0;
          final iconColor = switch (type) {
            WeatherVisualType.rainy => Color.lerp(widget.color, Colors.black, 0.28)!,
            WeatherVisualType.sunny => Color.lerp(widget.color, const Color(0xFFFFB300), 0.22)!,
            _ => widget.color,
          };

          // Custom Gorgeous Layered Sun-behind-cloud / Moon-behind-cloud for partly cloudy
          if (widget.conditionCode == 1 || widget.conditionCode == 2) {
            final sunColor = widget.isDay
                ? Color.lerp(widget.color, const Color(0xFFFFB000), 0.88)!
                : const Color(0xFF90CAF9);
            final cloudColor = widget.color.withValues(alpha: 0.95);

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Glowing background for sun (only if day)
                if (widget.isDay)
                  Positioned(
                    top: -widget.size * 0.02,
                    right: -widget.size * 0.02,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: sunColor.withValues(alpha: 0.3),
                            blurRadius: widget.size * 0.25,
                            spreadRadius: widget.size * 0.05,
                          ),
                        ],
                      ),
                      child: SizedBox(width: widget.size * 0.65, height: widget.size * 0.65),
                    ),
                  ),
                // Sun / Moon in the background (top-right)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Transform.translate(
                    offset: Offset(0, bob * 0.5),
                    child: Icon(
                      widget.isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                      color: sunColor,
                      size: widget.size * 0.68,
                    ),
                  ),
                ),
                // Cloud in the foreground (bottom-left)
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Transform.translate(
                    offset: Offset(0, bob * 0.8),
                    child: Icon(
                      Icons.cloud_rounded,
                      color: cloudColor,
                      size: widget.size * 0.72,
                    ),
                  ),
                ),
              ],
            );
          }
          return Stack(
            clipBehavior: Clip.none,
            children: [
              if (type == WeatherVisualType.sunny)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withValues(
                            alpha: (0.22 + (math.sin(tau(t)) + 1) * 0.12) * 0.45,
                          ),
                          blurRadius: widget.size * 0.28,
                          spreadRadius: widget.size * 0.08,
                        ),
                      ],
                    ),
                  ),
                ),
              if (type == WeatherVisualType.rainy) ...[
                _RainDrop(
                  left: widget.size * 0.2,
                  top: widget.size * (0.48 + (t * (0.24 + 0.12 * rainIntensity)) % 0.4),
                  color: iconColor.withValues(alpha: 0.85),
                ),
                _RainDrop(
                  left: widget.size * 0.46,
                  top: widget.size * (0.35 + ((t + 0.35) * (0.2 + 0.14 * rainIntensity)) % 0.45),
                  color: iconColor.withValues(alpha: 0.8),
                ),
                _RainDrop(
                  left: widget.size * 0.7,
                  top: widget.size * (0.42 + ((t + 0.65) * (0.22 + 0.14 * rainIntensity)) % 0.42),
                  color: iconColor.withValues(alpha: 0.75),
                ),
                if (rainIntensity >= 2)
                  _RainDrop(
                    left: widget.size * 0.32,
                    top: widget.size * (0.36 + ((t + 0.18) * (0.24 + 0.16 * rainIntensity)) % 0.46),
                    color: iconColor.withValues(alpha: 0.72),
                  ),
                if (rainIntensity >= 3)
                  _RainDrop(
                    left: widget.size * 0.58,
                    top: widget.size * (0.4 + ((t + 0.82) * (0.26 + 0.18 * rainIntensity)) % 0.42),
                    color: iconColor.withValues(alpha: 0.68),
                  ),
              ],
              if (type == WeatherVisualType.snowy) ...[
                _SnowFlake(
                  left: widget.size * 0.22,
                  top: widget.size * (0.45 + (t * (0.14 + 0.08 * snowIntensity)) % 0.45),
                  size: 2.2,
                  color: iconColor.withValues(alpha: 0.88),
                ),
                _SnowFlake(
                  left: widget.size * 0.5,
                  top: widget.size * (0.36 + ((t + 0.3) * (0.12 + 0.08 * snowIntensity)) % 0.5),
                  size: 2.0,
                  color: iconColor.withValues(alpha: 0.8),
                ),
                _SnowFlake(
                  left: widget.size * 0.72,
                  top: widget.size * (0.42 + ((t + 0.55) * (0.13 + 0.09 * snowIntensity)) % 0.46),
                  size: 1.8,
                  color: iconColor.withValues(alpha: 0.75),
                ),
                if (snowIntensity >= 2)
                  _SnowFlake(
                    left: widget.size * 0.36,
                    top: widget.size * (0.38 + ((t + 0.72) * (0.1 + 0.08 * snowIntensity)) % 0.5),
                    size: 1.6,
                    color: iconColor.withValues(alpha: 0.72),
                  ),
              ],
              Transform.translate(
                offset: Offset(0, bob),
                child: Icon(icon, color: iconColor, size: widget.size),
              ),
              if (type == WeatherVisualType.stormy && stormAlpha > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: stormAlpha),
                        borderRadius: BorderRadius.circular(widget.size),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

double tau(double t) => t * math.pi * 2;

Duration _animationDurationForCode(int code) {
  if (code == 0) return const Duration(milliseconds: 1700);
  if (code >= 95) return const Duration(milliseconds: 900);
  if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
    final i = _rainIntensityForCode(code);
    return Duration(milliseconds: 1500 - (i * 220));
  }
  if ((code >= 71 && code <= 77) || code == 85 || code == 86) {
    final i = _snowIntensityForCode(code);
    return Duration(milliseconds: 1900 - (i * 200));
  }
  return const Duration(milliseconds: 1400);
}

int _rainIntensityForCode(int code) {
  if (code == 51 || code == 61 || code == 80) return 1;
  if (code == 53 || code == 63 || code == 81 || code == 66) return 2;
  if (code == 55 || code == 65 || code == 67 || code == 82) return 3;
  return 1;
}

int _snowIntensityForCode(int code) {
  if (code == 71 || code == 85) return 1;
  if (code == 73 || code == 86 || code == 77) return 2;
  if (code == 75) return 3;
  return 1;
}

int _stormIntensityForCode(int code) {
  if (code == 95) return 1;
  if (code == 96 || code == 97) return 2;
  if (code == 99) return 3;
  return 1;
}

String? precipitationLevelTr(int code) {
  if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
    final i = _rainIntensityForCode(code);
    if (i == 1) return 'Yağış: Hafif';
    if (i == 2) return 'Yağış: Orta';
    return 'Yağış: Kuvvetli';
  }
  if ((code >= 71 && code <= 77) || code == 85 || code == 86) {
    final i = _snowIntensityForCode(code);
    if (i == 1) return 'Kar: Hafif';
    if (i == 2) return 'Kar: Orta';
    return 'Kar: Yoğun';
  }
  if (code >= 95) {
    final i = _stormIntensityForCode(code);
    if (i == 1) return 'Fırtına: Hafif';
    if (i == 2) return 'Fırtına: Orta';
    return 'Fırtına: Şiddetli';
  }
  return null;
}

class _RainDrop extends StatelessWidget {
  const _RainDrop({
    required this.left,
    required this.top,
    required this.color,
  });

  final double left;
  final double top;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: 1.8,
        height: 5.5,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

class _SnowFlake extends StatelessWidget {
  const _SnowFlake({
    required this.left,
    required this.top,
    required this.size,
    required this.color,
  });

  final double left;
  final double top;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
