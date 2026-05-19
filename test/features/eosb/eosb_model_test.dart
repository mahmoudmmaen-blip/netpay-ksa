import 'package:flutter_test/flutter_test.dart';
import 'package:netpay_ksa/features/eosb/domain/models/eosb_model.dart';

void main() {
  test('endOfServiceAmount — 3 years at 10000 basic + 2500 housing', () {
    const model = EosbModel(
      yearsOfService: 3,
      basicSalary: 10000,
      housingAllowance: 2500,
    );
    // 3 * 0.5 * 12500 = 18750
    expect(model.endOfServiceAmount, closeTo(18750, 0.01));
  });

  test('endOfServiceAmount — 7 years pro-rated', () {
    const model = EosbModel(
      yearsOfService: 7,
      basicSalary: 10000,
      housingAllowance: 0,
    );
    // 5*0.5*10000 + 2*1*10000 = 25000 + 20000 = 45000
    expect(model.endOfServiceAmount, closeTo(45000, 0.01));
  });

  test('vacationAllowance — 21 days before 5 years', () {
    const model = EosbModel(
      yearsOfService: 4,
      basicSalary: 30000,
      housingAllowance: 0,
    );
    expect(model.annualVacationDays, 21);
    expect(model.vacationAllowance, closeTo(30000 / 30 * 21, 0.01));
  });

  test('vacationAllowance — 30 days at 5+ years', () {
    const model = EosbModel(
      yearsOfService: 5,
      basicSalary: 30000,
    );
    expect(model.annualVacationDays, 30);
    expect(model.vacationAllowance, closeTo(30000, 0.01));
  });

  test('flightTicketAllowance — yearly vs biannual', () {
    const yearly = EosbModel(
      yearsOfService: 2,
      ticketCost: 3000,
      ticketFrequency: FlightTicketFrequency.yearly,
    );
    const biannual = EosbModel(
      yearsOfService: 2,
      ticketCost: 3000,
      ticketFrequency: FlightTicketFrequency.biannual,
    );
    expect(yearly.flightTicketAllowance, 6000);
    expect(biannual.flightTicketAllowance, 12000);
  });

  test('totalEntitlements sums components', () {
    const model = EosbModel(
      yearsOfService: 1,
      monthsOfService: 6,
      basicSalary: 8000,
      housingAllowance: 2000,
      ticketCost: 2000,
    );
    expect(
      model.totalEntitlements,
      closeTo(
        model.endOfServiceAmount +
            model.vacationAllowance +
            model.flightTicketAllowance,
        0.01,
      ),
    );
  });
}
