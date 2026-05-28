import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/features/eosb/domain/eosb_constants.dart';
import 'package:netgulf/features/eosb/domain/logic/eosb_calculator.dart';
import 'package:netgulf/features/eosb/domain/models/eosb_model.dart';
import 'package:netgulf/features/eosb/providers/eosb_providers.dart';

void _runGccCountryFlow({
  required GulfCountry country,
  required void Function(
    ProviderContainer container,
    EosbCalculationResult result,
  ) assertResult,
}) {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  final notifier = container.read(eosbWizardProvider.notifier);
  notifier.setCountry(country);
  notifier.setTerminationType(EosbTerminationType.employerDismissalUnfair);
  notifier.setSalaries(basic: 10_000, housing: 1500);
  notifier.setServiceDuration(years: 5);

  expect(container.read(eosbActiveCountryRulesProvider), isNotNull);
  expect(container.read(eosbCountryLawSummaryProvider), isNotEmpty);

  final liveBeforeFinish = container.read(eosbCalculatorProvider);
  expect(liveBeforeFinish.input.country, country);
  expect(liveBeforeFinish.endOfServiceAmount, greaterThan(0));
  expect(liveBeforeFinish.legalReferences, isNotEmpty);

  expect(notifier.finishWizard(), isTrue);
  expect(container.read(eosbWizardProvider).showResults, isTrue);

  final finalized = container.read(eosbFinalizedResultProvider);
  expect(finalized, isNotNull);
  final results = container.read(eosbResultsProvider);
  expect(results.input.country, country);
  expect(results.countryLabel, contains(country.flag));

  assert(
    (results.endOfServiceAmount -
                EosbCalculator.calculateEndOfServiceAward(results.input))
            .abs() <
        0.01,
  );

  assertResult(container, results);
}

void main() {
  group('Oman full EOSB flow', () {
    test('wizard → live preview → results → legal refs', () {
      _runGccCountryFlow(
        country: GulfCountry.oman,
        assertResult: (container, result) {
          expect(container.read(eosbActiveCountryRulesProvider),
              isA<OmanEosbRules>());
          final daily = 10_000 / 30;
          final expected = 3 * 15 * daily + 2 * 30 * daily;
          expect(result.endOfServiceAmount, closeTo(expected, 0.01));
          expect(
            result.legalReferences.first.article,
            contains('49'),
          );
        },
      );
    });

    test('resignation under 3 years shows zero EOS in preview', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(eosbWizardProvider.notifier);
      notifier.setCountry(GulfCountry.oman);
      notifier.setTerminationType(EosbTerminationType.employeeResignation);
      notifier.setSalaries(basic: 8000);
      notifier.setServiceDuration(years: 2);

      final live = container.read(eosbCalculatorProvider);
      expect(live.endOfServiceAmount, 0);
      expect(notifier.finishWizard(), isTrue);
      expect(container.read(eosbResultsProvider).endOfServiceAmount, 0);
    });
  });

  group('Qatar full EOSB flow', () {
    test('wizard → live preview → results → PDF-ready refs', () {
      _runGccCountryFlow(
        country: GulfCountry.qatar,
        assertResult: (container, result) {
          expect(container.read(eosbActiveCountryRulesProvider),
              isA<QatarEosbRules>());
          final daily = 10_000 / 30;
          expect(result.endOfServiceAmount, closeTo(5 * 21 * daily, 0.01));
          expect(
            result.legalReferences.any((r) => r.article.contains('51')),
            isTrue,
          );
        },
      );
    });

    test('Oman → Qatar updates live preview and legal references', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(eosbWizardProvider.notifier);
      notifier.setTerminationType(EosbTerminationType.employerDismissalUnfair);
      notifier.setSalaries(basic: 10_000);
      notifier.setServiceDuration(years: 5);

      notifier.setCountry(GulfCountry.oman);
      final omanLive = container.read(eosbCalculatorProvider);
      expect(omanLive.legalReferences.first.article, contains('49'));

      notifier.setCountry(GulfCountry.qatar);
      final qatarLive = container.read(eosbCalculatorProvider);
      expect(qatarLive.input.country, GulfCountry.qatar);
      expect(qatarLive.legalReferences.first.article, contains('51'));
      expect(
        omanLive.legalReferences.first.article,
        isNot(contains('51')),
      );
      expect(
        container.read(eosbCountryLawSummaryProvider),
        contains('قطر'),
      );
    });

    test('live preview updates when country changes SA → Qatar', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(eosbWizardProvider.notifier);
      notifier.setTerminationType(EosbTerminationType.contractExpiry);
      notifier.setSalaries(basic: 12_000);
      notifier.setServiceDuration(years: 4);

      notifier.setCountry(GulfCountry.saudiArabia);
      final saAward =
          container.read(eosbEndOfServiceAwardProvider);

      notifier.setCountry(GulfCountry.qatar);
      final qaAward =
          container.read(eosbEndOfServiceAwardProvider);

      expect(saAward, isNot(equals(qaAward)));
      expect(container.read(eosbActiveCountryRulesProvider),
          isA<QatarEosbRules>());
    });
  });

  test('approximation disclaimer constant is defined', () {
    expect(
      EosbConstants.approximationDisclaimerAr,
      contains('استشارة قانونية'),
    );
    expect(
      EosbConstants.approximationDisclaimerAr,
      contains('محامٍ'),
    );
    expect(
      EosbConstants.approximationDisclaimerAr,
      contains('الجهات المختصة'),
    );
  });
}
