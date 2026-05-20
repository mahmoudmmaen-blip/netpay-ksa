import 'package:flutter/material.dart';

/// ثوابت ومزايا Premium — مصدر واحد للنصوص والأسعار.
///
/// استخدم [PremiumConstants.benefits] في البوابة، الإعدادات، والترقية.
/// السعر والحدود المجانية مُعرّفة أيضاً في [AppConstants].
abstract final class PremiumConstants {
  PremiumConstants._();

  /// سعر الاشتراك السنوي (ريال سعودي).
  static const int premiumPriceSar = 29;

  static const String premiumPriceLabel = '$premiumPriceSar ريال';
  static const String premiumPriceFull = '$premiumPriceSar ريال / سنة';

  /// عنوان بوابة الترقية (bottom sheet).
  static const String upgradeTitle = 'ترقية إلى Premium';

  /// نص زر الشراء الموحّد.
  static const String activateCta = 'فعّل الآن';
  static const String renewCta = 'جدّد الآن';

  // ── حالات الاشتراك (Settings + Home) ─────────────────────────────────────

  static const String statusActive = 'Premium مفعّل';
  static const String statusExpired = 'انتهى الاشتراك';
  static const String statusNotSubscribed = 'غير مشترك';

  static const String statusActiveSubtitle =
      'بدون إعلانات — جميع الميزات مفتوحة';
  static const String statusExpiredSubtitle =
      'جدّد اشتراكك لاستعادة الميزات الكاملة';
  static const String statusNotSubscribedSubtitle =
      'افتح PDF، السجل الكامل، والمقارنة بدون إعلانات';

  /// قائمة المزايا — تُعرض مع ✓ في البوابة والإعدادات.
  static const List<(IconData, String)> benefits = [
    (Icons.block_rounded, 'بدون إعلانات نهائياً'),
    (Icons.history_rounded, 'سجل رواتب غير محدود'),
    (Icons.picture_as_pdf_rounded, 'تصدير PDF غير محدود'),
    (Icons.compare_arrows_rounded, 'مقارنة العروض الكاملة'),
    (Icons.smart_toy_outlined, 'أولوية في المساعد القانوني'),
    (Icons.auto_awesome_rounded, 'ميزات مستقبلية'),
  ];
}
