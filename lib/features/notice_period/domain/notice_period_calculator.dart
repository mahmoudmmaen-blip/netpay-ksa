import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/features/eosb/domain/models/eosb_model.dart';
import 'package:netgulf/features/notice_period/domain/notice_period_model.dart';

/// قواعد مدة إشعار الإنهاء وتعويض عدم الإشعار — ٦ دول خليجية.
abstract final class NoticePeriodCalculator {
  NoticePeriodCalculator._();

  static int requiredDays(NoticePeriodModel m) {
    return switch (m.country) {
      GulfCountry.saudiArabia =>
        m.contractType == EosbContractType.fixed ? 30 : 60,
      GulfCountry.uae => switch (m.totalServiceYears) {
          < 0.5 => 14,
          < 3 => 30,
          _ => 90,
        },
      GulfCountry.oman => m.totalServiceYears < 1 ? 15 : 30,
      GulfCountry.qatar => m.totalServiceYears < 2 ? 30 : 60,
      GulfCountry.bahrain => switch (m.totalServiceYears) {
          < 0.25 => 7,
          < 1 => 14,
          < 5 => 30,
          _ => 60,
        },
      GulfCountry.kuwait => 90,
    };
  }

  static double compensation(NoticePeriodModel m) {
    if (m.noticeWasGiven && m.daysNoticeGiven >= m.requiredNoticeDays) {
      return 0;
    }
    final missing = m.missingDays;
    if (missing <= 0) return 0;
    return m.dailyWage * missing;
  }

  static String legalReference(GulfCountry country) => switch (country) {
        GulfCountry.saudiArabia => 'المادة 75 — نظام العمل السعودي',
        GulfCountry.uae => 'المادة 43 — قانون العمل الإماراتي 2021',
        GulfCountry.oman => 'المادة 44 — قانون العمل العُماني',
        GulfCountry.qatar => 'المادة 43 — قانون العمل القطري 14/2004',
        GulfCountry.bahrain => 'المادة 100 — قانون العمل البحريني',
        GulfCountry.kuwait => 'المادة 44 — قانون العمل الكويتي 6/2010',
      };

  static String rulesSummary(GulfCountry country) => switch (country) {
        GulfCountry.saudiArabia =>
          'غير محدد: 60 يوم · محدد: 30 يوم أو حسب العقد',
        GulfCountry.uae =>
          '< 6 أشهر: 14 · 6ش–3س: 30 · > 3س: 90 يوم',
        GulfCountry.oman => '< سنة: 15 يوم · سنة فأكثر: 30 يوم',
        GulfCountry.qatar => '< سنتين: 30 · سنتان فأكثر: 60 يوم',
        GulfCountry.bahrain =>
          '< 3ش: 7 · 3ش–سنة: 14 · 1–5س: 30 · > 5س: 60 يوم',
        GulfCountry.kuwait =>
          'عقد غير محدد: 3 أشهر (موظف) / شهر (عامل)',
      };
}
