import 'dart:math' as math;

import 'package:netgulf/core/domain/gulf_country.dart';

class HomeLoanInput {
  const HomeLoanInput({
    required this.country,
    required this.propertyPrice,
    required this.downPaymentPercent,
    required this.annualInterestRate,
    required this.loanYears,
    this.monthlySalary = 0,
  });

  final GulfCountry country;
  final double propertyPrice;
  final double downPaymentPercent;
  final double annualInterestRate;
  final int loanYears;
  final double monthlySalary;
}

class HomeLoanAmortizationYear {
  const HomeLoanAmortizationYear({
    required this.year,
    required this.principalPaid,
    required this.interestPaid,
    required this.remainingBalance,
  });

  final int year;
  final double principalPaid;
  final double interestPaid;
  final double remainingBalance;
}

class HomeLoanResult {
  const HomeLoanResult({
    required this.loanAmount,
    required this.monthlyPayment,
    required this.totalPaid,
    required this.totalInterest,
    required this.interestPercent,
    required this.affordabilityRatio,
    required this.affordabilityWarning,
    required this.yearlyBreakdown,
  });

  final double loanAmount;
  final double monthlyPayment;
  final double totalPaid;
  final double totalInterest;
  final double interestPercent;
  final double? affordabilityRatio;
  final bool affordabilityWarning;
  final List<HomeLoanAmortizationYear> yearlyBreakdown;
}

abstract final class HomeLoanCalculator {
  HomeLoanCalculator._();

  static double defaultRate(GulfCountry country) => switch (country) {
        GulfCountry.saudiArabia => 5.5,
        GulfCountry.uae => 4.5,
        GulfCountry.qatar => 4.0,
        GulfCountry.kuwait => 3.5,
        GulfCountry.bahrain => 5.0,
        GulfCountry.oman => 5.5,
      };

  static HomeLoanResult calculate(HomeLoanInput input) {
    final down = input.downPaymentPercent / 100;
    final loanAmount = input.propertyPrice * (1 - down);
    final months = input.loanYears * 12;
    final r = input.annualInterestRate / 100 / 12;

    double monthly;
    if (r <= 0) {
      monthly = loanAmount / months;
    } else {
      monthly = loanAmount *
          (r * math.pow(1 + r, months)) /
          (math.pow(1 + r, months) - 1);
    }

    final totalPaid = monthly * months;
    final totalInterest = totalPaid - loanAmount;
    final interestPct =
        loanAmount > 0 ? (totalInterest / loanAmount) * 100 : 0.0;

    double? affordRatio;
    var warn = false;
    if (input.monthlySalary > 0) {
      affordRatio = monthly / input.monthlySalary;
      warn = affordRatio > 0.33;
    }

    final yearly = <HomeLoanAmortizationYear>[];
    var balance = loanAmount;
    for (var y = 1; y <= input.loanYears; y++) {
      var yearPrincipal = 0.0;
      var yearInterest = 0.0;
      for (var m = 0; m < 12 && balance > 0.01; m++) {
        final interest = balance * r;
        final principal = monthly - interest;
        yearInterest += interest;
        yearPrincipal += principal;
        balance -= principal;
      }
      yearly.add(HomeLoanAmortizationYear(
        year: y,
        principalPaid: yearPrincipal,
        interestPaid: yearInterest,
        remainingBalance: balance.clamp(0, double.infinity),
      ));
    }

    return HomeLoanResult(
      loanAmount: loanAmount,
      monthlyPayment: monthly,
      totalPaid: totalPaid,
      totalInterest: totalInterest,
      interestPercent: interestPct,
      affordabilityRatio: affordRatio,
      affordabilityWarning: warn,
      yearlyBreakdown: yearly,
    );
  }
}
