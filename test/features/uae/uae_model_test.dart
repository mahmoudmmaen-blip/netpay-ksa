import 'package:flutter_test/flutter_test.dart';
import 'package:netgulf/features/uae/domain/models/uae_model.dart';

void main() {
  test('GPSSA citizen — 5% employee on pensionable salary', () {
    const model = UaeModel(
      basicSalary: 10000,
      housingAllowance: 5000,
      nationality: UAENationalityType.citizen,
    );
    expect(model.monthlyDeduction, closeTo(750, 0.01));
    expect(model.employerMonthlyContribution, closeTo(1875, 0.01));
    expect(model.governmentMonthlyContribution, closeTo(375, 0.01));
    expect(model.netSalary, closeTo(14250, 0.01));
    expect(model.annualEntitlement, closeTo(9000, 0.01));
  });

  test('DEWS expat < 5 years — 5.83% of basic', () {
    const model = UaeModel(
      basicSalary: 12000,
      housingAllowance: 3000,
      yearsOfService: 3,
      nationality: UAENationalityType.expat,
    );
    expect(model.monthlyDeduction, closeTo(12000 * 0.0583, 0.01));
    expect(model.netSalary, closeTo(15000 - model.monthlyDeduction, 0.01));
  });

  test('DEWS expat 5+ years — 8.33% of basic', () {
    const model = UaeModel(
      basicSalary: 10000,
      yearsOfService: 7,
      nationality: UAENationalityType.expat,
    );
    expect(model.monthlyDeduction, closeTo(833, 0.01));
    expect(model.dewsMonthlyPercent, DewsRates.fivePlusYearsPercent);
  });
}
