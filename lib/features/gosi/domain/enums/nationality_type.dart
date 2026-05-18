enum NationalityType {
  saudi,
  nonSaudi,
}

extension NationalityTypeX on NationalityType {
  bool get isSaudi => this == NationalityType.saudi;

  String get labelAr => switch (this) {
        NationalityType.saudi => 'سعودي',
        NationalityType.nonSaudi => 'غير سعودي',
      };

  String get labelEn => switch (this) {
        NationalityType.saudi => 'Saudi',
        NationalityType.nonSaudi => 'Non-Saudi',
      };
}
