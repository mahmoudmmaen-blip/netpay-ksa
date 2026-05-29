import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/features/leave_balance/domain/leave_balance_calculator.dart';

/// نموذج حاسبة رصيد الإجازة السنوية.
class LeaveBalanceModel {
  const LeaveBalanceModel({
    required this.country,
    this.serviceYears = 0,
    this.serviceMonths = 0,
    this.basicSalary = 0,
    this.housingAllowance = 0,
    this.usedLeaveDays = 0,
    this.pendingLeaveDays = 0,
  });

  final GulfCountry country;
  final int serviceYears;
  final int serviceMonths;
  final double basicSalary;
  final double housingAllowance;
  final int usedLeaveDays;
  final int pendingLeaveDays;

  double get totalServiceYears => serviceYears + serviceMonths / 12;

  int get annualEntitlementDays => LeaveBalanceCalculator.annualDays(this);

  double get dailyWage => LeaveBalanceCalculator.dailyWage(this);

  double get cashValue => pendingLeaveDays * dailyWage;

  /// رصيد مستحق من بداية السنة حتى اليوم (بالتناسب).
  double get accruedThisYear {
    final months = serviceMonths % 12;
    return (annualEntitlementDays / 12) * months;
  }

  String get legalReference => LeaveBalanceCalculator.legalReference(country);

  bool get showsHousingAllowance =>
      country == GulfCountry.uae || country == GulfCountry.bahrain;

  LeaveBalanceModel copyWith({
    GulfCountry? country,
    int? serviceYears,
    int? serviceMonths,
    double? basicSalary,
    double? housingAllowance,
    int? usedLeaveDays,
    int? pendingLeaveDays,
  }) {
    return LeaveBalanceModel(
      country: country ?? this.country,
      serviceYears: serviceYears ?? this.serviceYears,
      serviceMonths: serviceMonths ?? this.serviceMonths,
      basicSalary: basicSalary ?? this.basicSalary,
      housingAllowance: housingAllowance ?? this.housingAllowance,
      usedLeaveDays: usedLeaveDays ?? this.usedLeaveDays,
      pendingLeaveDays: pendingLeaveDays ?? this.pendingLeaveDays,
    );
  }
}
