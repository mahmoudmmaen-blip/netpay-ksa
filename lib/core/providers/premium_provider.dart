import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netgulf/core/bootstrap/app_initializer.dart';
import 'package:netgulf/core/constants/app_constants.dart';

/// حالة Premium — SharedPreferences الآن، RevenueCat لاحقاً.
class PremiumNotifier extends StateNotifier<bool> {
  PremiumNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    try {
      final active =
          AppInitializer.prefs.getBool(AppConstants.prefPremiumActive) ?? false;
      state = active;
    } catch (_) {
      state = false;
    }
  }

  /// تفعيل Premium (محاكاة شراء — استبدل بـ in_app_purchase لاحقاً).
  Future<bool> activatePremium() async {
    try {
      final ok = await AppInitializer.prefs
          .setBool(AppConstants.prefPremiumActive, true);
      if (!ok) return false;
      final verified =
          AppInitializer.prefs.getBool(AppConstants.prefPremiumActive) ?? false;
      if (!verified) return false;
      state = true;
      return true;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('activatePremium failed: $e\n$st');
      }
      return false;
    }
  }

  /// للاختبار — إلغاء Premium.
  Future<void> deactivatePremium() async {
    await AppInitializer.prefs.setBool(AppConstants.prefPremiumActive, false);
    state = false;
  }
}

final premiumProvider =
    StateNotifierProvider<PremiumNotifier, bool>((ref) => PremiumNotifier());

final isPremiumProvider = Provider<bool>((ref) => ref.watch(premiumProvider));
