import 'package:flutter_test/flutter_test.dart';
import 'package:netgulf/features/uae/domain/models/uae_model.dart';

void main() {
  test('GPSSA citizen — monthlyContribution 5%', () {
    const model = UaeModel(
      basicSalary: 10000,
      housingAllowance: 5000,
      yearsOfService: 3,
      nationality: UAENationalityType.citizen,
    );
    expect(model.monthlyContribution, closeTo(750, 0.01));
    expect(model.netSalary, closeTo(14250, 0.01));
    expect(model.annualGratuity, closeTo((10000 / 30) * 21, 0.01));
  });

  test('vacation — 30 days after 1 year', () {
    const withLeave = UaeModel(basicSalary: 9000, yearsOfService: 2);
    const noLeave = UaeModel(basicSalary: 9000, yearsOfService: 0);
    expect(withLeave.annualVacationDays, 30);
    expect(withLeave.annualVacationValue, closeTo(9000, 0.01));
    expect(noLeave.annualVacationDays, 0);
  });

  test('DEWS expat < 5 years — 5.83% of basic', () {
    const model = UaeModel(
      basicSalary: 12000,
      housingAllowance: 3000,
      yearsOfService: 3,
      nationality: UAENationalityType.expat,
    );
    expect(model.monthlyContribution, closeTo(12000 * 0.0583, 0.01));
    expect(model.annualGratuity, closeTo(model.monthlyContribution * 12, 0.01));
    expect(model.netSalary, closeTo(15000 - model.monthlyContribution, 0.01));
  });

  test('DEWS expat >= 5 years — 8.33% of basic', () {
    const model = UaeModel(
      basicSalary: 10000,
      yearsOfService: 7,
      nationality: UAENationalityType.expat,
    );
    expect(model.monthlyContribution, closeTo(833, 0.01));
    expect(model.dewsMonthlyPercent, DewsRates.fivePlusYearsPercent);
    expect(model.annualGratuity, closeTo(833 * 12, 0.01));
  });
}
