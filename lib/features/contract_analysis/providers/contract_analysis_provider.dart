import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netgulf/core/constants/api_keys.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/core/utils/feature_hive_store.dart';
import 'package:netgulf/features/contract_analysis/models/contract_analysis_result.dart';
import 'package:netgulf/features/contract_analysis/services/contract_analysis_service.dart';

export 'package:netgulf/features/contract_analysis/models/contract_analysis_result.dart';

const _hiveBox = 'contract_analysis';

final contractAnalysisCountryProvider =
    StateProvider<GulfCountry>((ref) => GulfCountry.saudiArabia);

final contractAnalysisFileNameProvider = StateProvider<String?>((ref) => null);

final contractAnalysisPdfProvider = StateProvider<Uint8List?>((ref) => null);

final contractAnalysisResultProvider =
    StateProvider<ContractAnalysisResult?>((ref) => null);

final contractAnalysisLoadingProvider = StateProvider<bool>((ref) => false);

final contractAnalysisErrorProvider = StateProvider<String?>((ref) => null);

final contractAnalysisProgressProvider = StateProvider<double>((ref) => 0);

/// تحميل آخر دولة محفوظة.
final contractAnalysisBootstrapProvider = FutureProvider<void>((ref) async {
  final saved = await FeatureHiveStore.get<String>(_hiveBox, 'country');
  if (saved == null) return;
  for (final c in GulfCountry.values) {
    if (c.name == saved) {
      ref.read(contractAnalysisCountryProvider.notifier).state = c;
      break;
    }
  }
});

class ContractAnalysisController {
  ContractAnalysisController(this._ref);

  final Ref _ref;

  Future<void> analyze() async {
    final pdf = _ref.read(contractAnalysisPdfProvider);
    final country = _ref.read(contractAnalysisCountryProvider);

    if (pdf == null || pdf.isEmpty) {
      _ref.read(contractAnalysisErrorProvider.notifier).state =
          'ارفع ملف PDF أولاً';
      return;
    }

    if (!ApiKeys.canUseLiveAnthropic &&
        ApiKeys.effectiveClaudeApiKey.isEmpty) {
      _ref.read(contractAnalysisErrorProvider.notifier).state =
          'أضف مفتاح Claude API في الإعدادات';
      return;
    }

    _ref.read(contractAnalysisLoadingProvider.notifier).state = true;
    _ref.read(contractAnalysisErrorProvider.notifier).state = null;
    _ref.read(contractAnalysisProgressProvider.notifier).state = 0.1;

    Timer? progressTimer;
    try {
      progressTimer = _startProgressTicker();
      final result = await ContractAnalysisService.analyze(
        pdfBytes: pdf,
        country: country,
      );
      _ref.read(contractAnalysisProgressProvider.notifier).state = 1;
      _ref.read(contractAnalysisResultProvider.notifier).state = result;
      await FeatureHiveStore.put(_hiveBox, 'country', country.name);
    } on ContractAnalysisException catch (e) {
      _ref.read(contractAnalysisErrorProvider.notifier).state = e.message;
    } catch (e) {
      _ref.read(contractAnalysisErrorProvider.notifier).state =
          e.toString().replaceFirst('Exception: ', '');
    } finally {
      progressTimer?.cancel();
      _ref.read(contractAnalysisLoadingProvider.notifier).state = false;
    }
  }

  Timer? _startProgressTicker() {
    var p = 0.15;
    return Timer.periodic(const Duration(milliseconds: 450), (t) {
      if (!_ref.read(contractAnalysisLoadingProvider)) {
        t.cancel();
        return;
      }
      if (p < 0.88) {
        p += 0.1;
        _ref.read(contractAnalysisProgressProvider.notifier).state = p;
      }
    });
  }

  void reset() {
    _ref.read(contractAnalysisResultProvider.notifier).state = null;
    _ref.read(contractAnalysisErrorProvider.notifier).state = null;
    _ref.read(contractAnalysisProgressProvider.notifier).state = 0;
  }

  void setPdf(Uint8List bytes, String name) {
    _ref.read(contractAnalysisPdfProvider.notifier).state = bytes;
    _ref.read(contractAnalysisFileNameProvider.notifier).state = name;
    reset();
  }

  void clearPdf() {
    _ref.read(contractAnalysisPdfProvider.notifier).state = null;
    _ref.read(contractAnalysisFileNameProvider.notifier).state = null;
    reset();
  }
}

final contractAnalysisControllerProvider = Provider<ContractAnalysisController>(
  (ref) => ContractAnalysisController(ref),
);
