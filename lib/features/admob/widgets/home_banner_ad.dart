import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:netpay_ksa/features/admob/admob_service.dart';

/// بانر AdMob أسفل الشاشة الرئيسية.
class HomeBannerAd extends StatefulWidget {
  const HomeBannerAd({super.key});

  @override
  State<HomeBannerAd> createState() => _HomeBannerAdState();
}

class _HomeBannerAdState extends State<HomeBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    if (!AdMobService.isSupported) return;

    await AdMobService.initialize();

    final banner = AdMobService.createBannerAd(
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
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
    if (!AdMobService.isSupported || !_isLoaded || _bannerAd == null) {
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
