import 'package:flutter_test/flutter_test.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/features/eosb/domain/models/eosb_model.dart';

void main() {
  test('Saudi unfair dismissal — full Article 84 (basic + housing)', () {
    const model = EosbModel(
      yearsOfService: 3,
      basicSalary: 10000,
      housingAllowance: 2500,
      terminationType: EosbTerminationType.employerDismissalUnfair,
    );
    // (12500 ÷ 2) × 3 = 18750 — مكافأة كاملة دون خصم الاستقالة
    expect(model.endOfServiceAmount, closeTo(18750, 0.01));
  });

  test('contract expiry uses same Article 84 wage base', () {
    const unfair = EosbModel(
      yearsOfService: 3,
      basicSalary: 10000,
      housingAllowance: 2500,
      terminationType: EosbTerminationType.employerDismissalUnfair,
    );
    const contractEnd = EosbModel(
      yearsOfService: 3,
      basicSalary: 10000,
      housingAllowance: 2500,
      terminationType: EosbTerminationType.contractExpiry,
    );
    expect(unfair.endOfServiceAmount, closeTo(18750, 0.01));
    expect(contractEnd.endOfServiceAmount, closeTo(18750, 0.01));
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

  test('resignation 2-5 years Saudi — one third (Art. 85)', () {
    const model = EosbModel(
      yearsOfService: 4,
      basicSalary: 12000,
      terminationType: EosbTerminationType.employeeResignation,
    );
    // 12000 × 0.5 × 4 = 24000 · ثلث = 8000
    expect(model.endOfServiceAmount, closeTo(8000, 0.01));
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

  test('cash leave allowance uses monthly wage', () {
    const model = EosbModel(
      basicSalary: 15000,
      housingAllowance: 3000,
      accruedLeaveDays: 10,
    );
    expect(model.cashLeaveAllowance, closeTo(18000 / 30 * 10, 0.01));
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
