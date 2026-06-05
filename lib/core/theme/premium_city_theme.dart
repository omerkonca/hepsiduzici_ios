import 'package:flutter/material.dart';

import 'app_colors.dart';

class PremiumCityTheme {
  PremiumCityTheme._();

  static const Color gold = AppColors.primary;
  static const Color navy = Color(0xFF0F2744);
  static const Color ink = Color(0xFF111827);
  static const Color muted = Color(0xFF6B7280);
  static const Color canvas = Color(0xFFF6F7FB);
  static const Color mist = Color(0xFFEFF3F8);

  static const double radius = 24;
  static const double radiusLarge = 28;

  static const double pagePadding = 12;
  static const double sectionSpacing = 14;
  static const double sectionTitleSize = 16;
  static const double sectionHeaderGap = 8;

  static BorderRadius get borderRadius => BorderRadius.circular(radius);
  static BorderRadius get borderRadiusLarge =>
      BorderRadius.circular(radiusLarge);

  static List<BoxShadow> softShadow(
      {Color color = Colors.black, double alpha = 0.10}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: alpha),
        blurRadius: 34,
        spreadRadius: -16,
        offset: const Offset(0, 18),
      ),
    ];
  }

  static BoxDecoration glass({
    double radius = PremiumCityTheme.radius,
    Color color = Colors.white,
    double alpha = 0.72,
  }) {
    return BoxDecoration(
      color: color.withValues(alpha: alpha),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.70)),
      boxShadow: softShadow(),
    );
  }

  static BoxDecoration card({
    double radius = PremiumCityTheme.radius,
    Color color = Colors.white,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFFE7ECF2)),
      boxShadow: softShadow(alpha: 0.07),
    );
  }

  static const LinearGradient navyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF14365C), navy, Color(0xFF071725)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFE6A4), gold, Color(0xFFB88416)],
  );
}
