import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../data/models/city_content.dart';
import '../../data/services/place_image_policy.dart';
import '../../data/services/place_photo_service.dart';

/// Önce backend (Wikipedia/OSM), hata olursa JSON veya Unsplash.
class PlaceNetworkImage extends StatelessWidget {
  const PlaceNetworkImage({
    super.key,
    required this.place,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.heroTag,
    this.maxHeight = 800,
  });

  final ExplorePlace place;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String? heroTag;
  final int maxHeight;

  @override
  Widget build(BuildContext context) {
    final local = PlaceImagePolicy.safeContentImage(place);
    final isBundledAsset = local != null && local.startsWith('assets/');
    final isTrustedRemote = local != null && !isBundledAsset;

    Widget image;
    if (isBundledAsset) {
      image = Image.asset(
        local,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _placeholder(context),
      );
    } else if (isTrustedRemote) {
      // Onaylı/güvenilir görsel varsa doğrudan onu göster.
      image = _NetworkImageWithFallback(
        primaryUrl: local,
        fallbackUrl: PlacePhotoService.heroUrl(place, maxHeight: maxHeight),
        width: width,
        height: height,
        fit: fit,
      );
    } else {
      // Güvenilir içerik görseli yoksa dinamik servise düş.
      image = _NetworkImageWithFallback(
        primaryUrl: PlacePhotoService.heroUrl(place, maxHeight: maxHeight),
        fallbackUrl: _networkFallbackUrl(place),
        width: width,
        height: height,
        fit: fit,
      );
    }

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }
    if (heroTag != null) {
      image = Hero(tag: heroTag!, child: image);
    }
    return image;
  }

  static String? _networkFallbackUrl(ExplorePlace place) {
    final local = PlaceImagePolicy.safeContentImage(place);
    if (local == null || local.isEmpty || local.startsWith('assets/')) return null;
    final api = PlacePhotoService.heroUrl(place);
    return local != api ? local : null;
  }

  static Widget _placeholder(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.landscape_rounded, color: Theme.of(context).colorScheme.outline),
      ),
    );
  }
}

class _NetworkImageWithFallback extends StatefulWidget {
  const _NetworkImageWithFallback({
    required this.primaryUrl,
    this.fallbackUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final String primaryUrl;
  final String? fallbackUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  State<_NetworkImageWithFallback> createState() => _NetworkImageWithFallbackState();
}

class _NetworkImageWithFallbackState extends State<_NetworkImageWithFallback> {
  bool _useFallback = false;

  @override
  Widget build(BuildContext context) {
    final url = _useFallback && widget.fallbackUrl != null ? widget.fallbackUrl! : widget.primaryUrl;
    return CachedNetworkImage(
      imageUrl: url,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      placeholder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (_, __, ___) {
        if (!_useFallback && widget.fallbackUrl != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _useFallback = true);
          });
        }
        return Container(
          width: widget.width,
          height: widget.height,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(Icons.landscape_rounded, color: Theme.of(context).colorScheme.outline),
        );
      },
    );
  }
}
