import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/router/app_page_transitions.dart';
import 'package:netgulf/core/router/app_routes.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/features/salary_calculator/presentation/history_screen.dart';
import 'package:netgulf/features/home/presentation/home_screen.dart';
import 'package:netgulf/features/onboarding/presentation/onboarding_screen.dart';
import 'package:netgulf/features/settings/presentation/settings_screen.dart';
import 'package:netgulf/features/comparison/presentation/comparison_screen.dart';
import 'package:netgulf/features/eosb/presentation/eosb_screen.dart';
import 'package:netgulf/features/leave_balance/presentation/leave_balance_screen.dart';
import 'package:netgulf/features/notice_period/presentation/notice_period_screen.dart';
import 'package:netgulf/features/history/presentation/history_screen.dart';
import 'package:netgulf/features/salary_calculator/presentation/increase_calculator_screen.dart';
import 'package:netgulf/features/notifications/presentation/notifications_screen.dart';
import 'package:netgulf/features/uae/presentation/uae_calculator_screen.dart';
import 'package:netgulf/features/legal/presentation/privacy_policy_screen.dart';
import 'package:netgulf/features/splash/presentation/splash_screen.dart';
import 'package:netgulf/core/providers/app_state_provider.dart';

/// مفتاح التنقل الجذر — للـ dialogs و deep links.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// GoRouter مركزي — Splash أولاً ثم Home وباقي المسارات.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.initial,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final appState = ref.read(appStateProvider);
      if (!appState.isReady) return null;

      final location = state.matchedLocation;
      if (!appState.onboardingCompleted &&
          location != AppRoutes.onboarding &&
          location != AppRoutes.splash) {
        return AppRoutes.onboarding;
      }
      return null;
    },
    routes: [
      // ── Splash (أول شاشة) ───────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        name: AppRoutes.splashName,
        pageBuilder: (context, state) => AppPageTransitions.splash(
          key: state.pageKey,
          child: const SplashScreen(),
        ),
      ),

      // ── التعريف (أول تشغيل) ─────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.onboarding,
        name: AppRoutes.onboardingName,
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const OnboardingScreen(),
        ),
      ),

      // ── الحاسبة الرئيسية ─────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.home,
        name: AppRoutes.homeName,
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const HomeScreen(),
        ),
      ),

      // ── سجل الحسابات ─────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.history,
        name: AppRoutes.historyName,
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const SalaryHistoryScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.eosbHistory,
        name: AppRoutes.eosbHistoryName,
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const EosbHistoryScreen(),
        ),
      ),

      // ── الإعدادات ───────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.settings,
        name: AppRoutes.settingsName,
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const SettingsScreen(),
        ),
      ),

      // ── مسارات مستقبلية (placeholders) ─────────────────────────────────
      GoRoute(
        path: AppRoutes.salaryCalculator,
        name: 'salary',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const _ComingSoonScreen(
            title: 'حاسبة الراتب المتقدمة',
            icon: Icons.calculate_outlined,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.gosi,
        name: 'gosi',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const _ComingSoonScreen(
            title: 'تفاصيل التأمينات (GOSI)',
            icon: Icons.shield_outlined,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.eosb,
        name: AppRoutes.eosbName,
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: EosbScreen(
            historyEntryId: state.uri.queryParameters['historyId'],
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.noticePeriod,
        name: AppRoutes.noticePeriodName,
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const NoticePeriodScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.leaveBalance,
        name: AppRoutes.leaveBalanceName,
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const LeaveBalanceScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.comparison,
        name: AppRoutes.comparisonName,
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const ComparisonScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.increase,
        name: AppRoutes.increaseName,
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const IncreaseCalculatorScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: AppRoutes.notificationsName,
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const NotificationsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.uae,
        name: AppRoutes.uaeName,
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const UaeCalculatorScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        name: AppRoutes.privacyPolicyName,
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const PrivacyPolicyScreen(),
        ),
      ),
      // المساعد القانوني / legal — يوجّه لحاسبة نهاية الخدمة (EOSB).
      GoRoute(
        path: AppRoutes.legal,
        name: AppRoutes.legalName,
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const EosbScreen(),
        ),
      ),
    ],
    errorBuilder: (context, state) => _ComingSoonScreen(
      title: 'الصفحة غير موجودة',
      subtitle: state.uri.toString(),
      icon: Icons.error_outline_rounded,
    ),
  );
});

/// شاشة مؤقتة للمسارات قيد التطوير.
class _ComingSoonScreen extends StatelessWidget {
  const _ComingSoonScreen({
    required this.title,
    required this.icon,
    this.subtitle,
  });

  final String title;
  final IconData icon;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: AppColors.emerald.withValues(alpha: 0.6)),
              const SizedBox(height: 20),
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: GoogleFonts.cairo(color: AppColors.lightMuted),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'قريباً في تحديث قادم',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
