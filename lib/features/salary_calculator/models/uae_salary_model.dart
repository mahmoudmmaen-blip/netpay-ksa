import 'package:equatable/equatable.dart';
import 'package:netgulf/features/uae/domain/models/uae_model.dart';

/// نص ثنائي اللغة — عربي + إنجليزي.
class BilingualText {
  const BilingualText(this.ar, this.en);

  final String ar;
  final String en;

  String get combined => '$ar · $en';
}

/// تسميات حاسبة الإمارات.
abstract final class UaeSalaryLabels {
  UaeSalaryLabels._();

  static const basicSalary =
      BilingualText('الراتب الأساسي', 'Basic Salary');
  static const housingAllowance =
      BilingualText('بدل السكن', 'Housing Allowance');
  static const transportationAllowance =
      BilingualText('بدل المواصلات', 'Transportation Allowance');
  static const airTicketAllowance =
      BilingualText('بدل تذكرة الطيران', 'Air Ticket Allowance');
  static const yearsOfService =
      BilingualText('سنوات الخدمة', 'Years of Service');
  static const endOfService =
      BilingualText('مكافأة نهاية الخدمة', 'End of Service Gratuity');
  static const annualLeaveEncashment =
      BilingualText('بدل الإجازة السنوية', 'Annual Leave Encashment');
  static const healthInsurance =
      BilingualText('التأمين الصحي', 'Health Insurance');
  static const visaFees = BilingualText('رسوم التأشيرة', 'Visa Fees');
  static const totalGross = BilingualText('إجمالي الراتب', 'Total Gross');
  static const netSalary = BilingualText('صافي الراتب', 'Net Salary');
  static const monthlyDeductions =
      BilingualText('الخصومات الشهرية', 'Monthly Deductions');
  static const pensionScheme =
      BilingualText('نظام التقاعد', 'Pension Scheme');
  static const nationality = BilingualText('الجنسية', 'Nationality');
  static const citizen = BilingualText('مواطن', 'Citizen');
  static const expat = BilingualText('وافد', 'Expat');
  static const calculatorInputs =
      BilingualText('مدخلات الحاسبة', 'Calculator Inputs');
  static const gpssa = BilingualText('GPSSA — مواطن', 'GPSSA — Emirati');
  static const dews = BilingualText('DEWS — وافد', 'DEWS — Expat');
}

/// نموذج راتب الإمارات — GPSSA / DEWS + EOS + إجازة + تذكرة.
class UaeSalaryModel extends Equatable {
  const UaeSalaryModel({
    this.basicSalary = 0,
    this.housingAllowance = 0,
    this.transportationAllowance = 0,
    this.airTicketAllowanceMonthly = 0,
    this.yearsOfService = 0,
    this.unusedLeaveDays = 0,
    this.healthInsuranceMonthly = 0,
    this.visaFeesMonthly = 0,
    this.nationality = UAENationalityType.expat,
  });

  final double basicSalary;
  final double housingAllowance;
  final double transportationAllowance;
  final double airTicketAllowanceMonthly;
  final int yearsOfService;
  final int unusedLeaveDays;
  final double healthInsuranceMonthly;
  final double visaFeesMonthly;
  final UAENationalityType nationality;

  bool get isCitizen => nationality == UAENationalityType.citizen;

  double get dailyBasicSalary =>
      basicSalary <= 0 ? 0 : _round(basicSalary / 30);

  double get totalGross => _round(
        basicSalary +
            housingAllowance +
            transportationAllowance +
            airTicketAllowanceMonthly,
      );

  double get pensionableSalary => _round(basicSalary + housingAllowance);

  double get dewsMonthlyPercent => yearsOfService >= 5
      ? DewsRates.fivePlusYearsPercent
      : DewsRates.underFiveYearsPercent;

  /// GPSSA (مواطن) — 5% من الأجر الخاضع | DEWS (وافد) — % من الأساسي.
  double get pensionContribution {
    if (totalGross <= 0) return 0;
    if (isCitizen) {
      return _round(
        pensionableSalary * (GpssaRates.employeePercent / 100),
      );
    }
    return _round(basicSalary * (dewsMonthlyPercent / 100));
  }

