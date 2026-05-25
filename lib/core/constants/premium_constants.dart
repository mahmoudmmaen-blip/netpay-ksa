import 'package:flutter/material.dart';
import 'package:netgulf/core/domain/gulf_country.dart';

class PremiumConstants {
  // ==================== نصوص عامة ====================
  static const String premiumBadgeText = 'Premium';

  static const String premiumUpgradeTitle = 'ترقية إلى Premium';
  /// alias — used in premium gate sheet title.
  static const String upgradeTitle = premiumUpgradeTitle;

  static const String premiumUpgradeSubtitle =
      'استمتع بتجربة كاملة بدون إعلانات ومميزات متقدمة';

  static const String upgradeButtonText = 'ترقية الآن';
  static const String activateCta = 'تفعيل Premium';
  static const String renewCta = 'تجديد الاشتراك';

  static const String monthlyPriceSar = '٤٩ ريال / شهر';
  static const String yearlyPriceSar = '٢٩ ريال / سنة';
  static const String premiumPriceFullSar = '٢٩ ريال/سنة';

  static const String monthlyPriceAed = '٤٩ درهم / شهر';
  static const String yearlyPriceAed = '٢٩ درهم / سنة';
  static const String premiumPriceFullAed = '٢٩ درهم/سنة';

  /// @deprecated use [monthlyPriceFor] / [premiumPriceFullFor]
  static const String monthlyPrice = monthlyPriceSar;
  static const String yearlyPrice = yearlyPriceSar;
  static const String premiumPriceFull = premiumPriceFullSar;

  // ==================== مميزات Premium ====================
  static const String benefits = 'مميزات Premium';
  static const String premiumBenefitsTitle = 'مميزات الاشتراك المدفوع';

  static const List<String> _benefitsSaudi = [
    'إخفاء جميع الإعلانات',
    'سجل GOSI غير محدود',
    'تقارير شهرية PDF',
    'مقارنة عروض العمل',
    'حاسبة الزيادة والترقيات',
    'أولوية في التحديثات',
  ];

  static const List<String> _benefitsUae = [
    'إخفاء جميع الإعلانات',
    'سجل GPSSA / DEWS غير محدود',
    'تقارير شهرية PDF',
    'نهاية الخدمة — قانون العمل الإماراتي',
    'صرف الإجازة السنوية + بدل تذكرة',
    'أولوية في التحديثات',
  ];

  /// مميزات حسب الدولة المختارة.
  static List<String> benefitItemsFor(GulfCountry country) => switch (country) {
        GulfCountry.saudiArabia => _benefitsSaudi,
        GulfCountry.uae => _benefitsUae,
      };

  /// للتوافق — افتراضياً السعودية.
  static List<String> get benefitItems => _benefitsSaudi;

  static String monthlyPriceFor(GulfCountry country) => switch (country) {
        GulfCountry.saudiArabia => monthlyPriceSar,
        GulfCountry.uae => monthlyPriceAed,
      };

  static String yearlyPriceFor(GulfCountry country) => switch (country) {
        GulfCountry.saudiArabia => yearlyPriceSar,
        GulfCountry.uae => yearlyPriceAed,
      };

  static String premiumPriceFullFor(GulfCountry country) => switch (country) {
        GulfCountry.saudiArabia => premiumPriceFullSar,
        GulfCountry.uae => premiumPriceFullAed,
      };

  /// زر التفعيل في بوابة Premium — Activate Premium CTA in gate sheet.
  static String activatePremiumCtaFor(GulfCountry country) => switch (country) {
        GulfCountry.saudiArabia => 'فعّل Premium — $premiumPriceFullSar',
        GulfCountry.uae => 'فعّل Premium — $premiumPriceFullAed',
      };

  static String calculatorLabelFor(GulfCountry country) => switch (country) {
        GulfCountry.saudiArabia => 'GOSI · التأمينات الاجتماعية',
        GulfCountry.uae => 'GPSSA / DEWS · قانون العمل الإماراتي',
      };

  // ==================== حالات الاشتراك ====================
  static const String statusActive = 'اشتراك نشط';
  static const String statusActiveSubtitle = 'مبروك! أنت تستمتع بكل المميزات';

  static const String statusExpired = 'انتهى الاشتراك';
  static const String statusExpiredSubtitle = 'اشتراكك انتهى، جدده الآن';

  static const String statusNotSubscribed = 'غير مشترك';
  static const String statusNotSubscribedSubtitle =
      'ترقَ إلى Premium وافتح كل المميزات';

  // ==================== ألوان ====================
  static const Color premiumColor = Color(0xFF10B981);
  static const Color premiumGradientStart = Color(0xFF10B981);
  static const Color premiumGradientEnd = Color(0xFF34D399);
  static const Color premiumDarkColor = Color(0xFF059669);
}
