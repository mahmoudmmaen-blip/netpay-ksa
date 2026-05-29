import 'package:flutter_test/flutter_test.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/features/eosb/domain/models/eosb_model.dart';
import 'package:netgulf/features/notice_period/domain/notice_period_calculator.dart';
import 'package:netgulf/features/notice_period/domain/notice_period_model.dart';

void main() {
  group('NoticePeriodCalculator.requiredDays', () {
    test('Saudi unlimited contract — 60 days', () {
      const m = NoticePeriodModel(
        country: GulfCountry.saudiArabia,
        monthlyBasicSalary: 10000,
        totalServiceYears: 2,
      );
      expect(m.requiredNoticeDays, 60);
    });

    test('Saudi fixed contract — 30 days', () {
      const m = NoticePeriodModel(
        country: GulfCountry.saudiArabia,
        monthlyBasicSalary: 10000,
        totalServiceYears: 2,
        contractType: EosbContractType.fixed,
      );
      expect(m.requiredNoticeDays, 30);
    });

    test('UAE under 6 months — 14 days', () {
      const m = NoticePeriodModel(
        country: GulfCountry.uae,
        monthlyBasicSalary: 8000,
        totalServiceYears: 0.3,
      );
      expect(m.requiredNoticeDays, 14);
    });

    test('Kuwait — 90 days', () {
      const m = NoticePeriodModel(
        country: GulfCountry.kuwait,
        monthlyBasicSalary: 5000,
        totalServiceYears: 1,
      );
      expect(m.requiredNoticeDays, 90);
    });
  });

  group('NoticePeriodCalculator.compensation', () {
    test('full notice given — zero compensation', () {
      const m = NoticePeriodModel(
        country: GulfCountry.saudiArabia,
        monthlyBasicSalary: 30000,
        totalServiceYears: 5,
        noticeWasGiven: true,
        daysNoticeGiven: 60,
      );
      expect(m.compensationAmount, 0);
    });

    test('missing 30 days at 30000 salary — 30000 compensation', () {
      const m = NoticePeriodModel(
        country: GulfCountry.saudiArabia,
        monthlyBasicSalary: 30000,
        totalServiceYears: 5,
        noticeWasGiven: false,
      );
      expect(m.missingDays, 60);
      expect(m.compensationAmount, 60000);
    });
  });
}
