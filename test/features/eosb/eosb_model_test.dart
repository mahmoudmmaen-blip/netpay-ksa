import 'package:flutter_test/flutter_test.dart';
import 'package:netgulf/features/eosb/domain/models/eosb_model.dart';

void main() {
  test('termination — full salary per year', () {
    const model = EosbModel(
      yearsOfService: 3,
      basicSalary: 10000,
      housingAllowance: 2500,
      leavingReason: LeavingReason.termination,
    );
    expect(model.endOfServiceAmount, closeTo(37500, 0.01));
  });

  test('contractEnd — same as termination', () {
    const termination = EosbModel(
      yearsOfService: 5,
      basicSalary: 8000,
      leavingReason: LeavingReason.termination,
    );
    const contractEnd = EosbModel(
      yearsOfService: 5,
      basicSalary: 8000,
      leavingReason: LeavingReason.contractEnd,
    );
    expect(contractEnd.endOfServiceAmount, termination.endOfServiceAmount);
  });

  test('resignation < 2 years — zero', () {
    const model = EosbModel(
      yearsOfService: 1,
      basicSalary: 10000,
      leavingReason: LeavingReason.resignation,
    );
    expect(model.endOfServiceAmount, 0);
  });

  test('resignation 2-5 years — one third', () {
    const model = EosbModel(
      yearsOfService: 4,
      basicSalary: 12000,
      leavingReason: LeavingReason.resignation,
    );
    expect(model.endOfServiceAmount, closeTo(12000 * 4 / 3, 0.01));
  });

  test('resignation 5-10 years — two thirds', () {
    const model = EosbModel(
      yearsOfService: 7,
      basicSalary: 10000,
      leavingReason: LeavingReason.resignation,
    );
    expect(model.endOfServiceAmount, closeTo(10000 * 7 * 2 / 3, 0.01));
  });

  test('resignation 10+ years — full', () {
    const model = EosbModel(
      yearsOfService: 12,
      basicSalary: 9000,
      leavingReason: LeavingReason.resignation,
    );
    expect(model.endOfServiceAmount, closeTo(9000 * 12, 0.01));
  });

  test('vacationAllowance — 21 days before 5 years', () {
    const model = EosbModel(
      yearsOfService: 4,
      basicSalary: 30000,
    );
    expect(model.annualVacationDays, 21);
    expect(model.vacationAllowance, closeTo(30000 / 30 * 21, 0.01));
  });

  test('flightTicketAllowance — biannual', () {
    const biannual = EosbModel(
      yearsOfService: 2,
      ticketCost: 3000,
      ticketFrequency: FlightTicketFrequency.biannual,
    );
    expect(biannual.flightTicketAllowance, 12000);
  });

  test('totalEntitlements sums components', () {
    const model = EosbModel(
      yearsOfService: 2,
      basicSalary: 8000,
      housingAllowance: 2000,
      ticketCost: 2000,
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

  test('cashLeaveAllowance — basic/30 × accrued days', () {
    const model = EosbModel(
      basicSalary: 15000,
      accruedLeaveDays: 10,
    );
    expect(model.cashLeaveAllowance, closeTo(15000 / 30 * 10, 0.01));
    expect(
      model.totalEntitlements,
      greaterThan(model.endOfServiceAmount),
    );
  });
}
