import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:netgulf/core/constants/api_keys.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/features/contract_analyzer/domain/contract_analysis_result.dart';

/// تحليل عقد عمل PDF عبر Claude (مباشر أو عبر بروكسي Worker على Web).
abstract final class ContractAnalyzerService {
  ContractAnalyzerService._();

  static const _anthropicVersion = '2023-06-01';
  static const _model = 'claude-sonnet-4-20250514';

  static Future<ContractAnalysisResult> analyze({
    required Uint8List pdfBytes,
    required GulfCountry country,
  }) async {
    if (!ApiKeys.canUseLiveAnthropic) {
      if (ApiKeys.anthropicBlockedByBrowserCors) {
        throw Exception(ApiKeys.anthropicWebCorsMessage);
      }
      throw Exception(ApiKeys.anthropicKeyMissingMessage);
    }

    final base64Pdf = base64Encode(pdfBytes);

    final prompt = '''
أنت خبير قانوني متخصص في قانون العمل في ${country.nameAr}.
قم بتحليل عقد العمل المرفق واستخرج المعلومات التالية بالعربية:

1. البنود المالية: الراتب الأساسي، جميع البدلات، المكافآت، أي مبالغ مالية مذكورة
2. نقاط الضعف: البنود التي قد تضر بالموظف أو غير قانونية وفق ${country.eosLawChipAr}
3. الحقوق الناقصة: الحقوق التي يكفلها القانون لكنها غير مذكورة في العقد
4. الملخص: تقييم عام للعقد (جيد/متوسط/ضعيف) مع السبب

أجب بصيغة JSON فقط بهذا الشكل:
{
  "financial_terms": "...",
  "weak_points": "...",
  "missing_rights": "...",
  "summary": "..."
}
''';

    final uri = ApiKeys.useAnthropicProxy
        ? Uri.parse(ApiKeys.anthropicProxyUrl)
        : Uri.parse('https://api.anthropic.com/v1/messages');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'anthropic-version': _anthropicVersion,
    };
    if (!ApiKeys.useAnthropicProxy && ApiKeys.hasAnthropicApiKey) {
      headers['x-api-key'] = ApiKeys.anthropicApiKey;
    }

    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode({
        'model': _model,
        'max_tokens': 1500,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'document',
                'source': {
                  'type': 'base64',
                  'media_type': 'application/pdf',
                  'data': base64Pdf,
                },
              },
              {
                'type': 'text',
                'text': prompt,
              },
            ],
          },
        ],
      }),
    );

    if (response.statusCode != 200) {
      final snippet = response.body.length > 200
          ? '${response.body.substring(0, 200)}…'
          : response.body;
      throw Exception('فشل التحليل (${response.statusCode}): $snippet');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = data['content'] as List<dynamic>? ?? [];
    final text = content
        .where((b) => (b as Map<String, dynamic>)['type'] == 'text')
        .map((b) => (b as Map<String, dynamic>)['text'] as String)
        .join();

    final clean = text
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    final parsed = jsonDecode(clean) as Map<String, dynamic>;

    return ContractAnalysisResult(
      financialTerms: parsed['financial_terms']?.toString() ?? '',
      weakPoints: parsed['weak_points']?.toString() ?? '',
      missingRights: parsed['missing_rights']?.toString() ?? '',
      summary: parsed['summary']?.toString() ?? '',
      country: country,
    );
  }
}
