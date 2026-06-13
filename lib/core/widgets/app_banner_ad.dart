import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ads/ad_service.dart';
import '../config/ad_config.dart';

/// AdMob banner — alt menü veya içerik içi kullanım.
class AppBannerAd extends StatefulWidget {
  const AppBannerAd({super.key, this.inline = false});

  /// Scroll içinde (haber detayı vb.) gösterim için.
  final bool inline;

  @override
  State<AppBannerAd> createState() => _AppBannerAdState();
}

class _AppBannerAdState extends State<AppBannerAd> {
  BannerAd? _banner;
  bool _loaded = false;
  int _loadAttempts = 0;
  static const _maxAttempts = 4;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBanner());
  }

  Future<AdSize> _resolveBannerSize(double width) async {
    if (width < 320) return AdSize.banner;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final portrait = await AdSize.getAnchoredAdaptiveBannerAdSize(
        Orientation.portrait,
        width.truncate(),
      );
      if (portrait != null) return portrait;
    }

    final adaptive =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width.truncate());
    return adaptive ?? AdSize.banner;
  }

  Future<void> _loadBanner() async {
    if (!AdConfig.adsEnabled || !mounted) return;

    await AdService.instance.ensureInitialized();
    if (!mounted || !AdService.instance.isInitialized) return;

    final width = MediaQuery.sizeOf(context).width;
    if (width <= 0) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (mounted) return _loadBanner();
    }

    final adSize = await _resolveBannerSize(width);
    if (!mounted) return;

    _banner?.dispose();
    _loaded = false;

    final banner = BannerAd(
      adUnitId: AdConfig.bannerAdUnitId,
      size: adSize,
      request: AdService.instance.adRequest,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() => _loaded = true);
          if (kDebugMode) {
            debugPrint('[AppBannerAd] loaded (${AdConfig.bannerAdUnitId})');
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (kDebugMode) {
            debugPrint(
              '[AppBannerAd] failed (${AdConfig.bannerAdUnitId}): $error',
            );
          }
          if (!mounted) return;
          setState(() {
            _loaded = false;
            _banner = null;
          });
          _loadAttempts++;
          if (_loadAttempts < _maxAttempts) {
            Future<void>.delayed(
              Duration(seconds: 3 * _loadAttempts),
              _loadBanner,
            );
          }
        },
      ),
    );

    setState(() => _banner = banner);
    await banner.load();
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdConfig.adsEnabled || _banner == null || !_loaded) {
      return const SizedBox.shrink();
    }

    final banner = _banner!;
    final adBox = SizedBox(
      width: double.infinity,
      height: banner.size.height.toDouble(),
      child: Center(child: AdWidget(ad: banner)),
    );

    if (widget.inline) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: adBox,
      );
    }

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        child: adBox,
      ),
    );
  }
}
