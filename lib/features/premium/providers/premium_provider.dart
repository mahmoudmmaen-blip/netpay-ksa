import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:netgulf/core/bootstrap/app_initializer.dart';
import 'package:netgulf/core/constants/app_constants.dart';
import 'package:netgulf/core/models/premium_status.dart';

/// إدارة Premium — Hive (أساسي) + SharedPreferences (نسخ احتياطي).
class PremiumNotifier extends StateNotifier<PremiumStatus> {
  PremiumNotifier() : super(const PremiumStatus()) {
    _load();
  }

  static const _subscriptionDays = 365;

  Box<dynamic>? get _box {
    if (!AppInitializer.isHiveReady) return null;
    if (!Hive.isBoxOpen(AppConstants.hiveBoxPremium)) return null;
    return Hive.box<dynamic>(AppConstants.hiveBoxPremium);
  }

  Future<void> _load() async {
    try {
      await _ensurePremiumBox();
      final fromHive = _readFromHive();
      if (fromHive != null) {
        state = fromHive;
        await _persistPrefs(fromHive);
        return;
      }

      final fromPrefs = _readFromPrefs();
      state = fromPrefs;
      await _persistHive(fromPrefs);
    } catch (e, st) {
      if (kDebugMode) debugPrint('PremiumNotifier._load: $e\n$st');
      state = const PremiumStatus();
    }
  }

  Future<void> _ensurePremiumBox() async {
    if (!AppInitializer.isHiveReady) return;
    if (!Hive.isBoxOpen(AppConstants.hiveBoxPremium)) {
      await Hive.openBox<dynamic>(AppConstants.hiveBoxPremium);
    }
  }

  PremiumStatus? _readFromHive() {
    final box = _box;
    if (box == null || box.isEmpty) return null;
    final active = box.get(AppConstants.hivePremiumActive) as bool? ?? false;
    final expiryRaw = box.get(AppConstants.hivePremiumExpiresAt) as String?;
    return PremiumStatus(
      premiumStatus: active,
      expiresAt: expiryRaw != null ? DateTime.tryParse(expiryRaw) : null,
    );
  }

  PremiumStatus _readFromPrefs() {
    final prefs = AppInitializer.prefs;
    final active = prefs.getBool(AppConstants.prefPremiumActive) ?? false;
    final expiryRaw = prefs.getString(AppConstants.prefPremiumExpiresAt);
    return PremiumStatus(
      premiumStatus: active,
      expiresAt: expiryRaw != null ? DateTime.tryParse(expiryRaw) : null,
    );
  }

  /// هل Premium ساري الآن؟
  bool isPremium() => state.isValid;

  /// يعيد تحميل الحالة من Hive/Prefs ويُرجع هل الاشتراك ساري.
  Future<bool> loadPremiumStatus() async {
    await _load();
    return isPremium();
  }

  /// @deprecated استخدم [loadPremiumStatus].
  Future<bool> checkPremiumStatus() => loadPremiumStatus();

  /// ترقية إلى Premium (محاكاة IAP).
  Future<bool> upgradeToPremium() async {
    try {
      final expiresAt =
          DateTime.now().add(const Duration(days: _subscriptionDays));
      final next = PremiumStatus(premiumStatus: true, expiresAt: expiresAt);
      final ok = await _persistAll(next);
      if (ok) state = next;
      return ok;
    } catch (e, st) {
      if (kDebugMode) debugPrint('upgradeToPremium: $e\n$st');
      return false;
    }
  }

  /// @deprecated استخدم [upgradeToPremium].
  Future<bool> purchasePremium() => upgradeToPremium();

  Future<bool> restorePurchases() async {
    try {
      await _load();
      if (!state.premiumStatus) return false;
      if (!state.isValid) return false;
      return true;
    } catch (e, st) {
      if (kDebugMode) debugPrint('restorePurchases: $e\n$st');
      return false;
    }
  }

  Future<bool> _persistAll(PremiumStatus status) async {
    final hiveOk = await _persistHive(status);
    final prefsOk = await _persistPrefs(status);
    return hiveOk && prefsOk;
  }

  Future<bool> _persistHive(PremiumStatus status) async {
    try {
      await _ensurePremiumBox();
      final box = _box;
      if (box == null) return false;
      await box.put(AppConstants.hivePremiumActive, status.premiumStatus);
      if (status.expiresAt != null) {
        await box.put(
          AppConstants.hivePremiumExpiresAt,
          status.expiresAt!.toIso8601String(),
        );
      } else {
        await box.delete(AppConstants.hivePremiumExpiresAt);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _persistPrefs(PremiumStatus status) async {
    final prefs = AppInitializer.prefs;
    final okActive =
        await prefs.setBool(AppConstants.prefPremiumActive, status.premiumStatus);
    if (!okActive) return false;
    if (status.expiresAt != null) {
      return prefs.setString(
        AppConstants.prefPremiumExpiresAt,
        status.expiresAt!.toIso8601String(),
      );
    }
    await prefs.remove(AppConstants.prefPremiumExpiresAt);
    return true;
  }
}

final premiumNotifierProvider =
    StateNotifierProvider<PremiumNotifier, PremiumStatus>((ref) {
  return PremiumNotifier();
});

final premiumStatusProvider = Provider<PremiumStatus>((ref) {
  return ref.watch(premiumNotifierProvider);
});

final isPremiumProvider = Provider<bool>((ref) {
  return ref.watch(premiumStatusProvider).isValid;
});

@Deprecated('Use premiumNotifierProvider')
final premiumProvider = premiumNotifierProvider;
