import 'package:equatable/equatable.dart';
import 'package:netpay_ksa/features/gosi/domain/entities/gosi_rate_breakdown.dart';
import 'package:netpay_ksa/features/gosi/domain/enums/gosi_regime.dart';
import 'package:netpay_ksa/features/gosi/domain/enums/nationality_type.dart';

/// Full GOSI calculation output for one pay period.
class GosiContributionResult extends Equatable {
  const GosiContributionResult({
    required this.grossSalary,
    required this.contributableWage,
    required this.wageCeilingApplied,
    required this.nationality,
    required this.regime,
    required this.phaseYear,
    required this.employeeRates,
    required this.employerRates,
    required this.employeeContribution,
    required this.employerContribution,
    required this.totalContribution,
    required this.employeePensionAmount,
    required this.employeeSanedAmount,
    required this.employerPensionAmount,
    required this.employerHazardAmount,
    required this.employerSanedAmount,
  });

  final double grossSalary;
  final double contributableWage;
  final bool wageCeilingApplied;
  final NationalityType nationality;
  final GosiRegime regime;

  /// Calendar year of the active July phase (e.g. 2026). Null for legacy.
  final int? phaseYear;

  final GosiRateBreakdown employeeRates;
  final GosiRateBreakdown employerRates;

  final double employeeContribution;
  final double employerContribution;
  final double totalContribution;

  final double employeePensionAmount;
  final double employeeSanedAmount;
  final double employerPensionAmount;
  final double employerHazardAmount;
  final double employerSanedAmount;

  double get netAfterEmployeeGosi => grossSalary - employeeContribution;

  @override
  List<Object?> get props => [
        grossSalary,
        contributableWage,
        wageCeilingApplied,
        nationality,
        regime,
        phaseYear,
        employeeRates,
        employerRates,
        employeeContribution,
        employerContribution,
        totalContribution,
        employeePensionAmount,
        employeeSanedAmount,
        employerPensionAmount,
        employerHazardAmount,
        employerSanedAmount,
      ];
}
