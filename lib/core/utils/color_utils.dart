import 'package:flutter/material.dart';

/// "#RRGGBB" veya "RRGGBB" hex stringini Color'a cevirir.
/// Gecersiz girdi icin [fallback] doner.
Color hexToColor(String? hex, Color fallback) {
  if (hex == null) return fallback;
  var s = hex.trim().replaceAll('#', '');
  if (s.length == 3) {
    s = s.split('').map((c) => '$c$c').join();
  }
  if (s.length == 6) {
    final n = int.tryParse('FF$s', radix: 16);
    if (n != null) return Color(n);
  } else if (s.length == 8) {
    final n = int.tryParse(s, radix: 16);
    if (n != null) return Color(n);
  }
  return fallback;
}
