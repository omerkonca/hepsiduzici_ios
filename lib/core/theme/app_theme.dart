import 'package:flutter/material.dart';
import '../../data/models/city_content.dart';
import '../utils/color_utils.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => fromBranding(null, Brightness.light);
  static ThemeData get dark => fromBranding(null, Brightness.dark);

  /// Backend'den gelen [branding] varsa renkleri override eder, yoksa
  /// [AppColors] varsayilanlarini kullanir.
  static ThemeData fromBranding(BrandingInfo? branding, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    
    final primary = hexToColor(branding?.primaryColor, AppColors.primary);
    final primaryDark = hexToColor(branding?.primaryDarkColor, AppColors.primaryDark);
    final accentBlue = hexToColor(branding?.accentBlueColor, AppColors.accentBlue);

    final colorScheme = isDark 
      ? ColorScheme.dark(
          primary: primary,
          onPrimary: AppColors.white,
          secondary: accentBlue,
          onSecondary: AppColors.white,
          surface: AppColors.darkSurface,
          onSurface: AppColors.darkText,
          error: const Color(0xFFCF6679),
          onError: AppColors.premiumBlack,
        )
      : ColorScheme.light(
          primary: primary,
          onPrimary: AppColors.white,
          secondary: accentBlue,
          onSecondary: AppColors.white,
          surface: AppColors.surface,
          onSurface: AppColors.textDark,
          error: const Color(0xFFB00020),
          onError: AppColors.white,
        );

    final textColor = isDark ? AppColors.darkText : AppColors.textDark;
    final backgroundColor = isDark ? AppColors.darkBackground : const Color(0xFFF6F7FB);
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.darkSurface : primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        iconTheme: const IconThemeData(color: AppColors.white, size: 24),
        titleTextStyle: const TextStyle(
          color: AppColors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardTheme(
        color: surfaceColor,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: isDark 
                ? AppColors.darkCardBorder 
                : AppColors.softGrey.withValues(alpha: 0.45), 
            width: 1,
          ),
        ),
      ),
      textTheme: _buildTextTheme(textColor),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: AppColors.white,
          elevation: 0,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? primary : primaryDark,
          minimumSize: const Size(0, 44),
          side: BorderSide(
            color: (isDark ? AppColors.darkText : AppColors.textDark).withValues(alpha: 0.45), 
            width: 1.2,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: isDark ? primary : primaryDark,
        ),
      ),
      chipTheme: ChipThemeData(
        labelStyle: TextStyle(
          fontSize: 12, 
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkText : AppColors.textDark,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        backgroundColor: isDark 
            ? AppColors.darkCardBorder 
            : AppColors.softGrey.withValues(alpha: 0.3),
      ),
    );
  }

  static TextTheme _buildTextTheme(Color textColor) => TextTheme(
    headlineMedium: TextStyle(
      color: textColor,
      fontSize: 22,
      fontWeight: FontWeight.w700,
    ),
    titleLarge: TextStyle(
      color: textColor,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: TextStyle(
      color: textColor,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(
      color: textColor,
      fontSize: 16,
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: TextStyle(
      color: textColor,
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
    labelLarge: TextStyle(
      color: textColor,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
  );
}
