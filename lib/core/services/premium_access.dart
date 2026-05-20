import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netgulf/core/models/premium_status.dart';
import 'package:netgulf/core/providers/premium_provider.dart';
import 'package:netgulf/core/services/admob_service.dart';
import 'package:netgulf/core/widgets/premium_gate_sheet.dart';

/// هل يُعرض إعلان AdMob؟ — false لمشتركي Premium فقط.
final showAdsProvider = Provider<bool>((ref) {
  return !ref.watch(isPremiumProvider);
});

/// حالة الاشتراك للعرض (Active / Expired / Not Subscribed).
final premiumSubscriptionStateProvider =
    Provider<PremiumSubscriptionState>((ref) {
  return ref.watch(premiumStatusProvider).subscriptionState;
});

/// مساعد Premium مركزي — إعلانات، بوابات، فحص الميزات.
abstract final class PremiumAccess {
  PremiumAccess._();

  /// هل المستخدم يملك Premium ساري؟ (قراءة لحظية)
  static bool isPremium(WidgetRef ref) => ref.read(isPremiumProvider);

  /// هل المستخدم يملك Premium ساري؟ (مع إ rebuild عند التغيير)
  static bool watchIsPremium(WidgetRef ref) => ref.watch(isPremiumProvider);

  /// interstitial للمجانيين فقط (مرة/جلسة).
  static Future<void> showInterstitialIfFree(WidgetRef ref) {
    return AdMobService.tryShowInterstitial(isPremium: isPremium(ref));
  }

  /// هل الميزة مقفلة؟ (عكس isPremium)
  static bool isFeatureLocked(WidgetRef ref) => !isPremium(ref);

  /// يعرض بوابة Premium إن لزم — يرجع true إذا أصبح Premium.
  static Future<bool> requirePremium(
    BuildContext context,
    WidgetRef ref, {
    required PremiumFeature feature,
  }) async {
    if (isPremium(ref)) return true;
    final upgraded = await showPremiumGate(context, feature: feature);
    return upgraded || isPremium(ref);
  }
}
