import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netgulf/features/eosb/domain/models/eosb_model.dart';
import 'package:netgulf/features/legal_assistant/providers/eosb_wizard_provider.dart';

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
    notifier.setTermination(EosbTerminationType.contractExpiry);
    notifier.setSalaries(basic: 5000);
    notifier.setServiceDuration(years: 2);
    expect(notifier.nextStep(), isTrue); // → step 1
    expect(notifier.nextStep(), isTrue); // → step 2
    expect(notifier.nextStep(), isTrue); // → results
    final model = container.read(eosbCalculationProvider);
    expect(model.endOfServiceAmount, greaterThan(0));
  });
}
