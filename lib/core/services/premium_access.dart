import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netgulf/core/models/premium_status.dart';
import 'package:netgulf/core/providers/premium_provider.dart';
import 'package:netgulf/core/services/admob_service.dart';

/// هل يُعرض إعلان AdMob؟ — false لمشتركي Premium فقط.
final showAdsProvider = Provider<bool>((ref) {
  return !ref.watch(isPremiumProvider);
});

/// حالة الاشتراك للعرض (Active / Expired / Not Subscribed).
final premiumSubscriptionStateProvider = Provider<PremiumSubscriptionState>((ref) {
  return ref.watch(premiumStatusProvider).subscriptionState;
});

/// مساعد Premium مركزي — إعلانات، بوابات، فحص الميزات.
abstract final class PremiumAccess {
  PremiumAccess._();

  /// هل المستخدم يملك Premium ساري؟
  static bool isPremium(WidgetRef ref) => ref.read(isPremiumProvider);

  /// interstitial للمجانيين فقط (مرة/جلسة).
  static Future<void> showInterstitialIfFree(WidgetRef ref) {
    return AdMobService.tryShowInterstitial(isPremium: isPremium(ref));
  }

  /// هل الميزة مقفلة؟ (عكس isPremium)
  static bool isFeatureLocked(WidgetRef ref) => !isPremium(ref);
}
