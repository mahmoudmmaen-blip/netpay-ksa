/// Which GOSI contribution schedule applies to the employee.
enum GosiRegime {
  /// Pre–July 2024 registration: 9% + 9% pension, 1% SANED each side.
  legacy,

  /// Hired on/after 3 Jul 2024 with phased +0.5%/year pension (Jul 2025–2028).
  newLawPhased,
}

extension GosiRegimeX on GosiRegime {
  String get labelAr => switch (this) {
        GosiRegime.legacy => 'النظام القديم',
        GosiRegime.newLawPhased => 'النظام الجديد (2024+)',
      };

  String get labelEn => switch (this) {
        GosiRegime.legacy => 'Legacy system',
        GosiRegime.newLawPhased => 'New law (2024+)',
      };
}
