import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:netgulf/core/constants/api_keys.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/features/contract_analysis/models/contract_analysis_result.dart';

/// استدعاء Claude لتحليل عقد PDF.
abstract final class ContractAnalysisService {
  ContractAnalysisService._();

  static const _model = 'claude-sonnet-4-20250514';
  static const _anthropicVersion = '2023-06-01';
  static const _timeout = Duration(seconds: 30);
  static const _directApiUri = 'https://api.anthropic.com/v1/messages';

  /// فقط من `--dart-define=ANTHROPIC_PROXY_URL=...` (بدون fallback محلي).
  static const _anthropicProxyUrlEnv = String.fromEnvironment(
    'ANTHROPIC_PROXY_URL',
    defaultValue: '',
  );

  static String get _proxyUrl => _anthropicProxyUrlEnv.trim();

  /// Web: دائماً عبر Worker (CORS). غير Web: بروكسي إن وُجد وإلا API مباشر.
  static bool get _useProxy => kIsWeb || _proxyUrl.isNotEmpty;

  static const _systemPrompt = '''
أنت محلل عقود عمل خليجي متخصص. حلل عقد العمل المرفق وأخرج النتيجة بـ JSON فقط بهذا الشكل بالضبط:
{
  "salary_basic": number_or_null,
  "salary_total": number_or_null,
  "currency": "SAR|AED|QAR|KWD|BHD|OMR",
  "contract_duration_months": number_or_null,
  "notice_period_days": number_or_null,
  "annual_leave_days": number_or_null,
  "allowances": [{"name": "string", "amount": number}],
  "risks": ["string"],
  "missing_rights": ["string"],
  "positive_points": ["string"],
  "overall_score": 1_to_10
}
لا تكتب أي شيء خارج الـ JSON.
''';

  /// يزيل ```json ... ``` ويستخرج كائن JSON من النص.
  static String _stripMarkdownJsonFences(String raw) {
    var s = raw.trim();
    if (s.startsWith('```')) {
      s = s.replaceFirst(RegExp(r'^```(?:json)?\s*', multiLine: true), '');
      s = s.replaceFirst(RegExp(r'\s*```\s*$', multiLine: true), '');
      s = s.trim();
    }
    final start = s.indexOf('{');
    final end = s.lastIndexOf('}');
    if (start != -1 && end > start) {
      s = s.substring(start, end + 1);
    }
    return s.trim();
  }

  static Future<ContractAnalysisResult> analyze({
    required Uint8List pdfBytes,
    required GulfCountry country,
  }) async {
    if (kIsWeb && _proxyUrl.isEmpty) {
      throw ContractAnalysisException(
        'على Web يجب ضبط بروكسي Worker (CORS).\n'
        'راجع cloudflare_worker/README.md\n'
        'flutter run -d chrome '
        '--dart-define=ANTHROPIC_PROXY_URL=https://xxx.workers.dev',
        code: ContractAnalysisErrorCode.noApiKey,
      );
    }

    final apiKey = ApiKeys.claudeApiKey.trim();
    if (!_useProxy && apiKey.isEmpty) {
      throw ContractAnalysisException(
        'أضف مفتاح Claude API في الإعدادات',
        code: ContractAnalysisErrorCode.noApiKey,
      );
    }

    final base64Pdf = base64Encode(pdfBytes);
    final uri = _useProxy ? Uri.parse(_proxyUrl) : Uri.parse(_directApiUri);

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'anthropic-version': _anthropicVersion,
    };
    // المفتاح على Worker فقط — لا نرسله من Web.
    if (!_useProxy) {
      headers['x-api-key'] = apiKey;
    }

    final body = jsonEncode({
      'model': _model,
      'max_tokens': 2000,
      'system': _systemPrompt,
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
              'text':
                  'حلل عقد العمل وفق قانون العمل في ${country.nameAr}. ${country.eosLawChipAr}',
            },
          ],
        },
      ],
    });

    http.Response response;
    try {
      response = await http
          .post(uri, headers: headers, body: body)
          .timeout(_timeout);
    } on TimeoutException {
      throw ContractAnalysisException(
        'انتهت مهلة التحليل (30 ثانية)',
        code: ContractAnalysisErrorCode.timeout,
      );
    }

    if (response.statusCode != 200) {
      throw ContractAnalysisException(
        'فشل التحليل (${response.statusCode})',
        code: ContractAnalysisErrorCode.api,
      );
    }

    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      // ignore: avoid_print
      print('API Response: ${data.toString()}');

      final content = data['content'] as List<dynamic>?;
      if (content == null || content.isEmpty) {
        throw const FormatException('missing content array');
      }

      final firstBlock = content[0];
      if (firstBlock is! Map<String, dynamic>) {
        throw const FormatException('content[0] is not an object');
      }

      final text = firstBlock['text']?.toString();
      if (text == null || text.trim().isEmpty) {
        throw const FormatException('content[0].text is empty');
      }

      final clean = _stripMarkdownJsonFences(text);
      final parsed = jsonDecode(clean) as Map<String, dynamic>;
      return ContractAnalysisResult.fromJson(parsed, country: country);
    } catch (_) {
      throw ContractAnalysisException(
        'تعذر قراءة نتيجة التحليل',
        code: ContractAnalysisErrorCode.parse,
      );
    }
  }
}

enum ContractAnalysisErrorCode { noApiKey, timeout, api, parse, pdf }

class ContractAnalysisException implements Exception {
  const ContractAnalysisException(this.message, {required this.code});

  final String message;
  final ContractAnalysisErrorCode code;

  @override
  String toString() => message;
}
