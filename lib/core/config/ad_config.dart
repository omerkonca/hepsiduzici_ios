import 'package:flutter/foundation.dart';

/// AdMob kimlikleri.
///
/// Canlı yayın için `android/admob.properties` dosyasına App ID yazın ve
/// aşağıdaki `--dart-define` değerlerini build komutuna ekleyin:
///
/// flutter build appbundle --release \
///   --dart-define=ADMOB_BANNER_ANDROID=ca-app-pub-xxx/yyy \
///   --dart-define=ADMOB_INTERSTITIAL_ANDROID=ca-app-pub-xxx/zzz
class AdConfig {
  AdConfig._();

  static const String _bannerAndroid =
      String.fromEnvironment('ADMOB_BANNER_ANDROID');
  static const String _interstitialAndroid =
      String.fromEnvironment('ADMOB_INTERSTITIAL_ANDROID');
  static const String _bannerIos = String.fromEnvironment('ADMOB_BANNER_IOS');
  static const String _interstitialIos =
      String.fromEnvironment('ADMOB_INTERSTITIAL_IOS');
  static const bool _forceTestAds =
      bool.fromEnvironment('ADMOB_USE_TEST_ADS', defaultValue: false);

  // Hepsi Düziçi — canlı AdMob birimleri (Android)
  static const String prodAppIdAndroid =
      'ca-app-pub-5097523004889494~5039235533';
  static const String prodBannerAndroid =
      'ca-app-pub-5097523004889494/1099990521';
  static const String prodInterstitialAndroid =
      'ca-app-pub-5097523004889494/1777657698';

  // Hepsi Düziçi — canlı AdMob birimleri (iOS)
  static const String prodAppIdIos =
      'ca-app-pub-5097523004889494~5837842118';
  static const String prodBannerIos =
      'ca-app-pub-5097523004889494/5988365443';
  static const String prodInterstitialIos =
      'ca-app-pub-5097523004889494/9109352803';

  // Google resmi test birimleri
  static const String testBannerAndroid =
      'ca-app-pub-3940256099942544/6300978111';
  static const String testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const String testBannerIos = 'ca-app-pub-3940256099942544/2934735716';
  static const String testInterstitialIos =
      'ca-app-pub-3940256099942544/4411468910';

  static bool get adsEnabled =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static bool get useTestAds => kDebugMode || _forceTestAds;

  static bool get _isIos => defaultTargetPlatform == TargetPlatform.iOS;

  static String get bannerAdUnitId {
    if (useTestAds) {
      return _isIos ? testBannerIos : testBannerAndroid;
    }
    if (_isIos) {
      if (_bannerIos.isNotEmpty) return _bannerIos;
      return prodBannerIos;
    }
    if (_bannerAndroid.isNotEmpty) return _bannerAndroid;
    return prodBannerAndroid;
  }

  static String get interstitialAdUnitId {
    if (useTestAds) {
      return _isIos ? testInterstitialIos : testInterstitialAndroid;
    }
    if (_isIos) {
      if (_interstitialIos.isNotEmpty) return _interstitialIos;
      if (prodInterstitialIos.isNotEmpty) return prodInterstitialIos;
      return testInterstitialIos;
    }
    if (_interstitialAndroid.isNotEmpty) return _interstitialAndroid;
    if (prodInterstitialAndroid.isNotEmpty) return prodInterstitialAndroid;
    return testInterstitialAndroid;
  }

  static bool get interstitialAdsReady =>
      useTestAds ||
      _interstitialAndroid.isNotEmpty ||
      prodInterstitialAndroid.isNotEmpty ||
      _interstitialIos.isNotEmpty ||
      prodInterstitialIos.isNotEmpty;
}
