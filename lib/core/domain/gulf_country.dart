/// دول الخليج المدعومة في NetGulf.
enum GulfCountry {
  saudiArabia,
  uae,
  oman,
  qatar,
  bahrain,
  kuwait,
  ;

  /// اسم مختصر للسعودية — يُستخدم في [EosbCountryGrid.allGccCountries].
  static const GulfCountry saudi = GulfCountry.saudiArabia;
}

extension GulfCountryMeta on GulfCountry {
  String get flag => switch (this) {
        GulfCountry.saudiArabia => '🇸🇦',
        GulfCountry.uae => '🇦🇪',
        GulfCountry.oman => '🇴🇲',
        GulfCountry.qatar => '🇶🇦',
        GulfCountry.bahrain => '🇧🇭',
        GulfCountry.kuwait => '🇰🇼',
      };

  String get nameAr => switch (this) {
        GulfCountry.saudiArabia => 'السعودية',
        GulfCountry.uae => 'الإمارات',
        GulfCountry.oman => 'عمان',
        GulfCountry.qatar => 'قطر',
        GulfCountry.bahrain => 'البحرين',
        GulfCountry.kuwait => 'الكويت',
      };

  String get nameEn => switch (this) {
        GulfCountry.saudiArabia => 'Saudi Arabia',
        GulfCountry.uae => 'UAE',
        GulfCountry.oman => 'Oman',
        GulfCountry.qatar => 'Qatar',
        GulfCountry.bahrain => 'Bahrain',
        GulfCountry.kuwait => 'Kuwait',
      };

  String get schemeShort => switch (this) {
        GulfCountry.saudiArabia => 'GOSI',
        GulfCountry.uae => 'GPSSA / DEWS',
        GulfCountry.oman => 'PASI',
        GulfCountry.qatar => 'GRSIA',
        GulfCountry.bahrain => 'SIO',
        GulfCountry.kuwait => 'PIFSS',
      };

  /// تسمية نظام التقاعد/العمل في معالج نهاية الخدمة (EOSB).
  String get eosPensionSchemeLabel => switch (this) {
        GulfCountry.saudiArabia => 'GOSI',
        GulfCountry.uae => 'GPSSA / DEWS',
        GulfCountry.oman => 'Oman Pension',
        GulfCountry.qatar => 'Qatar Labor Law',
        GulfCountry.bahrain => 'Bahrain Labor Law',
        GulfCountry.kuwait => 'Kuwait Labor Law',
      };

  String get currencySymbol => switch (this) {
        GulfCountry.saudiArabia => 'ر.س',
        GulfCountry.uae => 'د.إ',
        GulfCountry.oman => 'ر.ع',
        GulfCountry.qatar => 'ر.ق',
        GulfCountry.bahrain => 'د.ب',
        GulfCountry.kuwait => 'د.ك',
      };

  String get currencyLocale => switch (this) {
        GulfCountry.saudiArabia => 'ar_SA',
        GulfCountry.uae => 'ar_AE',
        GulfCountry.oman => 'ar_OM',
        GulfCountry.qatar => 'ar_QA',
        GulfCountry.bahrain => 'ar_BH',
        GulfCountry.kuwait => 'ar_KW',
      };

  String get pensionLabel => switch (this) {
        GulfCountry.saudiArabia => 'خصم GOSI',
        GulfCountry.uae => 'خصم التقاعد',
        GulfCountry.oman => 'خصم التأمينات',
        GulfCountry.qatar => 'خصم التقاعد',
        GulfCountry.bahrain => 'خصم التأمينات',
        GulfCountry.kuwait => 'خصم التأمينات',
      };

  /// اسم العملة كاملاً بالعربية.
  String get currencyNameAr => switch (this) {
        GulfCountry.saudiArabia => 'ريال سعودي',
        GulfCountry.uae => 'درهم إماراتي',
        GulfCountry.oman => 'ريال عُماني',
        GulfCountry.qatar => 'ريال قطري',
        GulfCountry.bahrain => 'دينار بحريني',
        GulfCountry.kuwait => 'دينار كويتي',
      };

