import 'package:flutter/material.dart';

class UiTokens {
  UiTokens._();

  static const double radiusCard = 24;
  static const double radiusControl = 18;
  static const double radiusPill = 999;

  static const EdgeInsets pageHorizontal = EdgeInsets.symmetric(horizontal: 20);

  static List<BoxShadow> softShadow({double opacity = 0.05}) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: opacity),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ];
}

