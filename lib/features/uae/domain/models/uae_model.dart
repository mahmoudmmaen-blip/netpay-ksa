// حاسبة الإمارات — GPSSA (مواطن) و DEWS (وافد).

/// جنسية الموظف في الإمارات.
enum UAENationalityType {
  citizen,
  expat,
}

/// نسب GPSSA — مواطن.
abstract final class GpssaRates {
  GpssaRates._();
  static const double employeePercent = 5.0;
  static const double employerPercent = 12.5;
  static const double governmentPercent = 2.5;
}

/// نسب DEWS — وافد (من الراتب الأساسي شهرياً).
abstract final class DewsRates {
  DewsRates._();
  static const double underFiveYearsPercent = 5.83;
  static const double fivePlusYearsPercent = 8.33;
}

/// نموذج راتب الإمارات — خصم شهري وصافي ومستحق سنوي.
class UaeModel {
  const UaeModel({
    this.basicSalary = 0,
    this.housingAllowance = 0,
    this.yearsOfService = 0,
    this.nationality = UAENationalityType.citizen,
  });

  final double basicSalary;
  final double housingAllowance;
  final int yearsOfService;
  final UAENationalityType nationality;

  double get totalGross => _round(basicSalary + housingAllowance);

  /// أجر الاشتراك — GPSSA على الأساسي + السكن.
  double get pensionableSalary => totalGross;

  bool get isCitizen => nationality == UAENationalityType.citizen;

  /// نسبة DEWS الشهرية من الأساسي.
  double get dewsMonthlyPercent => yearsOfService >= 5
      ? DewsRates.fivePlusYearsPercent
      : DewsRates.underFiveYearsPercent;

  /// خصم الموظف الشهري.
  double get monthlyDeduction {
    if (basicSalary <= 0 && housingAllowance <= 0) return 0;
    if (isCitizen) {
      return _round(pensionableSalary * (GpssaRates.employeePercent / 100));
    }
    return _round(basicSalary * (dewsMonthlyPercent / 100));
  }

  /// مساهمة صاحب العمل شهرياً (GPSSA فقط).
  double get employerMonthlyContribution {
    if (!isCitizen || pensionableSalary <= 0) return 0;
    return _round(pensionableSalary * (GpssaRates.employerPercent / 100));
  }

  /// مساهمة الحكومة شهرياً (GPSSA فقط).
  double get governmentMonthlyContribution {
    if (!isCitizen || pensionableSalary <= 0) return 0;
    return _round(pensionableSalary * (GpssaRates.governmentPercent / 100));
  }

  /// إجمالي اشتراك الموظف سنوياً (DEWS أو GPSSA).
  double get annualEntitlement => _round(monthlyDeduction * 12);

  /// صافي الراتب = الإجمالي − خصم الموظف.
  double get netSalary => _round(totalGross - monthlyDeduction);

  String get schemeLabel => isCitizen ? 'GPSSA (مواطن)' : 'DEWS (وافد)';

  String get nationalityLabel => switch (nationality) {
        UAENationalityType.citizen => 'مواطن',
        UAENationalityType.expat => 'وافد',
      };

  UaeModel copyWith({
    double? basicSalary,
    double? housingAllowance,
    int? yearsOfService,
    UAENationalityType? nationality,
  }) {
    return UaeModel(
      basicSalary: basicSalary ?? this.basicSalary,
      housingAllowance: housingAllowance ?? this.housingAllowance,
      yearsOfService: yearsOfService ?? this.yearsOfService,
      nationality: nationality ?? this.nationality,
    );
  }

  static double _round(double v) => double.parse(v.toStringAsFixed(2));
}
