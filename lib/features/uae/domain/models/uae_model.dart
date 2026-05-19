// حاسبة الإمارات — GPSSA (مواطن) و DEWS/WPS (وافد) — قانون العمل الإماراتي.

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

/// نسب DEWS/WPS — وافد (% من الراتب الأساسي شهرياً).
abstract final class DewsRates {
  DewsRates._();
  static const double underFiveYearsPercent = 5.83;
  static const double fivePlusYearsPercent = 8.33;
}

/// إجازة سنوية بعد سنة خدمة كاملة.
abstract final class UaeLaborConstants {
  UaeLaborConstants._();
  static const int vacationDaysPerYear = 30;
  static const int gratuityDaysUnderFiveYears = 21;
  static const int gratuityDaysFivePlusYears = 30;
}

/// نموذج راتب الإمارات.
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

  double get pensionableSalary => totalGross;

  bool get isCitizen => nationality == UAENationalityType.citizen;

  double get dewsMonthlyPercent => yearsOfService >= 5
      ? DewsRates.fivePlusYearsPercent
      : DewsRates.underFiveYearsPercent;

  /// اشتراك/خصم الموظف الشهري (GPSSA أو DEWS).
  double get monthlyContribution {
    if (basicSalary <= 0 && housingAllowance <= 0) return 0;
    if (isCitizen) {
      return _round(pensionableSalary * (GpssaRates.employeePercent / 100));
    }
    return _round(basicSalary * (dewsMonthlyPercent / 100));
  }

  /// مستحق سنوي — وافد: تراكم DEWS | مواطن: استحقاق مكافأة سنوية تقريبية.
  double get annualGratuity {
    if (basicSalary <= 0) return 0;
    if (!isCitizen) {
      return _round(monthlyContribution * 12);
    }
    if (yearsOfService < 1) return 0;
    final dailyBasic = basicSalary / 30;
    final days = yearsOfService >= 5
        ? UaeLaborConstants.gratuityDaysFivePlusYears
        : UaeLaborConstants.gratuityDaysUnderFiveYears;
    return _round(dailyBasic * days);
  }

  /// إجازة سنوية: 30 يوماً بعد سنة خدمة.
  int get annualVacationDays =>
      yearsOfService >= 1 ? UaeLaborConstants.vacationDaysPerYear : 0;

  double get annualVacationValue =>
      _round((basicSalary / 30) * annualVacationDays);

  double get employerMonthlyContribution {
    if (!isCitizen || pensionableSalary <= 0) return 0;
    return _round(pensionableSalary * (GpssaRates.employerPercent / 100));
  }

  double get governmentMonthlyContribution {
    if (!isCitizen || pensionableSalary <= 0) return 0;
    return _round(pensionableSalary * (GpssaRates.governmentPercent / 100));
  }

  double get netSalary => _round(totalGross - monthlyContribution);

  String get schemeLabel =>
      isCitizen ? 'GPSSA (مواطن)' : 'DEWS / WPS (وافد)';

  String get nationalityLabel => switch (nationality) {
        UAENationalityType.citizen => 'مواطن',
        UAENationalityType.expat => 'وافد',
      };

  /// للتوافق مع الإصدارات السابقة.
  double get monthlyDeduction => monthlyContribution;

  double get annualEntitlement => annualGratuity;

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
