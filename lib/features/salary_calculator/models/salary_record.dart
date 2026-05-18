import 'package:equatable/equatable.dart';
import 'package:netpay_ksa/features/gosi/domain/enums/gosi_regime.dart';
import 'package:netpay_ksa/features/gosi/domain/enums/nationality_type.dart';
import 'package:netpay_ksa/features/salary_calculator/models/gosi_model.dart';

/// سجل راتب محفوظ — snapshot كامل من لحظة الحفظ.
class SalaryRecord extends Equatable {
  const SalaryRecord({
    required this.id,
    required this.savedAt,
    required this.label,
    required this.basicSalary,
    required this.housingAllowance,
    required this.otherAllowances,
    required this.includeOtherInGosiBase,
    required this.nationality,
    required this.regime,
    required this.gosi,
  });

  final String id;
  final DateTime savedAt;
  final String label;
  final double basicSalary;
  final double housingAllowance;
  final double otherAllowances;
  final bool includeOtherInGosiBase;
  final NationalityType nationality;
  final GosiRegime regime;
  final GosiModel gosi;

  // ── Computed ──────────────────────────────────────────────────────────────

  double get netSalary => gosi.netSalary;
  double get totalGross => gosi.totalGross;
  double get employeeGosi => gosi.employeeGosi;

  // ── JSON ──────────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'savedAt': savedAt.toIso8601String(),
        'label': label,
        'basicSalary': basicSalary,
        'housingAllowance': housingAllowance,
        'otherAllowances': otherAllowances,
        'includeOtherInGosiBase': includeOtherInGosiBase,
        'nationality': nationality.name,
        'regime': regime.name,
        'netSalary': gosi.netSalary,
        'totalGross': gosi.totalGross,
        'employeeGosi': gosi.employeeGosi,
        'employerGosi': gosi.employerGosi,
        'employeeRatePercent': gosi.employeeRatePercent,
        'employerRatePercent': gosi.employerRatePercent,
        'subscriptionWage': gosi.subscriptionWage,
        'contributableWage': gosi.contributableWage,
        'wageCeilingApplied': gosi.wageCeilingApplied,
        'employeePension': gosi.employeePension,
        'employeeSaned': gosi.employeeSaned,
        'employerPension': gosi.employerPension,
        'employerHazard': gosi.employerHazard,
        'employerSaned': gosi.employerSaned,
        'activePhaseYear': gosi.activePhaseYear,
      };

  factory SalaryRecord.fromJson(Map<String, dynamic> j) => SalaryRecord(
        id: j['id'] as String,
        savedAt: DateTime.parse(j['savedAt'] as String),
        label: j['label'] as String,
        basicSalary: (j['basicSalary'] as num).toDouble(),
        housingAllowance: (j['housingAllowance'] as num).toDouble(),
        otherAllowances: (j['otherAllowances'] as num).toDouble(),
        includeOtherInGosiBase: j['includeOtherInGosiBase'] as bool,
        nationality: NationalityType.values.byName(j['nationality'] as String),
        regime: GosiRegime.values.byName(j['regime'] as String),
        gosi: GosiModel.fromRecord(j),
      );

  @override
  List<Object?> get props => [id];
}