import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob — بانر + interstitial (مرة واحدة لكل جلسة).
class AdMobService {
  AdMobService._();

  // ── Test IDs (استبدلها في الإنتاج) ───────────────────────────────────────

  static const String androidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const String iosAppId = 'ca-app-pub-3940256099942544~1458002511';

  static const String androidBannerTestId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String iosBannerTestId =
      'ca-app-pub-3940256099942544/2934735716';

  static const String androidInterstitialTestId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String iosInterstitialTestId =
      'ca-app-pub-3940256099942544/4411468910';

  static bool _initialized = false;
  static bool _interstitialShownThisSession = false;
  static InterstitialAd? _interstitialAd;
  static bool _interstitialLoading = false;

  static bool get isInitialized => _initialized;

  static bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// تهيئة SDK — مرة واحدة من [AppInitializer].
  static Future<void> initialize() async {
    if (_initialized || !isSupported) return;
    await MobileAds.instance.initialize();
    _initialized = true;
    preloadInterstitial();
  }

  static String get bannerAdUnitId {
    if (Platform.isAndroid) return androidBannerTestId;
    if (Platform.isIOS) return iosBannerTestId;
    throw UnsupportedError('AdMob banners are only supported on Android/iOS.');
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) return androidInterstitialTestId;
    if (Platform.isIOS) return iosInterstitialTestId;
    throw UnsupportedError(
      'AdMob interstitials are only supported on Android/iOS.',
    );
  }

  static BannerAd createBannerAd({
    required BannerAdListener listener,
    AdSize size = AdSize.banner,
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: listener,
    );
  }

  /// يحمّل interstitial مسبقاً للعرض السريع.
  static void preloadInterstitial() {
    if (!isSupported || _interstitialLoading || _interstitialAd != null) return;
    _interstitialLoading = true;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialLoading = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              preloadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              _interstitialLoading = false;
              if (kDebugMode) {
                debugPrint('Interstitial show failed: ${error.message}');
              }
              preloadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _interstitialLoading = false;
          if (kDebugMode) {
            debugPrint('Interstitial load failed: ${error.message}');
          }
        },
      ),
    );
  }

  /// يعرض interstitial مرة واحدة لكل جلسة (بعد حفظ راتب أو تصدير PDF).
  static Future<void> tryShowInterstitial() async {
    if (!isSupported || _interstitialShownThisSession) return;

    final ad = _interstitialAd;
    if (ad == null) {
      preloadInterstitial();
      return;
    }

    _interstitialShownThisSession = true;
    ad.show();
    _interstitialAd = null;
  }

  static void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
