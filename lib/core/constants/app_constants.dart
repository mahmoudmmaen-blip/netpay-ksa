// ثوابت التطبيق — NetGulf 2026
// الهوية، المسارات، الألوان (hex)، GOSI، والانتقالات.

// ─────────────────────────────────────────────────────────────────────────────
// الهوية والأصول
// ─────────────────────────────────────────────────────────────────────────────

/// معلومات التطبيق والمسارات الثابتة.
abstract final class AppConstants {
  AppConstants._();

  static const String appNameAr = 'نت غلف';
  static const String appNameEn = 'NetGulf';
  static const String appTaglineAr =
      'حاسبة الراتب الصافي — السعودية والإمارات';
  static const String appTaglineEn =
      'Gulf Net Salary Calculator — KSA & UAE';

  static const String appVersion = '1.0.0';
  static const int appBuildNumber = 1;

  /// شعار التطبيق — PNG شفاف 512×512.
  static const String logoAsset = 'assets/images/logo.png';
  static const String logoPlaceholderAsset =
      'assets/images/logo_placeholder.png';

  /// اللغة والاتجاه الافتراضي.
  static const String defaultLocaleCode = 'ar';
  static const String defaultCountryCode = 'SA';
  static const bool defaultRtl = true;

  // ── Hive (Offline First) ───────────────────────────────────────────────────

  static const String hiveBoxSettings = 'netgulf_settings';
  static const String hiveBoxHistory = 'netgulf_salary_history';
  static const String hiveBoxPremium = 'netgulf_premium';

  /// مفاتيح Hive — Premium.
  static const String hivePremiumActive = 'premium_active';
  static const String hivePremiumExpiresAt = 'premium_expires_at';

  // ── SharedPreferences keys ─────────────────────────────────────────────────

  static const String prefThemeMode = 'theme_mode';
  static const String prefOnboardingDone = 'onboarding_done';
  static const String prefNotificationsEnabled = 'notifications_enabled';
  static const String prefLegalAiQuestionsDate = 'legal_ai_questions_date';
  static const String prefLegalAiQuestionsCount = 'legal_ai_questions_count';
  static const String prefGulfCountry = 'gulf_country';

  // ── Premium (SharedPreferences — استبدل بـ IAP/RevenueCat لاحقاً) ─────────

  /// مفتاح: هل اشترك المستخدم سابقاً (true حتى بعد انتهاء الصلاحية).
  static const String prefPremiumActive = 'premium_active';

  /// مفتاح: تاريخ انتهاء الاشتراك ISO8601.
  static const String prefPremiumExpiresAt = 'premium_expires_at';

  /// سعر Premium السنوي بالريال.
  static const int premiumPriceSar = 29;
  static const String premiumPriceLabel = '$premiumPriceSar ريال';

  /// حد سجل الرواتب للنسخة المجانية — Premium = غير محدود.
  static const int freeHistoryLimit = 5;

  /// @deprecated Use [freeHistoryLimit]
  static const int freeHistoryRecordLimit = freeHistoryLimit;

  /// حد الأسئلة اليومية للمساعد القانوني (النسخة المجانية).
  static const int legalAiDailyQuestionLimit = 5;

  // ── Splash & انتقالات الشاشات ────────────────────────────────────────────

  /// مدة عرض شاشة البداية قبل الانتقال للرئيسية.
  static const Duration splashDisplayDuration = Duration(milliseconds: 2400);

  /// مدة أنيميشن الشعار على Splash.
  static const Duration splashLogoAnimationDuration =
      Duration(milliseconds: 1200);

  /// مدة انتقال Splash → Home (fade + slide).
  static const Duration routeTransitionDuration = Duration(milliseconds: 450);

  static const Duration routeReverseTransitionDuration =
      Duration(milliseconds: 350);
}

// ─────────────────────────────────────────────────────────────────────────────
// لوحة الألوان (hex → [AppColors])
// ─────────────────────────────────────────────────────────────────────────────

/// زمردي + كحلي + ذهبي.
abstract final class AppPalette {
  AppPalette._();

