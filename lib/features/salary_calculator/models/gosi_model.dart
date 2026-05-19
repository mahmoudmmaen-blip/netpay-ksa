import 'package:equatable/equatable.dart';
import 'package:netgulf/features/gosi/domain/entities/gosi_calculation_input.dart';
import 'package:netgulf/features/gosi/domain/entities/gosi_contribution_result.dart';
import 'package:netgulf/features/gosi/domain/entities/gosi_rate_breakdown.dart';
import 'package:netgulf/features/gosi/domain/enums/gosi_regime.dart';
import 'package:netgulf/features/gosi/domain/enums/nationality_type.dart';
import 'package:netgulf/features/gosi/domain/logic/gosi_calculator.dart';
import 'package:netgulf/features/salary_calculator/models/salary_allowances.dart';

export 'package:netgulf/features/salary_calculator/models/salary_allowances.dart';

/// الموديل المالي الرئيسي — مصدر واحد للأرقام (UI / History / PDF).
///
/// صافي الراتب = [totalGross] − [employeeGosi]
/// سقف الأجر = 45,000 ر.س
class GosiModel extends Equatable {
  const GosiModel({
    required this.calculationInput,
    required this.result,
    required this.totalGross,
    this.allowances,
    this.upcomingWarnings = const [],
  });

  final GosiCalculationInput calculationInput;
  final GosiContributionResult result;
  final double totalGross;
  final SalaryAllowances? allowances;
  final List<GosiRateWarning> upcomingWarnings;

  static const int wageCeiling = 45000;
  static const int jsonVersion = 1;

  // ── صافي / إجمالي ─────────────────────────────────────────────────────────

  double get netSalary => _round(totalGross - employeeGosi);

  // ── GOSI ────────────────────────────────────────────────────────────────────

  double get employeeGosi => result.employeeContribution;
  double get employerGosi => result.employerContribution;
  double get totalGosi => result.totalContribution;

  double get subscriptionWage => result.grossSalary;
  double get contributableWage => result.contributableWage;
  bool get wageCeilingApplied => result.wageCeilingApplied;

  double get employeePension => result.employeePensionAmount;
  double get employeeSaned => result.employeeSanedAmount;

  double get employerPension => result.employerPensionAmount;
  double get employerHazard => result.employerHazardAmount;
  double get employerSaned => result.employerSanedAmount;

  /// سنة المرحلة النشطة (يوليو) — null للنظام القديم.
  int? get activePhaseYear => result.phaseYear;

  // ── نسب ─────────────────────────────────────────────────────────────────────

  double get employeeRatePercent => result.employeeRates.totalPercent;
  double get employerRatePercent => result.employerRates.totalPercent;
  double get employeePensionPercent => result.employeeRates.pensionPercent;
  double get employeeSanedPercent => result.employeeRates.sanedPercent;

  // ── تنبيهات ───────────────────────────────────────────────────────────────

  bool get hasUpcomingWarning => upcomingWarnings.isNotEmpty;

  GosiRateWarning? get upcomingWarning =>
      hasUpcomingWarning ? upcomingWarnings.first : null;

  String? get upcomingWarningAr => upcomingWarning?.messageAr;
  double? get nextEmployeeRatePercent => upcomingWarning?.nextEmployeePercent;

  // ── Factories ───────────────────────────────────────────────────────────────

  factory GosiModel.fromCalculationInput({
    required GosiCalculationInput calculationInput,
    required GosiContributionResult result,
    required double totalGross,
    SalaryAllowances? allowances,
    List<GosiRateWarning> upcomingWarnings = const [],
  }) {
    return GosiModel(
      calculationInput: calculationInput,
      result: result,
      totalGross: _round(totalGross),
      allowances: allowances,
      upcomingWarnings: upcomingWarnings,
    );
  }

  factory GosiModel.compute({
    required GosiCalculationInput calculationInput,
    required double totalGross,
    SalaryAllowances? allowances,
    GosiCalculator calculator = const GosiCalculator(),
    List<GosiRateWarning>? upcomingWarnings,
  }) {
    final result = calculator.calculate(calculationInput);
    final date = calculationInput.calculationDate ?? DateTime.now();
    final warnings = upcomingWarnings ??
        calculator.buildAllUpcomingWarnings(
          regime: calculationInput.regime,
          nationality: calculationInput.nationality,
          calculationDate: date,
        );

    return GosiModel.fromCalculationInput(
      calculationInput: calculationInput,
      result: result,
      totalGross: totalGross,
      allowances: allowances,
      upcomingWarnings: warnings,
    );
  }