  String get currencyNameEn => switch (this) {
        GulfCountry.saudiArabia => 'Saudi Riyal',
        GulfCountry.uae => 'UAE Dirham',
        GulfCountry.oman => 'Omani Rial',
        GulfCountry.qatar => 'Qatari Riyal',
        GulfCountry.bahrain => 'Bahraini Dinar',
        GulfCountry.kuwait => 'Kuwaiti Dinar',
      };

  String get currencyLabel => '$currencyNameAr · $currencyNameEn';

  /// اختصار العملة في حقول الإدخال.
  String get currencyShortAr => switch (this) {
        GulfCountry.saudiArabia => 'ريال',
        GulfCountry.uae => 'درهم',
        GulfCountry.oman => 'ريال',
        GulfCountry.qatar => 'ريال',
        GulfCountry.bahrain => 'دينار',
        GulfCountry.kuwait => 'دينار',
      };

  /// عنوان الحاسبة على الشاشة الرئيسية.
  String get calculatorTitleAr => switch (this) {
        GulfCountry.saudiArabia => 'حاسبة الراتب الصافي — GOSI',
        GulfCountry.uae => 'حاسبة الراتب الصافي — GPSSA / DEWS',
        GulfCountry.oman => 'حاسبة الراتب الصافي — PASI',
        GulfCountry.qatar => 'حاسبة الراتب الصافي — GRSIA',
        GulfCountry.bahrain => 'حاسبة الراتب الصافي — SIO',
        GulfCountry.kuwait => 'حاسبة الراتب الصافي — PIFSS',
      };

  String get calculatorSubtitleAr => switch (this) {
        GulfCountry.saudiArabia =>
          'التأمينات الاجتماعية · نظام العمل السعودي',
        GulfCountry.uae => 'التقاعد · قانون العمل الإماراتي',
        GulfCountry.oman => 'التأمينات · قانون العمل العُماني',
        GulfCountry.qatar => 'التقاعد · قانون العمل القطري',
        GulfCountry.bahrain => 'التأمينات · قانون العمل البحريني',
        GulfCountry.kuwait => 'التأمينات · قانون العمل الكويتي',
      };

  /// هل تُحسب مكافأة نهاية الخدمة على الأساسي فقط (بدون سكن).
  bool get eosGratuityUsesBasicOnly => switch (this) {
        GulfCountry.saudiArabia => false,
        GulfCountry.uae => true,
        GulfCountry.oman => true,
        GulfCountry.qatar => true,
        GulfCountry.bahrain => false,
        GulfCountry.kuwait => false,
      };

  /// وعاء الأجر لبدل الإجازات المتبقية = أساسي فقط.
  bool get eosLeaveDailyFromBasicOnly => eosGratuityUsesBasicOnly;

  /// شارة نظام العمل في معالج نهاية الخدمة.
  String get eosLawChipAr => switch (this) {
        GulfCountry.saudiArabia =>
          '🇸🇦 نظام العمل السعودي — المواد 84 و 85',
        GulfCountry.uae => '🇦🇪 قانون العمل الإماراتي — المادة 51',
        GulfCountry.oman => '🇴🇲 قانون العمل العُماني — المواد 49 و 50',
        GulfCountry.qatar =>
          '🇶🇦 قانون العمل القطري رقم 14 لسنة 2004 — المادة 51',
        GulfCountry.bahrain =>
          '🇧🇭 قانون العمل البحريني — 15/30 يوم أجر · شروط الاستقالة',
        GulfCountry.kuwait =>
          '🇰🇼 قانون العمل الكويتي — 30 يوم أجر عن كل سنة (م. 51)',
      };

  /// أقل مدة خدمة لاستحقاق مكافأة (سنوات).
  double get eosMinimumServiceYears => switch (this) {
        GulfCountry.saudiArabia => 0,
        GulfCountry.uae => 1,
        GulfCountry.oman => 1,
        GulfCountry.qatar => 1,
        GulfCountry.bahrain => 1,
        GulfCountry.kuwait => 1,
      };
}