  static const int emerald = 0xFF10B981;
  static const int emeraldDark = 0xFF059669;
  static const int emeraldLight = 0xFF34D399;
  static const int emeraldMuted = 0xFFD1FAE5;

  static const int navy = 0xFF0B1120;
  static const int navyMid = 0xFF131C31;
  static const int navyLight = 0xFF1E293B;
  static const int navyDeepGreen = 0xFF064E3B;

  static const int gold = 0xFFD4AF37;
  static const int goldBright = 0xFFFFC857;

  static const int lightBackground = 0xFFF0FDF9;
  static const int lightSurface = 0xFFFFFFFF;
  static const int lightOnSurface = 0xFF0F172A;
  static const int lightMuted = 0xFF64748B;

  static const int success = 0xFF22C55E;
  static const int error = 0xFFEF4444;
  static const int warning = 0xFFF59E0B;
  static const int info = 0xFF3B82F6;
}

// ─────────────────────────────────────────────────────────────────────────────
// GOSI — مرجع 2026
// ─────────────────────────────────────────────────────────────────────────────

abstract final class GosiConstants {
  GosiConstants._();

  static const double wageCeilingSar = 45000;

  static const int newLawYear = 2024;
  static const int newLawMonth = 7;
  static const int newLawDay = 3;

  static const int phasedIncreaseStartYear = 2025;
  static const int phasedIncreaseEndYear = 2028;

  static const double employerOccupationalHazardPercent = 2.0;

  /// تقاعد النظام القديم (%).
  static const double legacyPensionPercent = 9.0;

  /// ساند النظام القديم — 0.75% (إجمالي موظف 9.75%).
  static const double legacySanedPercent = 0.75;

  /// موظف سعودي — نظام قديم: 9.75%.
  static const double legacyEmployeeTotalPercent = 9.75;

  /// صاحب عمل — نظام قديم: 11.75%.
  static const double legacyEmployerTotalPercent = 11.75;

  /// ساند النظام الجديد — 0.25% (مع التقاعد = إجمالي الموظف).
  static const double newLawSanedPercent = 0.25;

  /// زيادة تقاعد سنوية كل 1 يوليو.
  static const double phasedPensionStepPercent = 0.5;

  /// تقاعد الموظف حسب مرحلة يوليو (+0.5% سنوياً).
  /// موظف: 2025→9.75% | 2026→10.25% | 2027→10.75% | 2028→11.25%
  /// (تقاعد + ساند 0.25%)
  static const Map<int, double> newLawPensionPercentByPhaseYear = {
    2025: 9.5,
    2026: 10.0,
    2027: 10.5,
    2028: 11.0,
  };

  static const double year2026PensionPercent = 10.0;
  static const double year2026EmployeeTotalPercent =
      year2026PensionPercent + newLawSanedPercent;
  static const double year2026EmployerTotalPercent =
      year2026PensionPercent +
      employerOccupationalHazardPercent +
      newLawSanedPercent;

  static const double nonSaudiEmployeePercent = 0.0;
  static const double nonSaudiEmployerPercent =
      employerOccupationalHazardPercent;
}

/// مرحلة زيادة GOSI للجداول والتنبيهات.
class GosiPhaseRate {
  const GosiPhaseRate({
    required this.phaseYear,
    required this.pensionPercent,
    required this.employeeTotalPercent,
    required this.employerTotalPercent,
  });

  final int phaseYear;
  final double pensionPercent;
  final double employeeTotalPercent;
  final double employerTotalPercent;

  static List<GosiPhaseRate> schedule2025to2028() {
    return GosiConstants.newLawPensionPercentByPhaseYear.entries.map((e) {
      final pension = e.value;
      final emp = pension + GosiConstants.newLawSanedPercent;
      final er = pension +
          GosiConstants.employerOccupationalHazardPercent +
          GosiConstants.newLawSanedPercent;
      return GosiPhaseRate(
        phaseYear: e.key,
        pensionPercent: pension,
        employeeTotalPercent: emp,
        employerTotalPercent: er,
      );
    }).toList();
  }
}
