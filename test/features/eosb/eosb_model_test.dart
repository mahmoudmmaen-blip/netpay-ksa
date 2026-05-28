import 'package:flutter_test/flutter_test.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/features/eosb/domain/models/eosb_model.dart';

void main() {
  test('Saudi unfair dismissal — basic × years (Art. 85)', () {
    const model = EosbModel(
      yearsOfService: 3,
      basicSalary: 10000,
      housingAllowance: 2500,
      terminationType: EosbTerminationType.employerDismissalUnfair,
    );
    expect(model.endOfServiceAmount, closeTo(30000, 0.01));
  });

  test('valid employer dismissal — half of unfair award', () {
    const model = EosbModel(
      yearsOfService: 5,
      basicSalary: 10000,
      terminationType: EosbTerminationType.employerDismissalValidReason,
    );
    expect(model.endOfServiceAmount, closeTo(25000, 0.01));
  });

  test('contract expiry — full Art 84 after 1+ years', () {
    const model = EosbModel(
      yearsOfService: 3,
      basicSalary: 10000,
      terminationType: EosbTerminationType.contractExpiry,
    );
    // 10000 × 0.5 × 3 = 15000
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

  test('mutual agreement — custom percent on Art 84', () {
    const model = EosbModel(
      yearsOfService: 4,
      basicSalary: 12000,
      terminationType: EosbTerminationType.mutualAgreement,
      mutualAgreementPercent: 75,
    );
    final art84 = 12000 * 0.5 * 4;
    expect(model.endOfServiceAmount, closeTo(art84 * 0.75, 0.01));
  });

  test('resignation < 2 years Saudi — zero', () {
    const model = EosbModel(
      yearsOfService: 1,
      basicSalary: 10000,
      terminationType: EosbTerminationType.employeeResignation,
    );
    expect(model.endOfServiceAmount, 0);
  });

  test('resignation 2-5 years Saudi — Art 84 × one third', () {
    const model = EosbModel(
      yearsOfService: 4,
      basicSalary: 12000,
      terminationType: EosbTerminationType.employeeResignation,
    );
    expect(model.endOfServiceAmount, closeTo(8000, 0.01));
  });

  test('UAE gratuity — 21 days per year', () {
    const model = EosbModel(
      country: GulfCountry.uae,
      yearsOfService: 3,
      basicSalary: 12000,
      terminationType: EosbTerminationType.employerDismissalUnfair,
    );
    final daily = 12000 / 30;
    expect(model.endOfServiceAmount, closeTo(3 * 21 * daily, 0.01));
  });

  test('UAE valid dismissal — half gratuity', () {
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
      housingAllowance: 3000,
      accruedLeaveDays: 10,
    );
    expect(model.cashLeaveAllowance, closeTo(15000 / 30 * 10, 0.01));
  });

  test('flight ticket uses country estimate when cost is zero', () {
    const model = EosbModel(
      yearsOfService: 2,
      includeFlightTicket: true,
      ticketCost: 0,
    );
    expect(model.flightTicketAllowance, closeTo(1500 * 2, 0.01));
  });

  test('totalEntitlements sums components', () {
    const model = EosbModel(
      yearsOfService: 2,
      basicSalary: 8000,
      ticketCost: 2000,
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
