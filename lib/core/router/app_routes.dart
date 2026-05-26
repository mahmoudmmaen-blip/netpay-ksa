// مسارات GoRouter — NetGulf

/// مسارات التطبيق (paths + أسماء للتنقل المسمّى).
abstract final class AppRoutes {
  AppRoutes._();

  // ── مسارات أساسية ────────────────────────────────────────────────────────

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String history = '/history';

  // ── مسارات مستقبلية ────────────────────────────────────────────────────────

  static const String salaryCalculator = '/salary';
  static const String gosi = '/gosi';
  static const String eosb = '/eosb';
  static const String comparison = '/comparison';
  static const String increase = '/increase';
  static const String notifications = '/notifications';
  static const String uae = '/uae';
  static const String legal = '/legal';
  static const String privacyPolicy = '/privacy-policy';
  static const String settings = '/settings';

  // ── أسماء GoRouter (للتنقل: context.goNamed) ───────────────────────────────

  static const String splashName = 'splash';
  static const String onboardingName = 'onboarding';
  static const String homeName = 'home';
  static const String historyName = 'history';
  static const String eosbName = 'eosb';
  static const String comparisonName = 'comparison';
  static const String increaseName = 'increase';
  static const String notificationsName = 'notifications';
  static const String uaeName = 'uae';
  static const String legalName = 'legal';
  static const String privacyPolicyName = 'privacyPolicy';
  static const String settingsName = 'settings';

  /// المسار الابتدائي عند فتح التطبيق.
  static const String initial = splash;

  /// مسار ما بعد Splash حسب إكمال التعريف.
  static String postSplash({required bool onboardingCompleted}) =>
      onboardingCompleted ? home : onboarding;

  /// هل المسار يعرض شريط تنقل سفلي (لاحقاً).
  static bool showsBottomNav(String path) {
    return path == home || path == history || path == settings;
  }
}
