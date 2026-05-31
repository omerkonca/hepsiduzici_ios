import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class LauncherUtils {
  LauncherUtils._();

  static Future<void> openWhatsApp(
    BuildContext context,
    String rawPhone, {
    String? message,
  }) async {
    var digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) digits = '90${digits.substring(1)}';
    if (!digits.startsWith('90') && digits.length == 10) digits = '90$digits';
    final text = message != null ? '&text=${Uri.encodeComponent(message)}' : '';
    final uri = Uri.parse('https://wa.me/$digits$text');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      _showError(context, 'WhatsApp açılamadı.');
    }
  }

  static Future<void> callPhone(
    BuildContext context,
    String rawPhone,
  ) async {
    final cleaned = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleaned');
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      _showError(context, 'Arama başlatılamadı.');
    }
  }

  /// Haritada ara (konum gösterir).
  static Future<void> openMapsWithAddress(
    BuildContext context,
    String address,
  ) async {
    final query = Uri.encodeComponent(_normalizeAddress(address));
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      _showError(context, 'Harita açılamadı.');
    }
  }

  /// Rota al (mevcut konumdan hedefe yol tarifi – navigasyon).
  static Future<void> openMapsDirections(
    BuildContext context,
    String destinationAddress,
  ) async {
    final destination = Uri.encodeComponent(_normalizeAddress(destinationAddress));
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$destination&travelmode=driving',
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      _showError(context, 'Rota açılamadı.');
    }
  }

  static String _normalizeAddress(String address) {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return 'Düziçi, Osmaniye';
    if (trimmed.toLowerCase().startsWith('düziçi') ||
        trimmed.toLowerCase().startsWith('duzici')) {
      return trimmed;
    }
    return 'Düziçi, Osmaniye $trimmed';
  }

  static Future<void> openMapsWithLatLng(
    BuildContext context,
    double lat,
    double lng,
  ) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      _showError(context, 'Konum açılamadı.');
    }
  }

  static Future<void> openUrlExternal(
    BuildContext context,
    String url,
  ) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (context.mounted) _showError(context, 'Geçersiz bağlantı.');
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      _showError(context, 'Bağlantı açılamadı.');
    }
  }

  static Future<void> launchURL(String urlString) async {
    final uri = Uri.tryParse(urlString);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> openMaps(String location, String city) async {
    final query = Uri.encodeComponent('$location, $city');
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<void> shareText(String text, {String? subject}) async {
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: subject,
      ),
    );
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
