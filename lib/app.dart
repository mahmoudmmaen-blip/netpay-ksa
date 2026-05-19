import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netgulf/core/constants/app_constants.dart';
import 'package:netgulf/core/providers/app_state_provider.dart';
import 'package:netgulf/core/router/app_router.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/core/theme/app_theme.dart';
import 'package:netgulf/core/widgets/app_logo.dart';

/// جذر التطبيق — Material 3، RTL، GoRouter، ثيم محفوظ.
class NetGulfApp extends ConsumerWidget {
  const NetGulfApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(appRouterProvider);

    if (!appState.isReady) {
      return _BootstrapApp(themeMode: themeMode);
    }

    return MaterialApp.router(
      title: AppConstants.appNameEn,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
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
      routerConfig: router,
      builder: (context, child) => _RtlShell(child: child),
    );
  }
}

/// تحميل prefs قبل إظهار GoRouter.
class _BootstrapApp extends StatelessWidget {
  const _BootstrapApp({required this.themeMode});

  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const _BootstrapLoadingScreen(),
    );
  }
}

class _RtlShell extends StatelessWidget {
  const _RtlShell({required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: AppConstants.defaultRtl
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: child ?? const SizedBox.shrink(),
    );
  }
}

class _BootstrapLoadingScreen extends StatelessWidget {
  const _BootstrapLoadingScreen();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppColors.splashGradient(brightness),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AppLogo(size: 80),
                  const SizedBox(height: 24),
                  Text(
                    AppConstants.appNameAr,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppConstants.appTaglineAr,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.lightMuted,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.emerald,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
