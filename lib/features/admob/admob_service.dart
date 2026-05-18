import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// تهيئة AdMob ومعرّفات الإعلانات التجريبية.
class AdMobService {
  AdMobService._();

  /// Google test app IDs (استبدلها بمعرّفاتك في الإنتاج).
  static const String androidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const String iosAppId = 'ca-app-pub-3940256099942544~1458002511';

  /// Google test banner unit IDs.
  static const String androidBannerTestId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String iosBannerTestId =
      'ca-app-pub-3940256099942544/2934735716';

  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  /// هل المنصة الحالية تدعم إعلانات AdMob.
  static bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// تهيئة SDK — استدعِها مرة من [AppInitializer] أو main.
  static Future<void> initialize() async {
    if (_initialized || !isSupported) return;
    await MobileAds.instance.initialize();
    _initialized = true;
  }

  /// معرّف وحدة البانر حسب المنصة.
  static String get bannerAdUnitId {
    if (Platform.isAndroid) return androidBannerTestId;
    if (Platform.isIOS) return iosBannerTestId;
    throw UnsupportedError('AdMob banners are only supported on Android/iOS.');
  }

  /// إنشاء طلب بانر قياسي.
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
}
