import 'package:netpay_ksa/core/constants/app_constants.dart';
import 'package:netpay_ksa/features/gosi/domain/entities/gosi_calculation_input.dart';
import 'package:netpay_ksa/features/gosi/domain/entities/gosi_contribution_result.dart';
import 'package:netpay_ksa/features/gosi/domain/enums/gosi_regime.dart';
import 'package:netpay_ksa/features/gosi/domain/enums/nationality_type.dart';
import 'package:netpay_ksa/features/gosi/domain/logic/gosi_rates_resolver.dart';

/// محرك GOSI — دقة 2026 (قديم 9.75% | جديد 10.25%+ مرحلي يوليو).
///
/// - سقف الأجر: 45,000 ر.س
/// - صافي الراتب (في [GosiModel]): إجمالي البدلات − اشتراك الموظف
class GosiCalculator {
  const GosiCalculator();

  GosiContributionResult calculate(GosiCalculationInput input) {
    if (input.grossSalary < 0) {
      throw ArgumentError.value(
        input.grossSalary,
        'grossSalary',
        'الراتب يجب أن يكون صفراً أو أكثر',
      );
    }

    final date = input.calculationDate ?? DateTime.now();
    final ceiling = input.customWageCeiling ?? GosiConstants.wageCeilingSar;
    final subscriptionWage = input.grossSalary;

    if (subscriptionWage == 0) {
      return _zeroResult(input, date);
    }

    final contributable = subscriptionWage.clamp(0.0, ceiling);
    final ceilingApplied = subscriptionWage > ceiling;

    final employeeRates = GosiRatesResolver.employeeRates(
      nationality: input.nationality,
      regime: input.regime,
      calculationDate: date,
    );
    final employerRates = GosiRatesResolver.employerRates(
      nationality: input.nationality,
      regime: input.regime,
      calculationDate: date,
    );

    final employeePension = _line(contributable, employeeRates.pensionPercent);
    final employeeSaned = _line(contributable, employeeRates.sanedPercent);
    final employerPension = _line(contributable, employerRates.pensionPercent);
    final employerHazard =
        _line(contributable, employerRates.occupationalHazardPercent);
    final employerSaned = _line(contributable, employerRates.sanedPercent);

    final employeeTotal = employeePension + employeeSaned;
    final employerTotal = employerPension + employerHazard + employerSaned;

    final phaseYear = input.regime == GosiRegime.newLawPhased
        ? GosiRatesResolver.resolvePhaseYear(date)
        : null;

    return GosiContributionResult(
      grossSalary: subscriptionWage,
      contributableWage: contributable,
      wageCeilingApplied: ceilingApplied,
      nationality: input.nationality,
      regime: input.regime,
      phaseYear: phaseYear,
      employeeRates: employeeRates,
      employerRates: employerRates,
      employeeContribution: _round(employeeTotal),
      employerContribution: _round(employerTotal),
      totalContribution: _round(employeeTotal + employerTotal),
      employeePensionAmount: _round(employeePension),
      employeeSanedAmount: _round(employeeSaned),
      employerPensionAmount: _round(employerPension),
      employerHazardAmount: _round(employerHazard),
      employerSanedAmount: _round(employerSaned),
    );
  }

  /// تنبيه الزيادة القادمة (أقرب يوليو).
  GosiRateWarning? buildNextIncreaseWarning({
    required GosiRegime regime,
    required NationalityType nationality,
    required DateTime calculationDate,
  }) {
    final warnings = buildAllUpcomingWarnings(
      regime: regime,
      nationality: nationality,
      calculationDate: calculationDate,
    );
    return warnings.isEmpty ? null : warnings.first;
  }

