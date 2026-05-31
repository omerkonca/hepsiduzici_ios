import 'package:flutter/material.dart';

/// Mekan ziyaret bilgisi: otopark, WC, giriş ücreti (JSON + canlı OSM).
class PlaceFacilityLabels {
  PlaceFacilityLabels._();

  static String parking(String? value) {
    switch (value?.toLowerCase()) {
      case 'var':
      case 'yes':
        return 'Otopark var';
      case 'ucretli':
      case 'paid':
        return 'Ücretli otopark';
      case 'sinirli':
      case 'limited':
        return 'Sınırlı otopark';
      case 'yok':
      case 'no':
        return 'Otopark yok';
      default:
        return 'Otopark bilinmiyor';
    }
  }

  static String restroom(String? value) {
    switch (value?.toLowerCase()) {
      case 'var':
      case 'yes':
        return 'WC var';
      case 'yok':
      case 'no':
        return 'WC yok';
      default:
        return 'WC bilinmiyor';
    }
  }

  static String entryFee(String? value, {String? note}) {
    if (note != null && note.trim().isNotEmpty) return note.trim();
    switch (value?.toLowerCase()) {
      case 'ucretsiz':
      case 'free':
        return 'Giriş ücretsiz';
      case 'ucretli':
      case 'paid':
        return 'Giriş ücretli';
      default:
        return 'Giriş ücreti bilinmiyor';
    }
  }

  static IconData parkingIcon(String? value) {
    switch (value?.toLowerCase()) {
      case 'var':
      case 'yes':
        return Icons.local_parking_rounded;
      case 'ucretli':
      case 'paid':
        return Icons.paid_rounded;
      case 'sinirli':
      case 'limited':
        return Icons.local_parking_outlined;
      case 'yok':
      case 'no':
        return Icons.no_crash_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  static IconData restroomIcon(String? value) {
    switch (value?.toLowerCase()) {
      case 'var':
      case 'yes':
        return Icons.wc_rounded;
      case 'yok':
      case 'no':
        return Icons.not_interested_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  static IconData entryFeeIcon(String? value) {
    switch (value?.toLowerCase()) {
      case 'ucretsiz':
      case 'free':
        return Icons.volunteer_activism_rounded;
      case 'ucretli':
      case 'paid':
        return Icons.payments_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  static bool parkingPositive(String? value) =>
      value == 'var' || value == 'yes' || value == 'sinirli' || value == 'limited' || value == 'ucretli' || value == 'paid';

  static bool restroomPositive(String? value) => value == 'var' || value == 'yes';
}
