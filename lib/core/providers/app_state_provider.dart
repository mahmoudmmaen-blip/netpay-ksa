import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:netgulf/core/bootstrap/app_initializer.dart';
import 'package:netgulf/core/constants/app_constants.dart';

/// حالة التطبيق العامة — جاهزية، إعدادات محفوظة.
class AppState extends Equatable {
  const AppState({
    required this.isReady,
    this.onboardingCompleted = true,
  });

  final bool isReady;

  /// هل أنهى المستخدم الإعداد الأولي (للاستخدام لاحقاً).
  final bool onboardingCompleted;

  AppState copyWith({
    bool? isReady,
    bool? onboardingCompleted,
  }) {
    return AppState(
      isReady: isReady ?? this.isReady,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  @override
  List<Object?> get props => [isReady, onboardingCompleted];
}

/// يحمّل ويحفظ الثيم + الإعدادات من SharedPreferences.
class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier()
      : super(
          const AppState(
            isReady: false,
          ),
        ) {
    _loadPersistedState();
  }

  Future<void> _loadPersistedState() async {
    try {
      final prefs = AppInitializer.prefs;

      final onboardingDone = await _resolveOnboardingCompleted(prefs);

      state = AppState(
        isReady: true,
        onboardingCompleted: onboardingDone,
      );
    } catch (_) {
      state = const AppState(
        isReady: true,
        onboardingCompleted: true,
      );
    }
  }

  /// يقرأ [prefOnboardingDone] — المستخدمون القدامى يُكمّلون الإعداد تلقائياً.
  Future<bool> _resolveOnboardingCompleted(SharedPreferences prefs) async {
    final legacyUser = _hasLegacyAppData(prefs);

    if (prefs.containsKey(AppConstants.prefOnboardingDone)) {
      final stored = prefs.getBool(AppConstants.prefOnboardingDone)!;
      // إصلاح تحديثات قديمة: false محفوظ بالخطأ لمستخدم استخدم التطبيق سابقاً.
      if (!stored && legacyUser) {
        await _persistOnboardingDone(prefs, completed: true);
        return true;
      }
      return stored;
    }

    if (legacyUser) {
      await _persistOnboardingDone(prefs, completed: true);
      return true;
    }

    return false;
  }

  bool _hasLegacyAppData(SharedPreferences prefs) {
    // أي مفتاح محفوظ غير onboarding_done = مستخدم قديم (بعد التحديث).
    final hasAnyOtherPref = prefs
        .getKeys()
        .any((key) => key != AppConstants.prefOnboardingDone);
    if (hasAnyOtherPref) return true;

    final hasKnownPrefs = prefs.containsKey(AppConstants.prefThemeMode) ||
        prefs.containsKey(AppConstants.prefGulfCountry) ||
        prefs.containsKey(AppConstants.prefNotificationsEnabled) ||
        prefs.containsKey(AppConstants.prefLegalAiQuestionsDate);

    if (hasKnownPrefs) return true;

    try {
      final history = AppInitializer.historyBox;
      if (history != null && history.isNotEmpty) return true;
      final settings = AppInitializer.settingsBox;
      if (settings != null && settings.isNotEmpty) return true;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('onboarding legacy hive check: $e\n$st');
      }
    }
    return false;
  }

  Future<bool> _persistOnboardingDone(
    SharedPreferences prefs, {
    required bool completed,
  }) async {
    final ok = await prefs.setBool(AppConstants.prefOnboardingDone, completed);
    if (!ok) return false;
    return prefs.getBool(AppConstants.prefOnboardingDone) == completed;
  }

  /// يحفظ [prefOnboardingDone] ثم يحدّث الحالة — مرة واحدة للمستخدم الجديد.
  Future<void> setOnboardingCompleted(bool value) async {
    final prefs = AppInitializer.prefs;
    final persisted = await _persistOnboardingDone(prefs, completed: value);
    if (!persisted) {
      if (kDebugMode) {
        debugPrint('onboarding_done: failed to persist $value');
      }
      return;
    }
    state = state.copyWith(onboardingCompleted: value);
  }
}

/// مزوّد الحالة الرئيسي.
final appStateProvider =
    StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});

/// اختصار لجاهزية التطبيق (بعد تحميل prefs).
final appReadyProvider = Provider<bool>((ref) {
  return ref.watch(appStateProvider).isReady;
});
