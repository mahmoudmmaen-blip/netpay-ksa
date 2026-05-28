import 'package:flutter_test/flutter_test.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/features/eosb/domain/logic/eosb_calculator.dart';
import 'package:netgulf/features/eosb/domain/logic/eosb_country_rules.dart';
import 'package:netgulf/features/eosb/domain/models/eosb_model.dart';

EosbModel _model({
  required GulfCountry country,
  double years = 5,
  double basic = 10000,
  double housing = 2000,
  EosbTerminationType termination = EosbTerminationType.employerDismissalUnfair,
}) =>
    EosbModel(
      country: country,
      yearsOfService: years.floor(),
      monthsOfService: ((years - years.floor()) * 12).round(),
      basicSalary: basic,
      housingAllowance: housing,
      terminationType: termination,
    );

void main() {
  group('Oman gratuity', () {
    test('5 years termination — 15d×3 + 30d×2', () {
      final m = _model(country: GulfCountry.oman, years: 5);
      final daily = 10000 / 30;
      final expected = (3 * 15 * daily) + (2 * 30 * daily);
      expect(EosbCalculator.calculateEndOfServiceAward(m), closeTo(expected, 0.01));
    });

    test('resignation under 3 years — zero', () {
      final m = _model(
        country: GulfCountry.oman,
        years: 2,
        termination: EosbTerminationType.employeeResignation,
      );
      expect(EosbCalculator.calculateEndOfServiceAward(m), 0);
    });

    test('termination at 2 years — full gratuity (not resignation)', () {
      final m = _model(country: GulfCountry.oman, years: 2);
      final daily = 10000 / 30;
      final expected = 2 * 15 * daily;
      expect(EosbCalculator.calculateEndOfServiceAward(m), closeTo(expected, 0.01));
    });

    test('resignation after 3 years — full', () {
      final m = _model(
        country: GulfCountry.oman,
        years: 4,
        termination: EosbTerminationType.employeeResignation,
      );
      final full = const OmanEosbRules().fullGratuity(m);
      expect(EosbCalculator.calculateEndOfServiceAward(m), closeTo(full, 0.01));
    });
  });

  group('Qatar gratuity', () {
    test('5 years — 21 days per year', () {
      final m = _model(country: GulfCountry.qatar, years: 5);
      final daily = 10000 / 30;
      final expected = 5 * 21 * daily;
      expect(EosbCalculator.calculateEndOfServiceAward(m), closeTo(expected, 0.01));
    });

    test('7 years — 21×5 + 30×2', () {
      final m = _model(country: GulfCountry.qatar, years: 7);
      final daily = 10000 / 30;
      final expected = 5 * 21 * daily + 2 * 30 * daily;
      expect(EosbCalculator.calculateEndOfServiceAward(m), closeTo(expected, 0.01));
    });

    test('resignation 4 years — one third', () {
      final m = _model(
        country: GulfCountry.qatar,
        years: 4,
        termination: EosbTerminationType.employeeResignation,
      );
      final full = const QatarEosbRules().fullGratuity(m);
      expect(
        EosbCalculator.calculateEndOfServiceAward(m),
        closeTo(full / 3, 0.01),
      );
    });
  });

  group('Bahrain gratuity', () {
    test('5 years — 15d×3 + 30d×2 on wage base', () {
      final m = _model(country: GulfCountry.bahrain, years: 5);
      final wage = 12000;
      final daily = wage / 30;
      final expected = 3 * 15 * daily + 2 * 30 * daily;
      expect(EosbCalculator.calculateEndOfServiceAward(m), closeTo(expected, 0.01));
    });
  });

  group('Kuwait gratuity', () {
    test('5 years — 30 days (one month) per year', () {
      final m = _model(country: GulfCountry.kuwait, years: 5);
      final wage = 12000;
      expect(
        EosbCalculator.calculateEndOfServiceAward(m),
        closeTo(wage * 5, 0.01),
      );
    });

    test('under 1 year — zero', () {
      final m = _model(country: GulfCountry.kuwait, years: 0.5);
      expect(EosbCalculator.calculateEndOfServiceAward(m), 0);
    });

    test('resignation 4 years — half', () {
      final m = _model(
        country: GulfCountry.kuwait,
        years: 4,
        termination: EosbTerminationType.employeeResignation,
      );
      final full = const KuwaitEosbRules().fullGratuity(m);
      expect(
        EosbCalculator.calculateEndOfServiceAward(m),
        closeTo(full * 0.5, 0.01),
      );
    });
  });

  group('Legal references', () {
    test('each GCC country returns country-specific refs', () {
      for (final country in GulfCountry.values) {
        final m = _model(country: country, years: 3);
        final refs = EosbCalculator.buildLegalReferences(m);
        expect(refs, isNotEmpty);
        expect(refs.first.article, isNotEmpty);
      }
    });

    test('Bahrain refs mention 15/30 days', () {
      final m = _model(country: GulfCountry.bahrain, years: 4);
      final text = EosbCalculator.buildLegalReferences(m)
          .map((r) => r.summary)
          .join(' ');
      expect(text, contains('15'));
      expect(text, contains('30'));
    });

    test('Kuwait refs mention 30 days per year', () {
      final m = _model(country: GulfCountry.kuwait, years: 4);
      final text = EosbCalculator.buildLegalReferences(m)
          .map((r) => r.summary)
          .join(' ');
      expect(text, contains('30'));
    });
  });
}
