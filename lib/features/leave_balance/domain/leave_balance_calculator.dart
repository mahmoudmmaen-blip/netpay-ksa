import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/features/leave_balance/domain/leave_balance_model.dart';

/// قواعد الإجازة السنوية — ٦ دول خليجية.
abstract final class LeaveBalanceCalculator {
  LeaveBalanceCalculator._();

  static int annualDays(LeaveBalanceModel m) {
    final fullYear = switch (m.country) {
      GulfCountry.saudiArabia => m.totalServiceYears >= 5 ? 30 : 21,
      GulfCountry.uae => 30,
      GulfCountry.oman => 30,
      GulfCountry.qatar => m.totalServiceYears >= 1 ? 30 : 21,
      GulfCountry.bahrain => 30,
      GulfCountry.kuwait => 30,
    };

    if (m.totalServiceYears < 1 &&
        (m.country == GulfCountry.uae ||
            m.country == GulfCountry.oman ||
            m.country == GulfCountry.bahrain)) {
      final monthsWorked = m.serviceYears * 12 + m.serviceMonths;
      return ((fullYear / 12) * monthsWorked).round().clamp(0, fullYear);
    }

    return fullYear;
  }

  static double dailyWage(LeaveBalanceModel m) {
    final base = switch (m.country) {
      GulfCountry.uae => m.basicSalary + m.housingAllowance,
      GulfCountry.bahrain => m.basicSalary + m.housingAllowance,
      _ => m.basicSalary,
    };
    return base / 30;
  }

  static String legalReference(GulfCountry country) => switch (country) {
        GulfCountry.saudiArabia => 'المادة 109 — نظام العمل السعودي',
        GulfCountry.uae => 'المادة 29 — قانون العمل الإماراتي 2021',
        GulfCountry.oman => 'المادة 61 — قانون العمل العُماني',
        GulfCountry.qatar => 'المادة 80 — قانون العمل القطري',
        GulfCountry.bahrain => 'المادة 57 — قانون العمل البحريني',
        GulfCountry.kuwait => 'المادة 70 — قانون العمل الكويتي',
      };

  static String wageBaseLabel(GulfCountry country) => switch (country) {
        GulfCountry.uae => 'الأساسي + بدل السكن ÷ 30',
        GulfCountry.bahrain => 'الأساسي + البدلات المعتادة ÷ 30',
        _ => 'الراتب الأساسي ÷ 30',
      };

  static String rulesSummary(GulfCountry country) => switch (country) {
        GulfCountry.saudiArabia =>
          '< 5 سنوات: 21 يوم · 5+ سنوات: 30 يوم · وعاء: الأساسي',
        GulfCountry.uae =>
          '< سنة: بالتناسب · سنة+: 30 يوم · وعاء: أساسي + سكن',
        GulfCountry.oman =>
          '< سنة: بالتناسب · سنة+: 30 يوم · وعاء: الأساسي',
        GulfCountry.qatar =>
          '< سنة: 21 يوم · سنة+: 30 يوم · وعاء: الأساسي',
        GulfCountry.bahrain =>
          '< سنة: بالتناسب · سنة+: 30 يوم · وعاء: أساسي + بدلات',
        GulfCountry.kuwait => '30 يوم سنوياً · وعاء: الراتب الأساسي',
      };
}
