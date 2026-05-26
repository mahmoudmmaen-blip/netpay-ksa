import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netgulf/core/constants/app_constants.dart';
import 'package:netgulf/core/theme/app_theme.dart';

/// Builds a test widget tree that mirrors the production `NetGulfApp` setup.
///
/// This is intentionally aligned with `lib/app.dart`:
/// - `ProviderScope` root
/// - `MaterialApp.router` + `builder` RTL shell
/// - Same localization delegates + supported locales + default locale
/// - Same theme/darkTheme wiring (themeMode is configurable for tests)
Widget createLocalizedTestWidget({
  required RouterConfig<Object> routerConfig,
  ThemeMode themeMode = ThemeMode.light,
  bool? defaultRtl,
}) {
  return ProviderScope(
    child: MaterialApp.router(
      title: AppConstants.appNameEn,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      themeAnimationDuration: const Duration(milliseconds: 350),
      themeAnimationCurve: Curves.easeInOut,
      locale: const Locale(
        AppConstants.defaultLocaleCode,
        AppConstants.defaultCountryCode,
      ),
      supportedLocales: const [
        Locale('ar', 'SA'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: routerConfig,
      builder: (context, child) => Directionality(
        textDirection: (defaultRtl ?? AppConstants.defaultRtl)
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: child ?? const SizedBox.shrink(),
      ),
    ),
  );
}

/// Same as [createLocalizedTestWidget] but for tests that don't need routing.
Widget createLocalizedTestApp({
  required Widget home,
  ThemeMode themeMode = ThemeMode.light,
  bool? defaultRtl,
}) {
  return ProviderScope(
    child: MaterialApp(
      title: AppConstants.appNameEn,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      themeAnimationDuration: const Duration(milliseconds: 350),
      themeAnimationCurve: Curves.easeInOut,
      locale: const Locale(
        AppConstants.defaultLocaleCode,
        AppConstants.defaultCountryCode,
      ),
      supportedLocales: const [
        Locale('ar', 'SA'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(
        textDirection: (defaultRtl ?? AppConstants.defaultRtl)
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: child ?? const SizedBox.shrink(),
      ),
      home: home,
    ),
  );
}

