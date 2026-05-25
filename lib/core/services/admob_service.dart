import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// موضع عرض الإعلان البيني — interstitial placement per user action.
enum InterstitialPlacement {
  /// بعد حفظ الراتب — after salary save.
  salarySave,

  /// بعد محاولة تصدير PDF — after PDF export attempt.
  pdfExport,
}

/// AdMob — بانر + interstitial (test IDs — استبدلها قبل الإنتاج).
/// AdMob service — banner + interstitial ads for free-tier users.
class AdMobService {
  AdMobService._();

  // ── Test IDs (Google official sample — replace before production) ───────────

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
  static InterstitialAd? _interstitialAd;
  static bool _interstitialLoading = false;

  /// مرة واحدة لكل موضع في الجلسة — once per placement per session.
  static final Set<InterstitialPlacement> _shownPlacements = {};

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
    required AdSize size,
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: listener,
    );
  }

  /// حجم بانر متكيّف بعرض الشاشة — adaptive anchored banner size.
  static Future<AdSize?> adaptiveBannerSize(int width) {
    return AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
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

  /// يعرض interstitial للمستخدم المجاني — مرة واحدة لكل [placement] في الجلسة.
  static Future<void> tryShowInterstitial({
    required InterstitialPlacement placement,
    bool isPremium = false,
  }) async {
    if (isPremium || !isSupported || _shownPlacements.contains(placement)) {
      return;
    }

    final ad = _interstitialAd;
    if (ad == null) {
      preloadInterstitial();
      return;
    }

    _shownPlacements.add(placement);
    ad.show();
    _interstitialAd = null;
    preloadInterstitial();
  }

  static void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _shownPlacements.clear();
  }
}
