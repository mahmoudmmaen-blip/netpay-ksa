import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netgulf/core/bootstrap/app_initializer.dart';
import 'package:netgulf/core/constants/app_constants.dart';

/// حالة التطبيق العامة — ثيم، جاهزية، إعدادات محفوظة.
class AppState extends Equatable {
  const AppState({
    required this.themeMode,
    required this.isReady,
    this.onboardingCompleted = false,
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
            themeMode: ThemeMode.system,
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
          : ThemeMode.system;

      final onboardingDone =
          prefs.getBool(AppConstants.prefOnboardingDone) ?? false;

      state = AppState(
        themeMode: themeMode,
        isReady: true,
        onboardingCompleted: onboardingDone,
      );
    } catch (_) {
      state = const AppState(
        themeMode: ThemeMode.system,
        isReady: true,
        onboardingCompleted: false,
      );
    }
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

  Future<void> setOnboardingCompleted(bool value) async {
    state = state.copyWith(onboardingCompleted: value);
    await AppInitializer.prefs.setBool(AppConstants.prefOnboardingDone, value);
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
