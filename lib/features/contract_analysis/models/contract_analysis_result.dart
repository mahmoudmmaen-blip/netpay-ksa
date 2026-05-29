import 'package:netgulf/core/domain/gulf_country.dart';

/// بند بدل مستخرج من العقد.
class ContractAllowanceItem {
  const ContractAllowanceItem({
    required this.name,
    required this.amount,
  });

  final String name;
  final double amount;

  factory ContractAllowanceItem.fromJson(Map<String, dynamic> json) {
    return ContractAllowanceItem(
      name: json['name']?.toString() ?? '',
      amount: ContractAnalysisResult.parseDouble(json['amount']),
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'amount': amount};
}

/// نتيجة تحليل عقد العمل (JSON من Claude).
class ContractAnalysisResult {
  const ContractAnalysisResult({
    this.salaryBasic,
    this.salaryTotal,
    this.currency = 'SAR',
    this.contractDurationMonths,
    this.noticePeriodDays,
    this.annualLeaveDays,
    this.allowances = const [],
    this.risks = const [],
    this.missingRights = const [],
    this.positivePoints = const [],
    this.overallScore = 5,
    this.country = GulfCountry.saudiArabia,
  });

  final double? salaryBasic;
  final double? salaryTotal;
  final String currency;
  final int? contractDurationMonths;
  final int? noticePeriodDays;
  final int? annualLeaveDays;
  final List<ContractAllowanceItem> allowances;
  final List<String> risks;
  final List<String> missingRights;
  final List<String> positivePoints;
  final int overallScore;
  final GulfCountry country;

  factory ContractAnalysisResult.fromJson(
    Map<String, dynamic> json, {
    GulfCountry country = GulfCountry.saudiArabia,
  }) {
    final allowancesRaw = json['allowances'];
    final allowances = allowancesRaw is List
        ? allowancesRaw
            .whereType<Map>()
            .map((e) => ContractAllowanceItem.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList()
        : <ContractAllowanceItem>[];

    return ContractAnalysisResult(
      salaryBasic: _nullableDouble(json['salary_basic']),
      salaryTotal: _nullableDouble(json['salary_total']),
      currency: json['currency']?.toString() ?? 'SAR',
      contractDurationMonths: _nullableInt(json['contract_duration_months']),
      noticePeriodDays: _nullableInt(json['notice_period_days']),
      annualLeaveDays: _nullableInt(json['annual_leave_days']),
      allowances: allowances,
      risks: _stringList(json['risks']),
      missingRights: _stringList(json['missing_rights']),
      positivePoints: _stringList(json['positive_points']),
      overallScore: (_nullableInt(json['overall_score']) ?? 5).clamp(1, 10),
      country: country,
    );
  }

  ContractAnalysisResult copyWith({
    double? salaryBasic,
    double? salaryTotal,
    String? currency,
    int? contractDurationMonths,
    int? noticePeriodDays,
    int? annualLeaveDays,
    List<ContractAllowanceItem>? allowances,
    List<String>? risks,
    List<String>? missingRights,
    List<String>? positivePoints,
    int? overallScore,
    GulfCountry? country,
  }) {
    return ContractAnalysisResult(
      salaryBasic: salaryBasic ?? this.salaryBasic,
      salaryTotal: salaryTotal ?? this.salaryTotal,
      currency: currency ?? this.currency,
      contractDurationMonths:
          contractDurationMonths ?? this.contractDurationMonths,
      noticePeriodDays: noticePeriodDays ?? this.noticePeriodDays,
      annualLeaveDays: annualLeaveDays ?? this.annualLeaveDays,
      allowances: allowances ?? this.allowances,
      risks: risks ?? this.risks,
      missingRights: missingRights ?? this.missingRights,
      positivePoints: positivePoints ?? this.positivePoints,
      overallScore: overallScore ?? this.overallScore,
      country: country ?? this.country,
    );
  }

  String get shareSummary {
    final b = StringBuffer()
      ..writeln('تحليل عقد عمل — ${country.nameAr}')
      ..writeln('التقييم: $overallScore/10')
      ..writeln('الراتب الأساسي: ${salaryBasic ?? '—'}')
      ..writeln('إجمالي الراتب: ${salaryTotal ?? '—'} $currency');
    if (risks.isNotEmpty) {
      b.writeln('\nمخاطر:');
      for (final r in risks) {
        b.writeln('• $r');
      }
    }
    if (missingRights.isNotEmpty) {
      b.writeln('\nحقوق ناقصة:');
      for (final r in missingRights) {
        b.writeln('• $r');
      }
    }
    return b.toString();
  }

  static double parseDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static double? _nullableDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int? _nullableInt(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.round();
    return int.tryParse(v.toString());
  }

  static List<String> _stringList(dynamic v) {
    if (v is! List) return const [];
    return v.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
  }
}
