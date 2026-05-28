import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netgulf/features/eosb/domain/logic/eosb_calculator.dart';
import 'package:netgulf/features/eosb/domain/models/eosb_model.dart';
import 'package:netgulf/features/legal_assistant/providers/eosb_calculator_provider.dart';

void main() {
  test('wizard blocks step 0 without termination type', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(eosbWizardProvider.notifier);
    expect(notifier.nextStep(), isFalse);
  });

  test('wizard produces model with termination', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(eosbWizardProvider.notifier);
    notifier.setTerminationType(EosbTerminationType.contractExpiry);
    notifier.setSalaries(basic: 5000);
    notifier.setServiceDuration(years: 2);
    expect(notifier.nextStep(), isTrue); // → step 1
    expect(notifier.nextStep(), isTrue); // → step 2
    expect(notifier.finishWizard(), isTrue);
    expect(container.read(eosbWizardProvider).showResults, isTrue);
    final result = container.read(eosbResultsProvider);
    expect(result.endOfServiceAmount, greaterThan(0));
    expect(result.totalEntitlements, greaterThan(0));
    expect(result.legalReferences, isNotEmpty);
    expect(container.read(eosbFinalizedResultProvider), isNotNull);
  });

  test('finalized result stays stable after finish', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(eosbWizardProvider.notifier);
    notifier.setTerminationType(EosbTerminationType.contractExpiry);
    notifier.setSalaries(basic: 10000, housing: 0);
    notifier.setServiceDuration(years: 3);
    notifier.finishWizard();
    final frozen = container.read(eosbResultsProvider).endOfServiceAmount;
    notifier.setSalaries(basic: 10000, housing: 5000);
    expect(
      container.read(eosbResultsProvider).endOfServiceAmount,
      frozen,
    );
    expect(
      container.read(eosbCalculatorProvider).endOfServiceAmount,
      greaterThan(frozen),
    );
  });

  test('all termination types produce valid finalized results', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(eosbWizardProvider.notifier);

    for (final type in EosbTerminationType.values) {
      notifier.reset();
      notifier.setTerminationType(type);
      notifier.setSalaries(basic: 12000, housing: 2000);
      notifier.setServiceDuration(years: 5, months: 3);
      if (type == EosbTerminationType.mutualAgreement) {
        notifier.setMutualAgreementPercent(60);
      }
      expect(notifier.finishWizard(), isTrue, reason: '$type');

      final result = container.read(eosbResultsProvider);
      final model = container.read(eosbWizardProvider).toModel();
      expect(
        result.endOfServiceAmount,
        EosbCalculator.calculateEndOfServiceAward(model),
      );
      expect(result.totalEntitlements, greaterThan(0));
      expect(result.legalReferences, isNotEmpty);
      expect(result.components, isNotEmpty);
    }
  });

  test('resumeEditing returns to wizard and clears finalized result', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(eosbWizardProvider.notifier);
    notifier.setTerminationType(EosbTerminationType.contractExpiry);
    notifier.setSalaries(basic: 8000);
    notifier.setServiceDuration(years: 2);
    notifier.finishWizard();
    expect(container.read(eosbWizardProvider).showResults, isTrue);

    notifier.resumeEditing(stepIndex: 1);
    expect(container.read(eosbWizardProvider).showResults, isFalse);
    expect(container.read(eosbWizardProvider).stepIndex, 1);
    expect(container.read(eosbFinalizedResultProvider), isNull);
  });

  test('live preview updates when housing changes', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(eosbWizardProvider.notifier);
    notifier.setTerminationType(EosbTerminationType.contractExpiry);
    notifier.setSalaries(basic: 10000, housing: 0);
    notifier.setServiceDuration(years: 3);
    final before = container.read(eosbEndOfServiceAwardProvider);
    notifier.setSalaries(basic: 10000, housing: 2500);
    final after = container.read(eosbEndOfServiceAwardProvider);
    expect(after, greaterThan(before));
    expect(
      after,
      EosbCalculator.calculateEndOfServiceAward(
        container.read(eosbWizardProvider).toModel(),
      ),
    );
  });
}
