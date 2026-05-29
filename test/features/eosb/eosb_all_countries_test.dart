import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/features/eosb/domain/models/eosb_model.dart';
import 'package:netgulf/features/eosb/providers/eosb_providers.dart';

void main() {
  test('EosbCountryGrid lists all 6 GCC countries', () {
    expect(GulfCountry.values, hasLength(6));
    expect(
      GulfCountry.values.map((c) => c.nameAr).toList(),
      [
        'السعودية',
        'الإمارات',
        'عمان',
        'قطر',
        'البحرين',
        'الكويت',
      ],
    );
    expect(GulfCountry.oman.eosPensionSchemeLabel, 'Oman Pension');
    expect(GulfCountry.qatar.eosPensionSchemeLabel, 'Qatar Labor Law');
  });

  test('setCountry updates live calculation and legal references for each GCC country',
      () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(eosbWizardProvider.notifier);
    notifier.setTerminationType(EosbTerminationType.contractExpiry);
    notifier.setSalaries(basic: 10_000, housing: 1500);
    notifier.setServiceDuration(years: 5);

    final refsByCountry = <GulfCountry, String>{};

    for (final country in GulfCountry.values) {
      notifier.setCountry(country);

      final live = container.read(eosbCalculatorProvider);
      expect(live.input.country, country);
      expect(live.legalReferences, isNotEmpty);
      expect(live.countryLabel, contains(country.flag));
      expect(live.countryLabel, contains(country.nameAr));

      final summary = container.read(eosbCountryLawSummaryProvider);
      expect(summary, country.eosLawChipAr);

      final articleKey = live.legalReferences.first.article;
      refsByCountry[country] = articleKey;
    }

    // Each country should produce distinct legal framing where applicable.
    expect(
      refsByCountry[GulfCountry.saudiArabia],
      isNot(equals(refsByCountry[GulfCountry.qatar])),
    );
    expect(
      refsByCountry[GulfCountry.oman],
      isNot(equals(refsByCountry[GulfCountry.uae])),
    );
  });
}
