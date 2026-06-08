import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ad_config.dart';

/// Banner ve geçiş (interstitial) reklam yönetimi.
class AdService {
  AdService._();

  static final AdService instance = AdService._();

  bool _initialized = false;
  InterstitialAd? _interstitial;
  bool _loadingInterstitial = false;
  DateTime? _lastInterstitialShownAt;
  Timer? _sessionTimer;
  bool _isForeground = true;

  /// Uygulamada bu kadar süre geçince geçiş reklamı gösterilir.
  static const Duration sessionInterstitialInterval = Duration(minutes: 4);

  /// İki geçiş reklamı arasındaki minimum süre.
  static const Duration _minInterstitialInterval = Duration(minutes: 2);

  Future<void> initialize() async {
    if (!AdConfig.adsEnabled || _initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      preloadInterstitial();
    } catch (e) {
      debugPrint('[AdService] init failed: $e');
    }
  }

  /// Ana ekranda uygulama açıkken periyodik geçiş reklamı zamanlayıcısı.
  void startSessionTimer() {
    if (!AdConfig.adsEnabled || !_initialized) return;
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(sessionInterstitialInterval, (_) {
      if (_isForeground) {
        showSessionInterstitial();
      }
    });
  }

  void onAppLifecycle(bool isForeground) {
    _isForeground = isForeground;
    if (isForeground) {
      startSessionTimer();
    } else {
      _sessionTimer?.cancel();
      _sessionTimer = null;
    }
  }

  void preloadInterstitial() {
    if (!AdConfig.adsEnabled || !_initialized || _loadingInterstitial) return;
    if (!AdConfig.interstitialAdsReady) return;
    if (_interstitial != null) return;

    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: AdConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _loadingInterstitial = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdService] interstitial load failed: $error');
          _loadingInterstitial = false;
        },
      ),
    );
  }

  bool get _canShowInterstitial {
    if (!AdConfig.adsEnabled || !_initialized) return false;
    final last = _lastInterstitialShownAt;
    if (last == null) return true;
    return DateTime.now().difference(last) >= _minInterstitialInterval;
  }

  /// Uygulamada belirli süre kaldıktan sonra çağrılır.
  Future<void> showSessionInterstitial() async {
    await _showInterstitial();
  }

  Future<void> _showInterstitial() async {
    if (!AdConfig.interstitialAdsReady) return;
    if (!_canShowInterstitial) return;

    final ad = _interstitial;
    if (ad == null) {
      preloadInterstitial();
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (dismissed) {
        dismissed.dispose();
        _interstitial = null;
        preloadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (failed, error) {
        debugPrint('[AdService] interstitial show failed: $error');
        failed.dispose();
        _interstitial = null;
        preloadInterstitial();
      },
    );

    _lastInterstitialShownAt = DateTime.now();
    _interstitial = null;
    await ad.show();
  }

  void dispose() {
    _sessionTimer?.cancel();
    _interstitial?.dispose();
    _interstitial = null;
  }
}
