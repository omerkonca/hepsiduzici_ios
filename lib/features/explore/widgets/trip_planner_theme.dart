import 'package:flutter/material.dart';

/// Gezi planlayıcı — premium koyu tema, sıcak altın + yumuşak kartlar.
class TripPlannerTheme {
  TripPlannerTheme._();

  static const Color bg = Color(0xFF0C1018);
  static const Color bgElevated = Color(0xFF121824);
  static const Color surface = Color(0xFF1A2234);
  static const Color surfaceElevated = Color(0xFF232D42);
  static const Color cardLight = Color(0xFFF5F6F8);
  static const Color cardBorder = Color(0xFFE8EAED);
  static const Color gold = Color(0xFFD4AF37);
  static const Color accent = gold;
  static const Color accentBlue = ctaBlue;
  static const Color goldMuted = Color(0xFF9A7B2E);
  static const Color textMuted = textSecondary;
  static const Color ctaBlue = Color(0xFF4D9AE8);
  static const Color ctaBlueDark = Color(0xFF2E6DB0);
  static const Color stepBlue = Color(0xFF5BA8D4);
  static const Color stepRing = Color(0xFF8EC5E8);
  static const Color textPrimary = Color(0xFFF2F4F8);
  static const Color textSecondary = Color(0xFF8B95A8);
  static const Color textOnCard = Color(0xFF151820);
  static const Color textMutedOnCard = Color(0xFF5C6370);
  static const Color chipBg = Color(0xFF1E2738);
  static const Color success = Color(0xFF3DDC84);
  static const Color amber = Color(0xFFE8A838);

  static const LinearGradient screenGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF101622), Color(0xFF0C1018)],
  );

  static const LinearGradient ctaGradient = LinearGradient(
    colors: [Color(0xFF5BA8E8), Color(0xFF3D7EC6)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFE4C04A), Color(0xFFC6A02E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient chipSelectedGradient = LinearGradient(
    colors: [Color(0xFF2A2618), Color(0xFF1E1A12)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData theme() => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(
          surface: surface,
          primary: gold,
          secondary: ctaBlue,
        ),
        appBarTheme: appBar(),
        dividerColor: Colors.white10,
      );

  static AppBarTheme appBar() => const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 17,
          letterSpacing: -0.35,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(color: textPrimary, size: 22),
      );

  static BoxDecoration surfaceCard({double radius = 20}) => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      );

  static BoxDecoration timelineCard() => BoxDecoration(
        color: cardLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static Widget primaryCta({
    required String label,
    required VoidCallback onPressed,
    IconData icon = Icons.navigation_rounded,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          decoration: BoxDecoration(
            gradient: ctaGradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: ctaBlue.withValues(alpha: 0.28),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SizedBox(
            height: 54,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget goldStepBadge(int number, {double size = 34}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: stepBlue,
        shape: BoxShape.circle,
        border: Border.all(color: stepRing, width: 2.5),
      ),
      child: Center(
        child: Text(
          '$number',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  static Widget timelineConnector({required double height, bool isLast = false}) {
    if (isLast) return const SizedBox.shrink();
    return Container(
      width: 2.5,
      height: height,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: gold.withValues(alpha: 0.55),
      ),
    );
  }
}
