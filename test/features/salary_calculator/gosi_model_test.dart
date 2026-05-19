import 'package:flutter_test/flutter_test.dart';
import 'package:netgulf/features/gosi/gosi.dart';
import 'package:netgulf/features/salary_calculator/models/gosi_model.dart';

void main() {
  group('GosiModel.wageCeiling', () {
    test('equals 45000', () {
      expect(GosiModel.wageCeiling, 45000);
    });
  });

  group('GosiModel.fromCalculationInput', () {
    test('netSalary = totalGross - employeeGosi (Aug 2026, 10.25%)', () {
      const calculator = GosiCalculator();
      const allowances = SalaryAllowances(
        basicSalary: 15000,
        housingAllowance: 5000,
      );
      final input = GosiCalculationInput(
        grossSalary: 20000,
        nationality: NationalityType.saudi,
        regime: GosiRegime.newLawPhased,
        calculationDate: DateTime(2026, 8, 1),
      );
      final result = calculator.calculate(input);

      final model = GosiModel.fromCalculationInput(
        calculationInput: input,
        result: result,
        totalGross: allowances.totalGross,
      );

      expect(model.employeeRatePercent, 10.25);
      expect(model.employeePensionPercent, 10.0);
      expect(model.employeeSanedPercent, 0.25);
      expect(model.employeeGosi, 2050);
      expect(model.totalGross, 20000);
      expect(model.netSalary, 17950);
      expect(model.netSalary, model.totalGross - model.employeeGosi);
    });
  });

  group('GosiModel.fromSalaryForm', () {
    test('legacy 9.75% on 10,000 subscription wage', () {
      final model = GosiModel.fromSalaryForm(
        allowances: const SalaryAllowances(basicSalary: 10000),
        nationality: NationalityType.saudi,
        regime: GosiRegime.legacy,
      );
      expect(model.employeeRatePercent, 9.75);
      expect(model.employeeGosi, 975);
      expect(model.netSalary, model.totalGross - 975);
    });

    test('March 2026 warns July 2026 → 10.25%', () {
      final model = GosiModel.fromSalaryForm(
        allowances: const SalaryAllowances(basicSalary: 10000),
        nationality: NationalityType.saudi,
        regime: GosiRegime.newLawPhased,
        calculationDate: DateTime(2026, 3, 1),
      );
      expect(model.employeeRatePercent, 9.75);
      expect(model.hasUpcomingWarning, isTrue);
      expect(model.nextEmployeeRatePercent, 10.25);
      expect(model.upcomingWarningAr, isNotNull);
    });

    test('wage ceiling on 60,000 basic', () {
      final model = GosiModel.fromSalaryForm(
        allowances: const SalaryAllowances(basicSalary: 60000),
        nationality: NationalityType.saudi,
        regime: GosiRegime.legacy,
      );
      expect(model.wageCeilingApplied, isTrue);
      expect(model.contributableWage, 45000);
    });
  });

  group('GosiModel JSON', () {
    test('round-trip preserves netSalary', () {
      final original = GosiModel.fromSalaryForm(
        allowances: const SalaryAllowances(
          basicSalary: 10000,
          housingAllowance: 2000,
        ),
        nationality: NationalityType.saudi,
        regime: GosiRegime.newLawPhased,
        calculationDate: DateTime(2026, 8, 1),
      );
      final restored = GosiModel.fromJson(original.toJson());
      expect(restored.netSalary, original.netSalary);
      expect(restored.employeeGosi, original.employeeGosi);
      expect(restored.employeeRatePercent, 10.25);
      expect(restored.allowances?.basicSalary, 10000);
    });
  });

  group('GosiModel getters', () {
    test('wageCeiling is 45000', () {
      expect(GosiModel.wageCeiling, 45000);
    });

    test('employerGosi and employeeRatePercent exposed', () {
      final model = GosiModel.fromSalaryForm(
        allowances: const SalaryAllowances(basicSalary: 10000),
        nationality: NationalityType.saudi,
        regime: GosiRegime.legacy,
      );
      expect(model.employerGosi, greaterThan(0));
      expect(model.employeeRatePercent, 9.75);
      expect(model.hasUpcomingWarning, isFalse);
    });
  });
}
