import 'package:equatable/equatable.dart';

/// مدخلات البدلات — تُحوَّل إلى أجر اشتراك GOSI + إجمالي الراتب.
class SalaryAllowances extends Equatable {
  const SalaryAllowances({
    this.basicSalary = 0,
    this.housingAllowance = 0,
    this.otherAllowances = 0,
    this.includeOtherInGosiBase = false,
  });

  final double basicSalary;
  final double housingAllowance;
  final double otherAllowances;
  final bool includeOtherInGosiBase;

  double get totalGross =>
      basicSalary + housingAllowance + otherAllowances;

  double get gosiSubscriptionWage {
    var base = basicSalary + housingAllowance;
    if (includeOtherInGosiBase) base += otherAllowances;
    return base < 0 ? 0 : base;
  }

  bool get isValid =>
      basicSalary >= 0 &&
      housingAllowance >= 0 &&
      otherAllowances >= 0;

  Map<String, dynamic> toJson() => {
        'basicSalary': basicSalary,
        'housingAllowance': housingAllowance,
        'otherAllowances': otherAllowances,
        'includeOtherInGosiBase': includeOtherInGosiBase,
      };

  factory SalaryAllowances.fromJson(Map<String, dynamic> json) {
    return SalaryAllowances(
      basicSalary: (json['basicSalary'] as num?)?.toDouble() ?? 0,
      housingAllowance: (json['housingAllowance'] as num?)?.toDouble() ?? 0,
      otherAllowances: (json['otherAllowances'] as num?)?.toDouble() ?? 0,
      includeOtherInGosiBase: json['includeOtherInGosiBase'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        basicSalary,
        housingAllowance,
        otherAllowances,
        includeOtherInGosiBase,
      ];
}
