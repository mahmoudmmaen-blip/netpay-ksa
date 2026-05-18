import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:netpay_ksa/core/constants/app_constants.dart';

final appStateProvider = NotifierProvider<AppStateNotifier, AppState>(() {
  return AppStateNotifier();
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(appStateProvider).themeMode;
});

class AppState {
  final ThemeMode themeMode;
  final bool isReady;
  final bool onboardingCompleted;

  const AppState({
    this.themeMode = ThemeMode.system,
    this.isReady = false,
    this.onboardingCompleted = false,
  });

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
}

class AppStateNotifier extends Notifier<AppState> {
  late SharedPreferences _prefs;

  @override
  AppState build() {
    _loadPreferences();
    return const AppState(isReady: false);
  }

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();

    final savedTheme = _prefs.getString(AppConstants.prefThemeMode);
    final onboardingDone = _prefs.getBool(AppConstants.prefOnboardingDone) ?? false;

    ThemeMode theme = ThemeMode.system;
    if (savedTheme == 'light') theme = ThemeMode.light;
    if (savedTheme == 'dark') theme = ThemeMode.dark;

    state = AppState(
      themeMode: theme,
      isReady: true,
      onboardingCompleted: onboardingDone,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(AppConstants.prefThemeMode, mode.name);
    state = state.copyWith(themeMode: mode);
  }

  void toggleDarkLight() {
    final newMode = state.themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    setThemeMode(newMode);
  }

  Future<void> completeOnboarding() async {
    await _prefs.setBool(AppConstants.prefOnboardingDone, true);
    state = state.copyWith(onboardingCompleted: true);
  }
}