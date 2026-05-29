import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/features/contract_analyzer/domain/contract_analysis_result.dart';
import 'package:netgulf/features/contract_analyzer/services/contract_analyzer_service.dart';

export 'package:netgulf/features/contract_analyzer/domain/contract_analysis_result.dart';

final contractAnalyzerProvider = StateNotifierProvider<
    ContractAnalyzerNotifier, AsyncValue<ContractAnalysisResult?>>(
  (ref) => ContractAnalyzerNotifier(),
);

class ContractAnalyzerNotifier
    extends StateNotifier<AsyncValue<ContractAnalysisResult?>> {
  ContractAnalyzerNotifier() : super(const AsyncValue.data(null));

  Future<void> analyzeContract({
    required Uint8List pdfBytes,
    required GulfCountry country,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await ContractAnalyzerService.analyze(
        pdfBytes: pdfBytes,
        country: country,
      );
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() => state = const AsyncValue.data(null);
}