  /// مكافأة نهاية الخدمة — قانون العمل الإماراتي.
  /// &lt; سنة: 0 | 1–5: 21 يوم/سنة | بعد 5: 21 يوم (5 سنوات) + 30 يوم/سنة إضافية.
  double get endOfServiceGratuity {
    if (yearsOfService < 1 || basicSalary <= 0) return 0;
    final daily = dailyBasicSalary;
    final y = yearsOfService;
    if (y <= 5) return _round(daily * UaeLaborConstants.gratuityDaysUnderFiveYears * y);
    final firstBand = daily * UaeLaborConstants.gratuityDaysUnderFiveYears * 5;
    final secondBand =
        daily * UaeLaborConstants.gratuityDaysFivePlusYears * (y - 5);
    return _round(firstBand + secondBand);
  }

  /// أيام الإجازة السنوية — 30 يوم بعد سنة خدمة.
  int get annualLeaveDays =>
      yearsOfService >= 1 ? UaeLaborConstants.vacationDaysPerYear : 0;

  /// قيمة بدل/صرف الإجازة السنوية (أيام غير مستخدمة أو كامل 30 يوم).
  double get annualLeaveEncashment {
    if (basicSalary <= 0) return 0;
    final days = unusedLeaveDays > 0 ? unusedLeaveDays : annualLeaveDays;
    if (days <= 0) return 0;
    return _round(dailyBasicSalary * days);
  }

  double get endOfServiceMonthlyAccrual =>
      yearsOfService < 1 ? 0 : _round(endOfServiceGratuity / 12);

  double get totalMonthlyDeductions => _round(
        pensionContribution + healthInsuranceMonthly + visaFeesMonthly,
      );

  double get netSalary => _round(totalGross - totalMonthlyDeductions);

  double get employerMonthlyContribution {
    if (!isCitizen || pensionableSalary <= 0) return 0;
    return _round(
      pensionableSalary * (GpssaRates.employerPercent / 100),
    );
  }

  String get schemeLabelAr =>
      isCitizen ? UaeSalaryLabels.gpssa.ar : UaeSalaryLabels.dews.ar;

  String get schemeLabelEn =>
      isCitizen ? UaeSalaryLabels.gpssa.en : UaeSalaryLabels.dews.en;

  String get schemeLabel => '$schemeLabelAr · $schemeLabelEn';

  /// @deprecated use [endOfServiceGratuity]
  double get gratuity => endOfServiceGratuity;

  UaeSalaryModel copyWith({
    double? basicSalary,
    double? housingAllowance,
    double? transportationAllowance,
    double? airTicketAllowanceMonthly,
    int? yearsOfService,
    int? unusedLeaveDays,
    double? healthInsuranceMonthly,
    double? visaFeesMonthly,
    UAENationalityType? nationality,
  }) {
    return UaeSalaryModel(
      basicSalary: basicSalary ?? this.basicSalary,
      housingAllowance: housingAllowance ?? this.housingAllowance,
      transportationAllowance:
          transportationAllowance ?? this.transportationAllowance,
      airTicketAllowanceMonthly:
          airTicketAllowanceMonthly ?? this.airTicketAllowanceMonthly,
      yearsOfService: yearsOfService ?? this.yearsOfService,
      unusedLeaveDays: unusedLeaveDays ?? this.unusedLeaveDays,
      healthInsuranceMonthly:
          healthInsuranceMonthly ?? this.healthInsuranceMonthly,
      visaFeesMonthly: visaFeesMonthly ?? this.visaFeesMonthly,
      nationality: nationality ?? this.nationality,
    );
  }

  static double _round(double v) => double.parse(v.toStringAsFixed(2));

  @override
  List<Object?> get props => [
        basicSalary,
        housingAllowance,
        transportationAllowance,
        airTicketAllowanceMonthly,
        yearsOfService,
        unusedLeaveDays,
        healthInsuranceMonthly,
        visaFeesMonthly,
        nationality,
      ];
}
