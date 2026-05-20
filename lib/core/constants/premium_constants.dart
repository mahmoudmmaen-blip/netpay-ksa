import 'package:flutter/material.dart';

/// ثوابت ومزايا Premium — مصدر واحد للنصوص.
abstract final class PremiumConstants {
  PremiumConstants._();

  static const int premiumPriceSar = 29;

  static const String premiumPriceLabel = '$premiumPriceSar ريال';
  static const String premiumPriceFull = '$premiumPriceSar ريال / سنة';

  static const String activateCta = 'فعّل Premium الآن';

  static const List<(IconData, String)> benefits = [
    (Icons.block_rounded, 'بدون إعلانات نهائياً'),
    (Icons.history_rounded, 'سجل رواتب غير محدود'),
    (Icons.picture_as_pdf_rounded, 'تصدير PDF غير محدود'),
    (Icons.compare_arrows_rounded, 'مقارنة العروض الكاملة'),
    (Icons.smart_toy_outlined, 'أولوية في المساعد القانوني'),
    (Icons.auto_awesome_rounded, 'ميزات مستقبلية'),
  ];
}
