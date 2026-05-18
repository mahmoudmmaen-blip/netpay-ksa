import 'package:flutter_test/flutter_test.dart';
import 'package:netpay_ksa/core/constants/app_constants.dart';
import 'package:netpay_ksa/features/gosi/gosi.dart';

void main() {
  const calculator = GosiCalculator();

  group('GosiCalculator — legacy Saudi (9.75%)', () {
    test('9.75% employee / 11.75% employer on 10,000 SAR', () {
      final result = calculator.calculate(
        const GosiCalculationInput(
          grossSalary: 10000,
          nationality: NationalityType.saudi,
          regime: GosiRegime.legacy,
        ),
      );

      expect(result.employeeRates.pensionPercent, 9.0);
      expect(result.employeeRates.sanedPercent, 0.75);
      expect(result.employeeRates.totalPercent, 9.75);
      expect(result.employerRates.totalPercent, 11.75);
      expect(result.employeeContribution, 975);
      expect(result.employerContribution, 1175);
    });
  });

  group('GosiCalculator — new law phased (0.25% SANED)', () {
    test('July 2025 phase → 9.75% (9.5% + 0.25%)', () {
      final result = calculator.calculate(
        GosiCalculationInput(
          grossSalary: 10000,
          nationality: NationalityType.saudi,
          regime: GosiRegime.newLawPhased,
          calculationDate: DateTime(2025, 9, 1),
        ),
      );

      expect(result.phaseYear, 2025);
      expect(result.employeeRates.pensionPercent, 9.5);
      expect(result.employeeRates.sanedPercent, 0.25);
      expect(result.employeeRates.totalPercent, 9.75);
      expect(result.employeeContribution, 975);
    });

    test('March 2026 → phase 2025 still 9.75%', () {
      final result = calculator.calculate(
        GosiCalculationInput(
          grossSalary: 10000,
          nationality: NationalityType.saudi,
          regime: GosiRegime.newLawPhased,
          calculationDate: DateTime(2026, 3, 1),
        ),
      );

      expect(result.phaseYear, 2025);
      expect(result.employeeRates.totalPercent, 9.75);
      expect(result.employeeContribution, 975);
    });

    test('August 2026 → phase 2026 = 10.25% (10% + 0.25%)', () {
      final result = calculator.calculate(
        GosiCalculationInput(
          grossSalary: 20000,
          nationality: NationalityType.saudi,
          regime: GosiRegime.newLawPhased,
          calculationDate: DateTime(2026, 8, 1),
        ),
      );

      expect(result.phaseYear, 2026);
      expect(result.employeeRates.pensionPercent, 10.0);
      expect(result.employeeRates.sanedPercent, 0.25);
      expect(result.employeeRates.totalPercent, 10.25);
      expect(result.employerRates.totalPercent, 12.25);
      expect(result.employeeContribution, 2050);
      expect(result.employerContribution, 2450);
    });

    test('July 2027 phase → 10.75% employee', () {
      final result = calculator.calculate(
        GosiCalculationInput(
          grossSalary: 10000,
          nationality: NationalityType.saudi,
          regime: GosiRegime.newLawPhased,
          calculationDate: DateTime(2027, 8, 1),
        ),
      );

      expect(result.phaseYear, 2027);
      expect(result.employeeRates.pensionPercent, 10.5);
      expect(result.employeeRates.totalPercent, 10.75);
      expect(result.employeeContribution, 1075);
    });

    test('July 2028 phase → 11.25% employee', () {
      final result = calculator.calculate(
        GosiCalculationInput(
          grossSalary: 10000,
          nationality: NationalityType.saudi,
          regime: GosiRegime.newLawPhased,
          calculationDate: DateTime(2028, 8, 1),
        ),
      );

      expect(result.phaseYear, 2028);
      expect(result.employeeRates.pensionPercent, 11.0);
      expect(result.employeeRates.totalPercent, 11.25);
      expect(result.employeeContribution, 1125);
    });
  });

  group('GosiCalculator — progressive warnings', () {
    test('March 2026 warns July 2026 increase to 10.25%', () {
      final warnings = calculator.buildAllUpcomingWarnings(
        regime: GosiRegime.newLawPhased,
        nationality: NationalityType.saudi,
        calculationDate: DateTime(2026, 3, 1),
      );

      expect(warnings, isNotEmpty);
      expect(warnings.first.phaseYear, 2026);
      expect(warnings.first.currentEmployeePercent, 9.75);
      expect(warnings.first.nextEmployeePercent, 10.25);
    });

    test('no warnings for legacy regime', () {
      final warnings = calculator.buildAllUpcomingWarnings(
        regime: GosiRegime.legacy,
        nationality: NationalityType.saudi,
        calculationDate: DateTime(2026, 3, 1),
      );
      expect(warnings, isEmpty);
    });
  });

  group('GosiCalculator — non-Saudi', () {
    test('employee 0%, employer 2% hazard only', () {
      final result = calculator.calculate(
        const GosiCalculationInput(
          grossSalary: 15000,
          nationality: NationalityType.nonSaudi,
          regime: GosiRegime.legacy,
        ),
      );

      expect(result.employeeContribution, 0);
      expect(result.employerContribution, 300);
    });

    test('new law non-Saudi still 2% employer only', () {
      final result = calculator.calculate(
        GosiCalculationInput(
          grossSalary: 15000,
          nationality: NationalityType.nonSaudi,
          regime: GosiRegime.newLawPhased,
          calculationDate: DateTime(2026, 8, 1),
        ),
      );

      expect(result.employeeContribution, 0);
      expect(result.employerContribution, 300);
    });
  });

  group('GosiCalculator — wage ceiling 45,000', () {
    test('caps contributable wage — legacy', () {
      final result = calculator.calculate(
        const GosiCalculationInput(
          grossSalary: 60000,
          nationality: NationalityType.saudi,
          regime: GosiRegime.legacy,
        ),
      );

      expect(result.wageCeilingApplied, isTrue);
      expect(result.contributableWage, GosiConstants.wageCeilingSar);
      expect(result.employeeContribution, 4387.5);
    });

    test('caps contributable wage — new law 2026 phase', () {
      final result = calculator.calculate(
        GosiCalculationInput(
          grossSalary: 60000,
          nationality: NationalityType.saudi,
          regime: GosiRegime.newLawPhased,
          calculationDate: DateTime(2026, 8, 1),
        ),
      );

      expect(result.contributableWage, 45000);
      expect(result.employeeContribution, 4612.5); // 45000 * 10.25%
    });
  });

  group('GosiCalculator — edge cases', () {
    test('zero wage returns zero contributions', () {
      final result = calculator.calculate(
        const GosiCalculationInput(
          grossSalary: 0,
          nationality: NationalityType.saudi,
          regime: GosiRegime.newLawPhased,
        ),
      );

      expect(result.employeeContribution, 0);
      expect(result.employerContribution, 0);
    });

    test('negative wage throws', () {
      expect(
        () => calculator.calculate(
          const GosiCalculationInput(
            grossSalary: -1,
            nationality: NationalityType.saudi,
            regime: GosiRegime.legacy,
          ),
        ),
        throwsArgumentError,
      );
    });
  });
}
