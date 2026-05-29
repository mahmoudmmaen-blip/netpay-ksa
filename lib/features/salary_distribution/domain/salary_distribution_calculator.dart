enum DistributionMode { classic503020, mode602020, custom }

class SalaryDistributionInput {
  const SalaryDistributionInput({
    required this.netSalary,
    required this.mode,
    this.needsPercent = 50,
    this.wantsPercent = 30,
    this.savingsPercent = 20,
    this.rent = 0,
    this.savingsYears = 5,
  });

  final double netSalary;
  final DistributionMode mode;
  final double needsPercent;
  final double wantsPercent;
  final double savingsPercent;
  final double rent;
  final int savingsYears;
}

class SalaryDistributionResult {
  const SalaryDistributionResult({
    required this.needsAmount,
    required this.wantsAmount,
    required this.savingsAmount,
    required this.needsPercent,
    required this.wantsPercent,
    required this.savingsPercent,
    required this.rentWarning,
    required this.rentPercentOfNet,
    required this.projectedSavings,
  });

  final double needsAmount;
  final double wantsAmount;
  final double savingsAmount;
  final double needsPercent;
  final double wantsPercent;
  final double savingsPercent;
  final bool rentWarning;
  final double rentPercentOfNet;
  final double projectedSavings;
}

abstract final class SalaryDistributionCalculator {
  SalaryDistributionCalculator._();

  static SalaryDistributionResult calculate(SalaryDistributionInput input) {
    late double n;
    late double w;
    late double s;

    switch (input.mode) {
      case DistributionMode.classic503020:
        n = 50;
        w = 30;
        s = 20;
      case DistributionMode.mode602020:
        n = 60;
        w = 20;
        s = 20;
      case DistributionMode.custom:
        final total =
            input.needsPercent + input.wantsPercent + input.savingsPercent;
        if (total <= 0) {
          n = w = s = 0;
        } else {
          n = input.needsPercent / total * 100;
          w = input.wantsPercent / total * 100;
          s = input.savingsPercent / total * 100;
        }
    }

    final needs = input.netSalary * n / 100;
    final wants = input.netSalary * w / 100;
    final savings = input.netSalary * s / 100;

    final rentPct =
        input.netSalary > 0 ? (input.rent / input.netSalary) * 100 : 0.0;
    final rentWarn = rentPct > 30;

    return SalaryDistributionResult(
      needsAmount: needs,
      wantsAmount: wants,
      savingsAmount: savings,
      needsPercent: n,
      wantsPercent: w,
      savingsPercent: s,
      rentWarning: rentWarn,
      rentPercentOfNet: rentPct,
      projectedSavings: savings * 12 * input.savingsYears,
    );
  }
}
