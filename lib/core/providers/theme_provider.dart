import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netgulf/core/bootstrap/app_initializer.dart';
import 'package:netgulf/core/constants/app_constants.dart';

/// إدارة وضع الثيم — system / light / dark مع حفظ محلي.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = AppInitializer.prefs;
      final index = prefs.getInt(AppConstants.prefThemeMode);
      if (index != null &&
          index >= 0 &&
          index < ThemeMode.values.length) {
        state = ThemeMode.values[index];
      }
    } catch (_) {
      state = ThemeMode.system;
    }
  }

  /// تعيين وضع الثيم وحفظه.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (state == mode) return;
    state = mode;
    await AppInitializer.prefs.setInt(
      AppConstants.prefThemeMode,
      mode.index,
    );
  }

  /// تبديل سريع فاتح ↔ داكن (من AppBar).
  Future<void> toggleDarkLight() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(next);
  }

  /// العودة لثيم النظام.
  Future<void> useSystemTheme() => setThemeMode(ThemeMode.system);
}

/// مزوّد وضع الثيم — الافتراضي [ThemeMode.system].
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

/// تسمية عربية لوضع الثيم الحالي.
String themeModeLabel(ThemeMode mode) => switch (mode) {
      ThemeMode.system => 'يتبع إعدادات الجهاز',
      ThemeMode.light => 'الوضع الفاتح',
      ThemeMode.dark => 'الوضع الداكن',
    };
