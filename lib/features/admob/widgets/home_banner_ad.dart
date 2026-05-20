import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:netgulf/core/services/admob_service.dart';
import 'package:netgulf/core/services/premium_access.dart';

/// ارتفاع البانر القياسي — يُحجز مسبقاً أثناء التحميل فقط.
const _kBannerHeight = 50.0;

/// بانر AdMob أسفل الشاشة الرئيسية — للنسخة المجانية فقط.
class HomeBannerAd extends ConsumerStatefulWidget {
  const HomeBannerAd({super.key});

  @override
  ConsumerState<HomeBannerAd> createState() => _HomeBannerAdState();
}

class _HomeBannerAdState extends ConsumerState<HomeBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isLoading = false;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAd());
  }

  Future<void> _loadAd() async {
    if (_isLoading || _bannerAd != null || _loadFailed) return;
    if (!AdMobService.isSupported || !ref.read(showAdsProvider)) return;

    setState(() => _isLoading = true);

    try {
      await AdMobService.initialize();

      final banner = AdMobService.createBannerAd(
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (!mounted || !ref.read(showAdsProvider)) {
              ad.dispose();
              if (mounted) setState(() => _isLoading = false);
              return;
            }
            setState(() {
              _bannerAd = ad as BannerAd;
              _isLoaded = true;
              _isLoading = false;
              _loadFailed = false;
            });
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            if (kDebugMode) {
              debugPrint('HomeBannerAd: ${error.message}');
            }
            if (mounted) {
              setState(() {
                _isLoading = false;
                _loadFailed = true;
              });
            }
          },
        ),
      );

      await banner.load();
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadFailed = true;
        });
      }
    }
  }

  void _disposeBanner() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isLoaded = false;
    _isLoading = false;
    _loadFailed = false;
  }

  @override
  void dispose() {
    _disposeBanner();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(showAdsProvider, (previous, showAds) {
      if (!showAds) {
        _disposeBanner();
        if (mounted) setState(() {});
      } else if (_bannerAd == null && !_isLoading && !_loadFailed) {
        _loadAd();
      }
    });

    final showAds = ref.watch(showAdsProvider);

    if (!showAds || !AdMobService.isSupported) {
      return const SizedBox.shrink();
    }

    if (_loadFailed) {
      return const SizedBox.shrink();
    }

    if (!_isLoaded && !_isLoading) {
      return const SizedBox.shrink();
    }

    final height = _bannerAd?.size.height.toDouble() ?? _kBannerHeight;

    return SafeArea(
      top: false,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _isLoaded && _bannerAd != null
            ? SizedBox(
                key: const ValueKey('banner-loaded'),
                width: _bannerAd!.size.width.toDouble(),
                height: height,
                child: AdWidget(ad: _bannerAd!),
              )
            : SizedBox(
                key: const ValueKey('banner-slot'),
                height: _isLoading ? height : 0,
              ),
      ),
    );
  }
}
