import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

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

  @override
  void initState() {
    super.initState();
    if (!AdConfig.adsEnabled) return;

    final banner = BannerAd(
      adUnitId: AdConfig.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) setState(() => _loaded = false);
        },
      ),
    );
    _banner = banner;
    banner.load();
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
