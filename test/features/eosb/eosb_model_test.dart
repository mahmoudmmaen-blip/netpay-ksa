import 'package:flutter_test/flutter_test.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/features/eosb/domain/models/eosb_model.dart';

void main() {
  test('Saudi termination — full salary per year', () {
    const model = EosbModel(
      yearsOfService: 3,
      basicSalary: 10000,
      housingAllowance: 2500,
      terminationType: EosbTerminationType.employerDismissalUnfair,
    );
    expect(model.endOfServiceAmount, closeTo(37500, 0.01));
  });

  test('contract expiry — same as unfair dismissal', () {
    const termination = EosbModel(
      yearsOfService: 5,
      basicSalary: 8000,
      terminationType: EosbTerminationType.employerDismissalUnfair,
    );
    const contractEnd = EosbModel(
      yearsOfService: 5,
      basicSalary: 8000,
      terminationType: EosbTerminationType.contractExpiry,
    );
    expect(contractEnd.endOfServiceAmount, termination.endOfServiceAmount);
  });

  test('valid employer dismissal — zero EOS', () {
    const model = EosbModel(
      yearsOfService: 5,
      basicSalary: 10000,
      terminationType: EosbTerminationType.employerDismissalValidReason,
    );
    expect(model.endOfServiceAmount, 0);
  });

  test('resignation < 2 years Saudi — zero', () {
    const model = EosbModel(
      yearsOfService: 1,
      basicSalary: 10000,
      terminationType: EosbTerminationType.employeeResignation,
    );
    expect(model.endOfServiceAmount, 0);
  });

  test('resignation 2-5 years Saudi — one third', () {
    const model = EosbModel(
      yearsOfService: 4,
      basicSalary: 12000,
      terminationType: EosbTerminationType.employeeResignation,
    );
    expect(model.endOfServiceAmount, closeTo(12000 * 4 / 3, 0.01));
  });

  test('UAE gratuity — 21 days per year cap', () {
    const model = EosbModel(
      country: GulfCountry.uae,
      yearsOfService: 3,
      basicSalary: 12000,
      terminationType: EosbTerminationType.employerDismissalUnfair,
    );
    final daily = 12000 / 30;
    expect(model.endOfServiceAmount, closeTo(3 * 21 * daily, 0.01));
  });

  test('cash leave allowance', () {
    const model = EosbModel(
      basicSalary: 15000,
      accruedLeaveDays: 10,
    );
    expect(model.cashLeaveAllowance, closeTo(15000 / 30 * 10, 0.01));
  });

  test('totalEntitlements sums components', () {
    const model = EosbModel(
      yearsOfService: 2,
      basicSalary: 8000,
      housingAllowance: 2000,
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
