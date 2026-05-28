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
    test('5 years unfair dismissal — 15d×3 + 30d×2', () {
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
  });

  group('Qatar gratuity', () {
    test('5 years matches 21 days per year formula', () {
      final m = _model(country: GulfCountry.qatar, years: 5);
      final daily = 10000 / 30;
      final expected = 5 * 21 * daily;
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

  group('Bahrain indemnity', () {
    test('5 years — half month × 3 + full month × 2', () {
      final m = _model(country: GulfCountry.bahrain, years: 5);
      final wage = 12000;
      final expected = 3 * 0.5 * wage + 2 * wage;
      expect(EosbCalculator.calculateEndOfServiceAward(m), closeTo(expected, 0.01));
    });
  });

  group('Kuwait indemnity', () {
    test('7 years — 15 days × 5 + month × 2', () {
      final m = _model(country: GulfCountry.kuwait, years: 7);
      final wage = 12000;
      final expected = 5 * (wage / 2) + 2 * wage;
      expect(EosbCalculator.calculateEndOfServiceAward(m), closeTo(expected, 0.01));
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
  });
}
