import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/core/utils/gulf_country_code.dart';
import 'package:netgulf/features/allowances/data/allowances_rules.dart';

class AllowancesInput {
  const AllowancesInput({
    required this.country,
    required this.basicSalary,
    this.housingEnabled = true,
    this.housingAmount = 0,
    this.transportEnabled = true,
    this.transportAmount = 0,
    this.phoneEnabled = false,
    this.phoneAmount = 0,
    this.foodEnabled = false,
    this.foodAmount = 0,
    this.otherEnabled = false,
    this.otherAmount = 0,
  });

  final GulfCountry country;
  final double basicSalary;
  final bool housingEnabled;
  final double housingAmount;
  final bool transportEnabled;
  final double transportAmount;
  final bool phoneEnabled;
  final double phoneAmount;
  final bool foodEnabled;
  final double foodAmount;
  final bool otherEnabled;
  final double otherAmount;
}

class AllowancesResult {
  const AllowancesResult({
    required this.totalPackage,
    required this.gosiBase,
    required this.netAfterGosi,
    required this.employeeRate,
    required this.eosbIncludesHousing,
    required this.activeAllowancesTotal,
    required this.basicSalary,
  });

  final double totalPackage;
  final double gosiBase;
  final double netAfterGosi;
  final double employeeRate;
  final bool eosbIncludesHousing;
  final double activeAllowancesTotal;
  final double basicSalary;
}

abstract final class AllowancesCalculator {
  AllowancesCalculator._();

  static Map<String, dynamic> rules(GulfCountry country) =>
      allowancesRules[gulfCountryCode(country)]!;

  static AllowancesResult calculate(AllowancesInput input) {
    final r = rules(input.country);
    final rate = (r['employee_rate'] as num).toDouble();

    var housing = 0.0;
    if (input.housingEnabled) {
      housing = input.housingAmount > 0
          ? input.housingAmount
          : input.basicSalary * (r['housing_pct'] as num).toDouble();
    }

    var transport = 0.0;
    if (input.transportEnabled) {
      final maxT = (r['transport_max'] as num).toDouble();
      transport = input.transportAmount > 0
          ? input.transportAmount
          : (input.basicSalary * 0.1).clamp(0, maxT > 0 ? maxT : double.infinity);
      if (maxT > 0 && transport > maxT) transport = maxT;
    }

    final phone = input.phoneEnabled
        ? (input.phoneAmount > 0
            ? input.phoneAmount
            : (r['phone_typical'] as num).toDouble())
        : 0.0;
    final food = input.foodEnabled
        ? (input.foodAmount > 0
            ? input.foodAmount
            : (r['food_typical'] as num).toDouble())
        : 0.0;
    final other = input.otherEnabled ? input.otherAmount : 0.0;

    final allowancesTotal = housing + transport + phone + food + other;
    final total = input.basicSalary + allowancesTotal;

    var gosiBase = input.basicSalary;
    if (r['gosi_includes_housing'] == true) gosiBase += housing;
    if (r['gosi_includes_transport'] == true) gosiBase += transport;

    final deduction = gosiBase * rate;
    final net = total - deduction;

    return AllowancesResult(
      totalPackage: total,
      gosiBase: gosiBase,
      netAfterGosi: net,
      employeeRate: rate,
      eosbIncludesHousing: r['eosb_includes_housing'] == true,
      activeAllowancesTotal: allowancesTotal,
      basicSalary: input.basicSalary,
    );
  }
}
