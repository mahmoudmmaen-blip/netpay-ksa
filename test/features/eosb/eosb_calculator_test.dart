import 'package:flutter_test/flutter_test.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/features/eosb/domain/logic/eosb_calculator.dart';
import 'package:netgulf/features/eosb/domain/models/eosb_model.dart';

void main() {
  const calc = EosbCalculator();

  test('calculateEndOfService returns components and total', () {
    const model = EosbModel(
      yearsOfService: 4,
      basicSalary: 10000,
      housingAllowance: 2000,
      terminationType: EosbTerminationType.contractExpiry,
    );
    final result = calc.calculateEndOfService(model);
    expect(result.endOfServiceAmount, greaterThan(0));
    expect(result.totalEntitlements, model.totalEntitlements);
    expect(result.components, isNotEmpty);
    expect(result.legalReferences, isNotEmpty);
  });

  test('UAE resignation factor in result', () {
    const model = EosbModel(
      country: GulfCountry.uae,
      yearsOfService: 4,
      basicSalary: 12000,
      terminationType: EosbTerminationType.employeeResignation,
    );
    final result = calc.calculate(model);
    expect(result.resignationFactorApplied, closeTo(1 / 3, 0.001));
  });
}