  /// كل الزيادات المرحلية القادمة (+0.5% سنوياً).
  List<GosiRateWarning> buildAllUpcomingWarnings({
    required GosiRegime regime,
    required NationalityType nationality,
    required DateTime calculationDate,
  }) {
    if (regime != GosiRegime.newLawPhased || !nationality.isSaudi) {
      return const [];
    }

    final currentEmp = GosiRatesResolver.employeeRates(
      nationality: nationality,
      regime: regime,
      calculationDate: calculationDate,
    );
    final currentEr = GosiRatesResolver.employerRates(
      nationality: nationality,
      regime: regime,
      calculationDate: calculationDate,
    );

    final upcoming = GosiRatesResolver.upcomingPhasesFrom(calculationDate);
    final warnings = <GosiRateWarning>[];

    for (final phase in upcoming) {
      final effectiveDate =
          GosiRatesResolver.julyPhaseStart(phase.phaseYear);
      if (!calculationDate.isBefore(effectiveDate)) continue;

      final days = effectiveDate.difference(calculationDate).inDays;
      final empDelta = phase.employeePercent - currentEmp.totalPercent;
      final erDelta = phase.employerPercent - currentEr.totalPercent;

      final empFrom = _fmt(currentEmp.totalPercent);
      final empTo = _fmt(phase.employeePercent);
      final erFrom = _fmt(currentEr.totalPercent);
      final erTo = _fmt(phase.employerPercent);
      final deltaEmp = _fmt(empDelta);
      final deltaEr = _fmt(erDelta);

      warnings.add(
        GosiRateWarning(
          effectiveDate: effectiveDate,
          phaseYear: phase.phaseYear,
          currentEmployeePercent: currentEmp.totalPercent,
          nextEmployeePercent: phase.employeePercent,
          currentEmployerPercent: currentEr.totalPercent,
          nextEmployerPercent: phase.employerPercent,
          pensionIncreasePercent: GosiConstants.phasedPensionStepPercent,
          daysUntilEffective: days,
          messageAr:
              'تنبيه زيادة GOSI — 1 يوليو ${phase.phaseYear} '
              '(بعد $days يوم): نسبة الموظف $empFrom% → $empTo% '
              '(+$deltaEmp نقطة، +${GosiConstants.phasedPensionStepPercent}% تقاعد، '
              'ساند ${GosiConstants.newLawSanedPercent}%). '
              'صاحب العمل $erFrom% → $erTo% (+$deltaEr).',
          messageEn:
              'GOSI increase 1 Jul ${phase.phaseYear} ($days days): '
              'employee $empFrom% → $empTo% (+$deltaEmp pp), '
              'employer $erFrom% → $erTo% (+$deltaEr pp).',
        ),
      );
    }

    return warnings;
  }

  GosiContributionResult _zeroResult(
    GosiCalculationInput input,
    DateTime date,
  ) {
    final employeeRates = GosiRatesResolver.employeeRates(
      nationality: input.nationality,
      regime: input.regime,
      calculationDate: date,
    );
    final employerRates = GosiRatesResolver.employerRates(
      nationality: input.nationality,
      regime: input.regime,
      calculationDate: date,
    );
    final phaseYear = input.regime == GosiRegime.newLawPhased
        ? GosiRatesResolver.resolvePhaseYear(date)
        : null;

    return GosiContributionResult(
      grossSalary: 0,
      contributableWage: 0,
      wageCeilingApplied: false,
      nationality: input.nationality,
      regime: input.regime,
      phaseYear: phaseYear,
      employeeRates: employeeRates,
      employerRates: employerRates,
      employeeContribution: 0,
      employerContribution: 0,
      totalContribution: 0,
      employeePensionAmount: 0,
      employeeSanedAmount: 0,
      employerPensionAmount: 0,
      employerHazardAmount: 0,
      employerSanedAmount: 0,
    );
  }

  double _line(double wage, double percent) => wage * (percent / 100);

  double _round(double v) => double.parse(v.toStringAsFixed(2));

  static String _fmt(double v) => v.toStringAsFixed(2);
}

/// تنبيه زيادة GOSI القادمة.
class GosiRateWarning {
  const GosiRateWarning({
    required this.effectiveDate,
    required this.phaseYear,
    required this.currentEmployeePercent,
    required this.nextEmployeePercent,
    required this.currentEmployerPercent,
    required this.nextEmployerPercent,
    required this.pensionIncreasePercent,
    required this.daysUntilEffective,
    required this.messageAr,
    required this.messageEn,
  });

  final DateTime effectiveDate;
  final int phaseYear;
  final double currentEmployeePercent;
  final double nextEmployeePercent;
  final double currentEmployerPercent;
  final double nextEmployerPercent;
  final double pensionIncreasePercent;
  final int daysUntilEffective;
  final String messageAr;
  final String messageEn;

  double get employeeIncrease =>
      nextEmployeePercent - currentEmployeePercent;
}
