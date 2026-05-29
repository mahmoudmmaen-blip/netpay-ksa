import 'package:netgulf/core/domain/gulf_country.dart';

/// نتيجة تحليل عقد العمل عبر Claude.
class ContractAnalysisResult {
  const ContractAnalysisResult({
    required this.financialTerms,
    required this.weakPoints,
    required this.missingRights,
    required this.summary,
    required this.country,
  });

  final String financialTerms;
  final String weakPoints;
  final String missingRights;
  final String summary;
  final GulfCountry country;
}
