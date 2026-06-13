import 'dart:async';
import 'dart:developer' as developer;

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ad_config.dart';

/// Banner ve geçiş (interstitial) reklam yönetimi.
class AdService {
  AdService._();

  static final AdService instance = AdService._();

  bool _initialized = false;
  bool _attHandled = false;
  TrackingStatus? _attStatus;
  Future<void>? _initFuture;
  InterstitialAd? _interstitial;
  bool _loadingInterstitial = false;
  DateTime? _lastInterstitialShownAt;
  Timer? _sessionTimer;
  bool _isForeground = true;

  /// Uygulamada bu kadar süre geçince geçiş reklamı gösterilir.
  static const Duration sessionInterstitialInterval = Duration(minutes: 8);

  /// İki geçiş reklamı arasındaki minimum süre.
  static const Duration _minInterstitialInterval = Duration(minutes: 2);

  bool get isInitialized => _initialized;

  /// ATT reddedildiyse kişiselleştirilmemiş reklam isteği (iOS doldurma oranı).
  AdRequest get adRequest {
    final limited = _attStatus == TrackingStatus.denied ||
        _attStatus == TrackingStatus.restricted;
    return AdRequest(nonPersonalizedAds: limited);
  }

  Future<void> initialize() => ensureInitialized();

  Future<void> ensureInitialized() {
    if (_initialized) return Future<void>.value();
    return _initFuture ??= _doInitialize();
  }

  Future<void> _doInitialize() async {
    if (!AdConfig.adsEnabled) return;
    try {
      await _requestAttIfNeeded();
      final status = await MobileAds.instance.initialize();
      _initialized = true;
      _logAd('MobileAds initialized (${AdConfig.bannerAdUnitId})');
      for (final entry in status.adapterStatuses.entries) {
        _logAd('adapter ${entry.key}: ${entry.value.description}');
      }
      preloadInterstitial();
    } catch (e, st) {
      _logAd('init failed: $e', error: e, stackTrace: st);
      _initFuture = null;
    }
  }

  Future<void> _requestAttIfNeeded() async {
    if (_attHandled || defaultTargetPlatform != TargetPlatform.iOS) return;
    _attHandled = true;
    try {
      var status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        status = await AppTrackingTransparency.requestTrackingAuthorization();
      }
      _attStatus = status;
      _logAd('ATT status: $status');
    } catch (e) {
      _logAd('ATT failed: $e');
    }
  }

  void _logAd(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(message, name: 'AdService', error: error, stackTrace: stackTrace);
    if (kDebugMode) {
      debugPrint('[AdService] $message');
    }
  }

  /// Ana ekranda uygulama açıkken periyodik geçiş reklamı zamanlayıcısı.
  void startSessionTimer() {
    if (!AdConfig.adsEnabled) return;
    ensureInitialized().then((_) {
      if (!_initialized) return;
      _sessionTimer?.cancel();
      _sessionTimer = Timer.periodic(sessionInterstitialInterval, (_) {
        if (_isForeground) {
          showSessionInterstitial();
        }
      });
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
      request: adRequest,
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _loadingInterstitial = false;
        },
        onAdFailedToLoad: (error) {
          _logAd('interstitial load failed: $error');
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
        _logAd('interstitial show failed: $error');
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
