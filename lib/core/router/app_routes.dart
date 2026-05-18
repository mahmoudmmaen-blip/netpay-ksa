// مسارات GoRouter — NetPay KSA

/// مسارات التطبيق (paths + أسماء للتنقل المسمّى).
abstract final class AppRoutes {
  AppRoutes._();

  // ── مسارات أساسية ────────────────────────────────────────────────────────

  static const String splash = '/';
  static const String home = '/home';
  static const String history = '/history';

  // ── مسارات مستقبلية ────────────────────────────────────────────────────────

  static const String salaryCalculator = '/salary';
  static const String gosi = '/gosi';
  static const String eosb = '/eosb';
  static const String settings = '/settings';

  // ── أسماء GoRouter (للتنقل: context.goNamed) ───────────────────────────────

  static const String splashName = 'splash';
  static const String homeName = 'home';
  static const String historyName = 'history';
  static const String settingsName = 'settings';

  /// المسار الابتدائي عند فتح التطبيق.
  static const String initial = splash;

  /// مسار ما بعد Splash.
  static const String postSplash = home;

  /// هل المسار يعرض شريط تنقل سفلي (لاحقاً).
  static bool showsBottomNav(String path) {
    return path == home || path == history || path == settings;
  }
}
