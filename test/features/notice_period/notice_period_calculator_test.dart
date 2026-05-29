import 'package:flutter_test/flutter_test.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/features/eosb/domain/models/eosb_model.dart';
import 'package:netgulf/features/notice_period/domain/notice_period_model.dart';

void main() {
  group('NoticePeriodModel.totalServiceYears', () {
    test('combines years and months', () {
      const m = NoticePeriodModel(
        country: GulfCountry.saudiArabia,
        monthlyBasicSalary: 1000,
        serviceYears: 2,
        serviceMonths: 6,
      );
      expect(m.totalServiceYears, closeTo(2.5, 0.001));
    });
  });

  group('NoticePeriodCalculator.requiredDays', () {
    test('Saudi unlimited contract — 60 days', () {
      const m = NoticePeriodModel(
        country: GulfCountry.saudiArabia,
        monthlyBasicSalary: 10000,
        serviceYears: 2,
      );
      expect(m.requiredNoticeDays, 60);
    });

    test('Saudi fixed contract — 30 days', () {
      const m = NoticePeriodModel(
        country: GulfCountry.saudiArabia,
        monthlyBasicSalary: 10000,
        serviceYears: 2,
        contractType: EosbContractType.fixed,
      );
      expect(m.requiredNoticeDays, 30);
    });

    test('UAE under 6 months — 14 days', () {
      const m = NoticePeriodModel(
        country: GulfCountry.uae,
        monthlyBasicSalary: 8000,
        serviceMonths: 3,
      );
      expect(m.requiredNoticeDays, 14);
    });

    test('Kuwait — 90 days', () {
      const m = NoticePeriodModel(
        country: GulfCountry.kuwait,
        monthlyBasicSalary: 5000,
        serviceYears: 1,
      );
      expect(m.requiredNoticeDays, 90);
    });
  });

  group('NoticePeriodCalculator.compensation', () {
    test('full notice given — zero compensation', () {
      const m = NoticePeriodModel(
        country: GulfCountry.saudiArabia,
        monthlyBasicSalary: 30000,
        serviceYears: 5,
        noticeWasGiven: true,
        daysNoticeGiven: 60,
      );
      expect(m.compensationAmount, 0);
    });

    test('no notice — 60 missing days at 30000 salary', () {
      const m = NoticePeriodModel(
        country: GulfCountry.saudiArabia,
        monthlyBasicSalary: 30000,
        serviceYears: 5,
        noticeWasGiven: false,
      );
      expect(m.missingDays, 60);
      expect(m.compensationAmount, 60000);
    });
  });
}
