import '../config/app_config.dart';

/// Admin panelinden gelen `/uploads/...` ve Cloudinary URL'lerini uygulamada yüklenebilir hale getirir.
class MediaUrlResolver {
  MediaUrlResolver._();

  static String resolve(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return trimmed;

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    if (trimmed.startsWith('/uploads/')) {
      return '${AppConfig.backendBaseUrl}$trimmed';
    }

    if (trimmed.startsWith('uploads/')) {
      return '${AppConfig.backendBaseUrl}/$trimmed';
    }

    // Paket içi asset yolları olduğu gibi kalır.
    return trimmed;
  }

  static bool isBundledAsset(String url) {
    return url.trim().startsWith('assets/');
  }

  static bool shouldLoadFromNetwork(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return false;
    if (isBundledAsset(trimmed)) return false;
    return trimmed.startsWith('http') ||
        trimmed.startsWith('/uploads/') ||
        trimmed.startsWith('uploads/') ||
        trimmed.contains('cloudinary.com');
  }

  static String? resolvedOrNull(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    return resolve(url);
  }
}
