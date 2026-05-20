import 'package:flutter/material.dart';

/// ثوابت Premium — نصوص، ألوان، مزايا.
abstract final class PremiumConstants {
  PremiumConstants._();

  static const int premiumPriceSar = 29;
  static const String premiumPriceLabel = '$premiumPriceSar ريال';
  static const String premiumPriceFull = '$premiumPriceSar ريال / سنة';

  static const String premiumUpgradeTitle = 'ترقية إلى Premium';
  static const String premiumUpgradeSubtitle =
      'استمتع بتجربة خالية من الإعلانات ومميزات متقدمة';
  static const String upgradeButtonText = 'ترقية الآن';
  static const String activateCta = 'فعّل الآن';
  static const String renewCta = 'جدّد الآن';

  static const String statusActive = 'Premium مفعّل';
  static const String statusExpired = 'انتهى الاشتراك';
  static const String statusNotSubscribed = 'غير مشترك';
  static const String statusActiveSubtitle =
      'بدون إعلانات — جميع الميزات مفتوحة';
  static const String statusExpiredSubtitle =
      'جدّد اشتراكك لاستعادة الميزات الكاملة';
  static const String statusNotSubscribedSubtitle =
      'افتح PDF، السجل الكامل، والمقارنة بدون إعلانات';

  static const Color premiumColor = Color(0xFF10B981);
  static const Color premiumDarkColor = Color(0xFF059669);
  static const Color premiumGradientStart = Color(0xFF10B981);
  static const Color premiumGradientEnd = Color(0xFF34D399);
  static const String premiumBadgeText = 'Premium';
  static const String unlockAllFeatures = 'افتح كل المميزات';

  static const List<(IconData, String)> benefits = [
    (Icons.block_rounded, 'بدون إعلانات نهائياً'),
    (Icons.history_rounded, 'سجل رواتب غير محدود'),
    (Icons.picture_as_pdf_rounded, 'تصدير PDF غير محدود'),
    (Icons.compare_arrows_rounded, 'مقارنة العروض الكاملة'),
    (Icons.smart_toy_outlined, 'أولوية في المساعد القانوني'),
    (Icons.auto_awesome_rounded, 'ميزات مستقبلية'),
  ];
}
