/// دول الخليج المدعومة في NetGulf.
enum GulfCountry {
  saudiArabia,
  uae,
}

extension GulfCountryMeta on GulfCountry {
  String get flag => switch (this) {
        GulfCountry.saudiArabia => '🇸🇦',
        GulfCountry.uae => '🇦🇪',
      };

  String get nameAr => switch (this) {
        GulfCountry.saudiArabia => 'السعودية',
        GulfCountry.uae => 'الإمارات',
      };

  String get nameEn => switch (this) {
        GulfCountry.saudiArabia => 'Saudi Arabia',
        GulfCountry.uae => 'UAE',
      };

  String get schemeShort => switch (this) {
        GulfCountry.saudiArabia => 'GOSI',
        GulfCountry.uae => 'GPSSA / DEWS',
      };

  String get currencySymbol => switch (this) {
        GulfCountry.saudiArabia => 'ر.س',
        GulfCountry.uae => 'د.إ',
      };

  String get currencyLocale => switch (this) {
        GulfCountry.saudiArabia => 'ar_SA',
        GulfCountry.uae => 'ar_AE',
      };

  String get pensionLabel => switch (this) {
        GulfCountry.saudiArabia => 'خصم GOSI',
        GulfCountry.uae => 'خصم التقاعد',
      };

  /// اسم العملة كاملاً بالعربية.
  String get currencyNameAr => switch (this) {
        GulfCountry.saudiArabia => 'ريال سعودي',
        GulfCountry.uae => 'درهم إماراتي',
      };

  /// عنوان الحاسبة على الشاشة الرئيسية.
  String get calculatorTitleAr => switch (this) {
        GulfCountry.saudiArabia => 'حاسبة الراتب الصافي — GOSI',
        GulfCountry.uae => 'حاسبة الراتب الصافي — GPSSA / DEWS',
      };

  String get calculatorSubtitleAr => switch (this) {
        GulfCountry.saudiArabia =>
          'التأمينات الاجتماعية · نظام العمل السعودي',
        GulfCountry.uae => 'التقاعد · قانون العمل الإماراتي',
      };
}
