import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Keşfet / Gezi Rehberi listesi — açık mod, tek palet.
class ExploreListTheme {
  ExploreListTheme._();

  static const Color background = Color(0xFFF6F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF0F2F6);
  static const Color border = Color(0xFFE4E8EF);
  static const Color textPrimary = Color(0xFF1A2332);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  static const LinearGradient headerBanner = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFF9EE), Color(0xFFFFF0D6)],
  );

  static const Color segmentActive = AppColors.primaryDark;
  static const Color chipSelected = AppColors.primaryDark;
  static const Color chipUnselectedBg = surface;
  static const Color chipUnselectedBorder = border;

  static BoxDecoration cardDecoration() => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration searchFieldDecoration() => BoxDecoration(
        color: surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      );

  static BoxDecoration infoPanelDecoration() => BoxDecoration(
        gradient: headerBanner,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      );

  static TextStyle sectionTitleStyle() => const TextStyle(
        fontWeight: FontWeight.w900,
        fontSize: 18,
        color: textPrimary,
        letterSpacing: -0.4,
      );

  static TextStyle sectionSubtitleStyle() => const TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 13,
        color: textSecondary,
        height: 1.4,
      );
}
