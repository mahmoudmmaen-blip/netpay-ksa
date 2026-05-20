import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:netgulf/core/bootstrap/app_initializer.dart';
import 'package:netgulf/core/constants/app_constants.dart';

/// حالة التطبيق العامة — ثيم، جاهزية، إعدادات محفوظة.
class AppState extends Equatable {
  const AppState({
    required this.themeMode,
    required this.isReady,
    this.onboardingCompleted = true,
  });

  final ThemeMode themeMode;
  final bool isReady;

  /// هل أنهى المستخدم الإعداد الأولي (للاستخدام لاحقاً).
  final bool onboardingCompleted;

  bool get isDarkMode => themeMode == ThemeMode.dark;
  bool get isLightMode => themeMode == ThemeMode.light;
  bool get followsSystem => themeMode == ThemeMode.system;

  AppState copyWith({
    ThemeMode? themeMode,
    bool? isReady,
    bool? onboardingCompleted,
  }) {
    return AppState(
      themeMode: themeMode ?? this.themeMode,
      isReady: isReady ?? this.isReady,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  @override
  List<Object?> get props => [themeMode, isReady, onboardingCompleted];
}

/// يحمّل ويحفظ الثيم + الإعدادات من SharedPreferences.
class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier()
      : super(
          const AppState(
            themeMode: ThemeMode.dark,
            isReady: false,
          ),
        ) {
    _loadPersistedState();
  }

  Future<void> _loadPersistedState() async {
    try {
      final prefs = AppInitializer.prefs;

      final themeIndex = prefs.getInt(AppConstants.prefThemeMode);
      final themeMode = themeIndex != null &&
              themeIndex >= 0 &&
              themeIndex < ThemeMode.values.length
          ? ThemeMode.values[themeIndex]
          : ThemeMode.dark;

      final onboardingDone = await _resolveOnboardingCompleted(prefs);

      state = AppState(
        themeMode: themeMode,
        isReady: true,
        onboardingCompleted: onboardingDone,
      );
    } catch (_) {
      state = const AppState(
        themeMode: ThemeMode.dark,
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

  /// تعيين وضع الثيم وحفظه محلياً.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (state.themeMode == mode) return;
    state = state.copyWith(themeMode: mode);
    await AppInitializer.prefs.setInt(AppConstants.prefThemeMode, mode.index);
  }

  /// تبديل سريع بين فاتح / داكن (من AppBar).
  Future<void> toggleDarkLight() async {
    final brightness =
        state.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(brightness);
  }

  /// العودة لثيم النظام.
  Future<void> useSystemTheme() => setThemeMode(ThemeMode.system);

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

/// اختصار لـ [AppState.themeMode] فقط.
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(appStateProvider).themeMode;
});

/// اختصار لجاهزية التطبيق (بعد تحميل prefs).
final appReadyProvider = Provider<bool>((ref) {
  return ref.watch(appStateProvider).isReady;
});
