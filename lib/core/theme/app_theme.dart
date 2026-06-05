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
    final backgroundColor = isDark ? AppColors.darkBackground : const Color(0xFFF5F7FB);
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        toolbarHeight: 56,
        iconTheme: IconThemeData(color: textColor, size: 20),
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 19,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.6,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark 
                ? AppColors.darkCardBorder 
                : AppColors.softGrey.withValues(alpha: 0.42), 
            width: 1,
          ),
        ),
      ),
      textTheme: _buildTextTheme(textColor),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        hintStyle: TextStyle(
          color: textColor.withValues(alpha: 0.45),
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: textColor.withValues(alpha: 0.12),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: textColor.withValues(alpha: 0.12),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: primary.withValues(alpha: 0.55),
            width: 1.4,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: textColor.withValues(alpha: 0.08),
        thickness: 1,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        iconColor: primaryDark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: AppColors.white,
          elevation: 0,
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
          minimumSize: const Size(0, 40),
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
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor.withValues(alpha: isDark ? 0.9 : 0.97),
        indicatorColor: primary.withValues(alpha: 0.16),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? primaryDark : textColor.withValues(alpha: 0.55),
            size: 20,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 10.5,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? primaryDark : textColor.withValues(alpha: 0.6),
          );
        }),
      ),
    );
  }

  static TextTheme _buildTextTheme(Color textColor) => TextTheme(
    displaySmall: TextStyle(
      color: textColor,
      fontSize: 30,
      fontWeight: FontWeight.w900,
      letterSpacing: -1.0,
    ),
    headlineMedium: TextStyle(
      color: textColor,
      fontSize: 22,
      fontWeight: FontWeight.w900,
      letterSpacing: -0.8,
    ),
    headlineSmall: TextStyle(
      color: textColor,
      fontSize: 26,
      fontWeight: FontWeight.w900,
      letterSpacing: -1.0,
    ),
    titleLarge: TextStyle(
      color: textColor,
      fontSize: 18,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.4,
    ),
    titleMedium: TextStyle(
      color: textColor,
      fontSize: 16,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.25,
    ),
    bodyLarge: TextStyle(
      color: textColor,
      fontSize: 15,
      fontWeight: FontWeight.w500,
      height: 1.32,
    ),
    bodyMedium: TextStyle(
      color: textColor,
      fontSize: 13.5,
      fontWeight: FontWeight.w500,
      height: 1.32,
    ),
    labelLarge: TextStyle(
      color: textColor,
      fontSize: 13,
      fontWeight: FontWeight.w700,
    ),
  );
}
