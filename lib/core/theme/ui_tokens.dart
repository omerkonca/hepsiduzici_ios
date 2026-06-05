import 'package:flutter/material.dart';

class UiTokens {
  UiTokens._();

  static const double radiusCard = 20;
  static const double radiusControl = 16;
  static const double radiusPill = 999;

  static const EdgeInsets pageHorizontal = EdgeInsets.symmetric(horizontal: 16);

  static List<BoxShadow> softShadow({double opacity = 0.05}) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: opacity),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ];
}

