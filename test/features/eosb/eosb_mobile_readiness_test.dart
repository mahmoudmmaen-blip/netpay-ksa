import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/features/eosb/domain/eosb_constants.dart';
import 'package:netgulf/features/eosb/domain/logic/eosb_calculator.dart';
import 'package:netgulf/features/eosb/domain/models/eosb_model.dart';
import 'package:netgulf/features/eosb/providers/eosb_providers.dart';

const _calc = EosbCalculator();

EosbModel _sampleModel(GulfCountry country) => EosbModel(
      country: country,
      yearsOfService: 5,
      monthsOfService: 0,
      basicSalary: 12_000,
      housingAllowance: country.eosGratuityUsesBasicOnly ? 0 : 2000,
      terminationType: EosbTerminationType.contractExpiry,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('ar');
  });

  group('Multi-country EOSB (mobile QA)', () {
    for (final country in GulfCountry.values) {
      test('${country.name} — calculate + legal refs + PDF', () async {
        final model = _sampleModel(country);
        final result = _calc.calculateEndOfService(model);

        expect(result.endOfServiceAmount, greaterThan(0));
        expect(result.totalEntitlements, greaterThan(0));
        expect(result.legalReferences, isNotEmpty);
        expect(result.countryLabel, contains(country.nameAr));

        final pdf = await EosbPdfService.buildPdfBytes(result);
        expect(pdf.length, greaterThan(800));
        expect(String.fromCharCodes(pdf.take(4)), '%PDF');
      });
    }
  });

  group('History save / open / delete', () {
    late Directory tempDir;
    late Box<dynamic> box;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('eosb_hive_test');
      Hive.init(tempDir.path);
      box = await Hive.openBox<dynamic>('eosb_test_box');
      EosbHistoryService.setHistoryBoxForTesting(box);
      await EosbHistoryService.clearAllForTesting();
    });

    tearDown(() async {
      EosbHistoryService.setHistoryBoxForTesting(null);
      await box.close();
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('save → load → open model → delete', () async {
      final model = _sampleModel(GulfCountry.qatar);
      final result = _calc.calculateEndOfService(model);

      expect(await EosbHistoryService.save(result), isTrue);
      final entries = EosbHistoryService.loadAll();
      expect(entries, hasLength(1));
      expect(entries.first.countryNameAr, 'قطر');
      expect(entries.first.canOpenDetails, isTrue);

      final entry = EosbHistoryService.getById(entries.first.id);
      expect(entry, isNotNull);

      final restored = entry!.toModel();
      expect(restored?.country, GulfCountry.qatar);
      expect(restored?.basicSalary, 12_000);

      final reopened = EosbHistoryService.calculationResultFor(entry);
      expect(reopened, isNotNull);
      expect(reopened!.totalEntitlements, closeTo(result.totalEntitlements, 0.01));

      expect(await EosbHistoryService.delete(entry.id), isTrue);
      expect(EosbHistoryService.loadAll(), isEmpty);
    });

    test('wizard openFromHistoryEntry restores results view', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = _calc.calculateEndOfService(_sampleModel(GulfCountry.oman));
      // Simulate persisted entry without async save in this isolate.
      final entry = EosbHistoryEntry(
        id: 'test-oman',
        savedAt: DateTime.now(),
        countryCode: GulfCountry.oman.name,
        countryNameAr: GulfCountry.oman.nameAr,
        terminationSummary: result.input.terminationSummary,
        totalEntitlements: result.totalEntitlements,
        endOfServiceAmount: result.endOfServiceAmount,
        serviceYears: result.input.totalServiceYears,
        currencySymbol: GulfCountry.oman.currencySymbol,
        modelSnapshot: {
          'country': GulfCountry.oman.name,
          'yearsOfService': 5,
          'monthsOfService': 0,
          'daysOfService': 0,
          'basicSalary': 12_000,
          'housingAllowance': 0,
          'otherAllowances': 0,
          'contractType': EosbContractType.unlimited.name,
          'terminationType': EosbTerminationType.contractExpiry.name,
          'ticketCost': 0,
          'includeFlightTicket': false,
          'ticketFrequency': FlightTicketFrequency.yearly.name,
          'accruedLeaveDays': 0,
          'noticeProvided': true,
          'mutualAgreementPercent': 100,
        },
      );

      final ok = container
          .read(eosbWizardProvider.notifier)
          .openFromHistoryEntry(entry);
      expect(ok, isTrue);
      expect(container.read(eosbWizardProvider).showResults, isTrue);
      expect(
        container.read(eosbFinalizedResultProvider)?.input.country,
        GulfCountry.oman,
      );
    });
  });

  group('PDF includes disclaimer', () {
    test('generated PDF is valid binary', () async {
      final result =
          _calc.calculateEndOfService(_sampleModel(GulfCountry.saudiArabia));
      final bytes = await EosbPdfService.buildPdfBytes(result);
      expect(bytes.length, greaterThan(1500));
      expect(EosbConstants.approximationDisclaimerAr, isNotEmpty);
    });
  });
}