  factory GosiModel.fromSalaryForm({
    required SalaryAllowances allowances,
    required NationalityType nationality,
    required GosiRegime regime,
    DateTime? calculationDate,
    GosiCalculator calculator = const GosiCalculator(),
  }) {
    if (!allowances.isValid) {
      throw ArgumentError('الرواتب والبدلات يجب أن تكون صفراً أو أكثر');
    }

    final date = calculationDate ?? DateTime.now();
    final calcInput = GosiCalculationInput(
      grossSalary: allowances.gosiSubscriptionWage,
      nationality: nationality,
      regime: regime,
      calculationDate: date,
    );

    return GosiModel.compute(
      calculationInput: calcInput,
      totalGross: allowances.totalGross,
      allowances: allowances,
      calculator: calculator,
    );
  }

  Map<String, dynamic> toJson() => {
        'version': jsonVersion,
        'calculationInput': _calculationInputToJson(calculationInput),
        'result': _resultToJson(result),
        'totalGross': totalGross,
        if (allowances != null) 'allowances': allowances!.toJson(),
        'upcomingWarnings': upcomingWarnings.map(_warningToJson).toList(),
      };

  factory GosiModel.fromJson(Map<String, dynamic> json) {
    return GosiModel(
      calculationInput: _calculationInputFromJson(
        json['calculationInput'] as Map<String, dynamic>,
      ),
      result: _resultFromJson(json['result'] as Map<String, dynamic>),
      totalGross: (json['totalGross'] as num).toDouble(),
      allowances: json['allowances'] != null
          ? SalaryAllowances.fromJson(
              json['allowances'] as Map<String, dynamic>,
            )
          : null,
      upcomingWarnings: (json['upcomingWarnings'] as List<dynamic>?)
              ?.map((e) => _warningFromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  /// يعيد بناء [GosiModel] من JSON [SalaryRecord] (كامل أو مسطّح).
  factory GosiModel.fromRecord(Map<String, dynamic> j) {
    final nested = j['gosi'];
    if (nested is Map<String, dynamic>) {
      return GosiModel.fromJson(nested);
    }

    final allowances = SalaryAllowances(
      basicSalary: (j['basicSalary'] as num).toDouble(),
      housingAllowance: (j['housingAllowance'] as num).toDouble(),
      otherAllowances: (j['otherAllowances'] as num?)?.toDouble() ?? 0,
      includeOtherInGosiBase: j['includeOtherInGosiBase'] as bool? ?? false,
    );

    return GosiModel.fromSalaryForm(
      allowances: allowances,
      nationality: NationalityType.values.byName(j['nationality'] as String),
      regime: GosiRegime.values.byName(j['regime'] as String),
      calculationDate: DateTime.parse(j['savedAt'] as String),
    );
  }

  static double _round(double v) => double.parse(v.toStringAsFixed(2));

  @override
  List<Object?> get props => [
        calculationInput,
        result,
        totalGross,
        allowances,
        upcomingWarnings,
      ];
}

// ── JSON helpers ─────────────────────────────────────────────────────────────

Map<String, dynamic> _calculationInputToJson(GosiCalculationInput i) => {
      'grossSalary': i.grossSalary,
      'nationality': i.nationality.name,
      'regime': i.regime.name,
      'calculationDate': i.calculationDate?.toIso8601String(),
    };

GosiCalculationInput _calculationInputFromJson(Map<String, dynamic> json) {
  return GosiCalculationInput(
    grossSalary: (json['grossSalary'] as num).toDouble(),
    nationality: NationalityType.values.byName(json['nationality'] as String),
    regime: GosiRegime.values.byName(json['regime'] as String),
    calculationDate: json['calculationDate'] != null
        ? DateTime.parse(json['calculationDate'] as String)
        : null,
  );
}

Map<String, dynamic> _rateToJson(GosiRateBreakdown r) => {
      'pensionPercent': r.pensionPercent,
      'occupationalHazardPercent': r.occupationalHazardPercent,
      'sanedPercent': r.sanedPercent,
      'totalPercent': r.totalPercent,
    };

GosiRateBreakdown _rateFromJson(Map<String, dynamic> json) {
  return GosiRateBreakdown(
    pensionPercent: (json['pensionPercent'] as num).toDouble(),
    occupationalHazardPercent:
        (json['occupationalHazardPercent'] as num).toDouble(),
    sanedPercent: (json['sanedPercent'] as num).toDouble(),
    totalPercent: (json['totalPercent'] as num).toDouble(),
  );
}

Map<String, dynamic> _resultToJson(GosiContributionResult r) => {
      'grossSalary': r.grossSalary,
      'contributableWage': r.contributableWage,
      'wageCeilingApplied': r.wageCeilingApplied,
      'nationality': r.nationality.name,
      'regime': r.regime.name,
      'phaseYear': r.phaseYear,
      'employeeRates': _rateToJson(r.employeeRates),
      'employerRates': _rateToJson(r.employerRates),
      'employeeContribution': r.employeeContribution,
      'employerContribution': r.employerContribution,
      'totalContribution': r.totalContribution,
      'employeePensionAmount': r.employeePensionAmount,
      'employeeSanedAmount': r.employeeSanedAmount,
      'employerPensionAmount': r.employerPensionAmount,
      'employerHazardAmount': r.employerHazardAmount,
      'employerSanedAmount': r.employerSanedAmount,
    };

GosiContributionResult _resultFromJson(Map<String, dynamic> json) {
  return GosiContributionResult(
    grossSalary: (json['grossSalary'] as num).toDouble(),
    contributableWage: (json['contributableWage'] as num).toDouble(),
    wageCeilingApplied: json['wageCeilingApplied'] as bool,
    nationality: NationalityType.values.byName(json['nationality'] as String),
    regime: GosiRegime.values.byName(json['regime'] as String),
    phaseYear: json['phaseYear'] as int?,
    employeeRates:
        _rateFromJson(json['employeeRates'] as Map<String, dynamic>),
    employerRates:
        _rateFromJson(json['employerRates'] as Map<String, dynamic>),
    employeeContribution: (json['employeeContribution'] as num).toDouble(),
    employerContribution: (json['employerContribution'] as num).toDouble(),
    totalContribution: (json['totalContribution'] as num).toDouble(),
    employeePensionAmount: (json['employeePensionAmount'] as num).toDouble(),
    employeeSanedAmount: (json['employeeSanedAmount'] as num).toDouble(),
    employerPensionAmount: (json['employerPensionAmount'] as num).toDouble(),
    employerHazardAmount: (json['employerHazardAmount'] as num).toDouble(),
    employerSanedAmount: (json['employerSanedAmount'] as num).toDouble(),
  );
}

Map<String, dynamic> _warningToJson(GosiRateWarning w) => {
      'effectiveDate': w.effectiveDate.toIso8601String(),
      'phaseYear': w.phaseYear,
      'currentEmployeePercent': w.currentEmployeePercent,
      'nextEmployeePercent': w.nextEmployeePercent,
      'currentEmployerPercent': w.currentEmployerPercent,
      'nextEmployerPercent': w.nextEmployerPercent,
      'pensionIncreasePercent': w.pensionIncreasePercent,
      'daysUntilEffective': w.daysUntilEffective,
      'messageAr': w.messageAr,
      'messageEn': w.messageEn,
    };

GosiRateWarning _warningFromJson(Map<String, dynamic> json) {
  return GosiRateWarning(
    effectiveDate: DateTime.parse(json['effectiveDate'] as String),
    phaseYear: json['phaseYear'] as int,
    currentEmployeePercent:
        (json['currentEmployeePercent'] as num).toDouble(),
    nextEmployeePercent: (json['nextEmployeePercent'] as num).toDouble(),
    currentEmployerPercent:
        (json['currentEmployerPercent'] as num).toDouble(),
    nextEmployerPercent: (json['nextEmployerPercent'] as num).toDouble(),
    pensionIncreasePercent:
        (json['pensionIncreasePercent'] as num).toDouble(),
    daysUntilEffective: json['daysUntilEffective'] as int,
    messageAr: json['messageAr'] as String,
    messageEn: json['messageEn'] as String,
  );
}
