import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:netgulf/core/services/premium_access.dart';
import 'package:netgulf/core/services/admob_service.dart';

/// بانر AdMob أسفل الشاشة الرئيسية — للنسخة المجانية فقط.
class HomeBannerAd extends ConsumerStatefulWidget {
  const HomeBannerAd({super.key});

  @override
  ConsumerState<HomeBannerAd> createState() => _HomeBannerAdState();
}

class _HomeBannerAdState extends ConsumerState<HomeBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  void didUpdateWidget(covariant HomeBannerAd oldWidget) {
    super.didUpdateWidget(oldWidget);
    final showAds = ref.read(showAdsProvider);
    if (!showAds && _bannerAd != null) {
      _bannerAd?.dispose();
      _bannerAd = null;
      _isLoaded = false;
    } else if (showAds && _bannerAd == null) {
      _loadAd();
    }
  }

  Future<void> _loadAd() async {
    if (!AdMobService.isSupported || !ref.read(showAdsProvider)) return;

    await AdMobService.initialize();

    final banner = AdMobService.createBannerAd(
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted || !ref.read(showAdsProvider)) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('HomeBannerAd failed: ${error.message}');
        },
      ),
    );

    await banner.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(showAdsProvider, (previous, showAds) {
      if (!showAds) {
        _bannerAd?.dispose();
        _bannerAd = null;
        if (_isLoaded) {
          setState(() => _isLoaded = false);
        }
      } else if (_bannerAd == null) {
        _loadAd();
      }
    });

    final showAds = ref.watch(showAdsProvider);

    if (!showAds ||
        !AdMobService.isSupported ||
        !_isLoaded ||
        _bannerAd == null) {
      return const SizedBox.shrink();
    }

    final height = _bannerAd!.size.height.toDouble();

    return SafeArea(
      top: false,
      child: SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: height,
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
