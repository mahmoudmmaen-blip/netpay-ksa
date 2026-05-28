import 'package:flutter_test/flutter_test.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/features/eosb/domain/logic/eosb_calculator.dart';
import 'package:netgulf/features/eosb/domain/models/eosb_model.dart';

void main() {
  const calc = EosbCalculator();

  test('Saudi unfair dismissal — 100% basic × years', () {
    const model = EosbModel(
      yearsOfService: 3,
      basicSalary: 10000,
      terminationType: EosbTerminationType.employerDismissalUnfair,
    );
    expect(model.endOfServiceAmount, closeTo(30000, 0.01));
  });

  test('valid employer dismissal — 50%', () {
    const model = EosbModel(
      yearsOfService: 5,
      basicSalary: 10000,
      terminationType: EosbTerminationType.employerDismissalValidReason,
    );
    expect(model.endOfServiceAmount, closeTo(25000, 0.01));
  });

  test('resignation — Art 84 only (50% first 5 + 100% after)', () {
    const fourYears = EosbModel(
      yearsOfService: 4,
      basicSalary: 12000,
      terminationType: EosbTerminationType.employeeResignation,
    );
    expect(fourYears.endOfServiceAmount, closeTo(24000, 0.01));

    const sixYears = EosbModel(
      yearsOfService: 6,
      basicSalary: 10000,
      terminationType: EosbTerminationType.employeeResignation,
    );
    // 10000×0.5×5 + 10000×1 = 35000
    expect(sixYears.endOfServiceAmount, closeTo(35000, 0.01));
  });

  test('contract expiry — full Art 84 after 1+ years', () {
    const model = EosbModel(
      yearsOfService: 3,
      basicSalary: 10000,
      terminationType: EosbTerminationType.contractExpiry,
    );
    expect(model.endOfServiceAmount, closeTo(15000, 0.01));
  });

  test('contract expiry fixed < 1 year — half Art 84', () {
    const model = EosbModel(
      yearsOfService: 0,
      monthsOfService: 6,
      basicSalary: 10000,
      contractType: EosbContractType.fixed,
      terminationType: EosbTerminationType.contractExpiry,
    );
    final art84 = 10000 * 0.5 * 0.5;
    expect(model.endOfServiceAmount, closeTo(art84 * 0.5, 0.01));
  });

  test('mutual agreement — custom percent', () {
    const model = EosbModel(
      yearsOfService: 4,
      basicSalary: 12000,
      terminationType: EosbTerminationType.mutualAgreement,
      mutualAgreementPercent: 75,
    );
    expect(model.endOfServiceAmount, closeTo(24000 * 0.75, 0.01));
  });

  test('retirement — full Art 84', () {
    const model = EosbModel(
      yearsOfService: 8,
      basicSalary: 9000,
      terminationType: EosbTerminationType.retirementOrDeath,
    );
    // 9000×0.5×5 + 9000×3 = 49500
    expect(model.endOfServiceAmount, closeTo(49500, 0.01));
  });

  test('UAE unfair — 100% gratuity', () {
    const model = EosbModel(
      country: GulfCountry.uae,
      yearsOfService: 3,
      basicSalary: 12000,
      terminationType: EosbTerminationType.employerDismissalUnfair,
    );
    final daily = 12000 / 30;
    expect(model.endOfServiceAmount, closeTo(3 * 21 * daily, 0.01));
  });

  test('UAE valid dismissal — 50%', () {
    const model = EosbModel(
      country: GulfCountry.uae,
      yearsOfService: 3,
      basicSalary: 12000,
      terminationType: EosbTerminationType.employerDismissalValidReason,
    );
    final daily = 12000 / 30;
    expect(model.endOfServiceAmount, closeTo(3 * 21 * daily * 0.5, 0.01));
  });

  test('cash leave — (basic / 30) × days', () {
    const model = EosbModel(
      basicSalary: 15000,
      accruedLeaveDays: 10,
    );
    expect(model.cashLeaveAllowance, closeTo(5000, 0.01));
  });

  test('flight ticket auto-estimate', () {
    const model = EosbModel(
      yearsOfService: 2,
      includeFlightTicket: true,
    );
    expect(model.flightTicketAllowance, closeTo(3000, 0.01));
  });

  test('calculateEndOfService returns legal references for all types', () {
    for (final type in EosbTerminationType.values) {
      final model = EosbModel(
        yearsOfService: 5,
        basicSalary: 10000,
        terminationType: type,
      );
      final result = calc.calculateEndOfService(model);
      expect(result.legalReferences, isNotEmpty);
    }
  });

  test('totalEntitlements sums components', () {
    const model = EosbModel(
      yearsOfService: 2,
      basicSalary: 8000,
      includeFlightTicket: true,
    );
    expect(
      model.totalEntitlements,
      closeTo(
        model.endOfServiceAmount +
            model.vacationAllowance +
            model.flightTicketAllowance +
            model.cashLeaveAllowance,
        0.01,
      ),
    );
  });
}
