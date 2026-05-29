import 'package:flutter_test/flutter_test.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/features/leave_balance/domain/leave_balance_model.dart';

void main() {
  group('annualEntitlementDays', () {
    test('Saudi 3 years — 21 days', () {
      const m = LeaveBalanceModel(
        country: GulfCountry.saudiArabia,
        serviceYears: 3,
      );
      expect(m.annualEntitlementDays, 21);
    });

    test('Saudi 6 years — 30 days', () {
      const m = LeaveBalanceModel(
        country: GulfCountry.saudiArabia,
        serviceYears: 6,
      );
      expect(m.annualEntitlementDays, 30);
    });

    test('Qatar under 1 year — 21 days', () {
      const m = LeaveBalanceModel(
        country: GulfCountry.qatar,
        serviceMonths: 8,
      );
      expect(m.annualEntitlementDays, 21);
    });
  });

  group('cashValue', () {
    test('10 pending days at 10000 basic — 3333.33', () {
      const m = LeaveBalanceModel(
        country: GulfCountry.saudiArabia,
        basicSalary: 10000,
        pendingLeaveDays: 10,
      );
      expect(m.dailyWage, closeTo(333.333, 0.01));
      expect(m.cashValue, closeTo(3333.33, 0.01));
    });

    test('UAE includes housing in daily wage', () {
      const m = LeaveBalanceModel(
        country: GulfCountry.uae,
        basicSalary: 8000,
        housingAllowance: 2000,
        pendingLeaveDays: 10,
      );
      expect(m.dailyWage, closeTo(333.333, 0.01));
      expect(m.cashValue, closeTo(3333.33, 0.01));
    });
  });

  group('showsHousingAllowance', () {
    test('UAE and Bahrain show housing', () {
      const uae = LeaveBalanceModel(country: GulfCountry.uae);
      const bh = LeaveBalanceModel(country: GulfCountry.bahrain);
      const sa = LeaveBalanceModel(country: GulfCountry.saudiArabia);
      expect(uae.showsHousingAllowance, isTrue);
      expect(bh.showsHousingAllowance, isTrue);
      expect(sa.showsHousingAllowance, isFalse);
    });
  });
}
