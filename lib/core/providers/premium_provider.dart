import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netgulf/core/bootstrap/app_initializer.dart';
import 'package:netgulf/core/constants/app_constants.dart';
import 'package:netgulf/core/models/premium_status.dart';

/// إدارة Premium — SharedPreferences الآن، RevenueCat / IAP لاحقاً.
class PremiumNotifier extends StateNotifier<PremiumStatus> {
  PremiumNotifier() : super(const PremiumStatus()) {
    _load();
  }

  static const _subscriptionDays = 365;

  Future<void> _load() async {
    try {
      final prefs = AppInitializer.prefs;
      final active = prefs.getBool(AppConstants.prefPremiumActive) ?? false;
      final expiryRaw = prefs.getString(AppConstants.prefPremiumExpiresAt);
      final expiresAt =
          expiryRaw != null ? DateTime.tryParse(expiryRaw) : null;

      var status = PremiumStatus(
        premiumStatus: active,
        expiresAt: expiresAt,
      );

      // احتفظ بحالة "منتهٍ" للعرض — لا تمسح السجل تلقائياً.
      state = status;
    } catch (_) {
      state = const PremiumStatus();
    }
  }

  /// هل المستخدم Premium حالياً؟
  bool isPremium() => state.isValid;

  /// شراء Premium (محاكاة — استبدل بـ in_app_purchase).
  Future<bool> purchasePremium() async {
    try {
      final expiresAt = DateTime.now().add(const Duration(days: _subscriptionDays));
      final next = PremiumStatus(premiumStatus: true, expiresAt: expiresAt);
      final ok = await _persist(next);
      if (ok) state = next;
      return ok;
    } catch (e, st) {
      if (kDebugMode) debugPrint('purchasePremium: $e\n$st');
      return false;
    }
  }

  /// استعادة المشتريات من التخزين المحلي.
  Future<bool> restorePurchases() async {
    try {
      final prefs = AppInitializer.prefs;
      final active = prefs.getBool(AppConstants.prefPremiumActive) ?? false;
      if (!active) return false;

      final expiryRaw = prefs.getString(AppConstants.prefPremiumExpiresAt);
      final expiresAt =
          expiryRaw != null ? DateTime.tryParse(expiryRaw) : null;

      final restored = PremiumStatus(
        premiumStatus: true,
        expiresAt: expiresAt,
      );

      if (!restored.isValid) return false;

      state = restored;
      return true;
    } catch (e, st) {
      if (kDebugMode) debugPrint('restorePurchases: $e\n$st');
      return false;
    }
  }

  Future<bool> _persist(PremiumStatus status) async {
    final prefs = AppInitializer.prefs;
    final okActive =
        await prefs.setBool(AppConstants.prefPremiumActive, status.premiumStatus);
    if (!okActive) return false;

    if (status.expiresAt != null) {
      final okExpiry = await prefs.setString(
        AppConstants.prefPremiumExpiresAt,
        status.expiresAt!.toIso8601String(),
      );
      if (!okExpiry) return false;
    } else {
      await prefs.remove(AppConstants.prefPremiumExpiresAt);
    }

    return prefs.getBool(AppConstants.prefPremiumActive) == status.premiumStatus;
  }
}

final premiumNotifierProvider =
    StateNotifierProvider<PremiumNotifier, PremiumStatus>((ref) {
  return PremiumNotifier();
});

/// حالة Premium الكاملة.
final premiumStatusProvider = Provider<PremiumStatus>((ref) {
  return ref.watch(premiumNotifierProvider);
});

/// اختصار — هل Premium مفعّل؟
final isPremiumProvider = Provider<bool>((ref) {
  return ref.watch(premiumStatusProvider).isValid;
});

/// للتوافق مع الكود السابق.
@Deprecated('Use premiumNotifierProvider')
final premiumProvider = premiumNotifierProvider;
