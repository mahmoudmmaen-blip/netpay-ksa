import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:netgulf/core/constants/api_keys.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/features/legal_qa/models/legal_qa_message.dart';

/// استشارة قانونية عبر Claude (نص فقط).
abstract final class LegalQaService {
  LegalQaService._();

  static const _model = 'claude-sonnet-4-5';
  static const _anthropicVersion = '2023-06-01';
  static const _timeout = Duration(seconds: 90);
  static const _directApiUri = 'https://api.anthropic.com/v1/messages';
  static const _maxHistoryMessages = 6;

  static const _anthropicProxyUrlEnv = String.fromEnvironment(
    'ANTHROPIC_PROXY_URL',
    defaultValue: '',
  );

  static String get _proxyUrl => _anthropicProxyUrlEnv.trim();
  static bool get _useProxy => kIsWeb || _proxyUrl.isNotEmpty;

  static String _referenceLaborLawAr(GulfCountry country) => switch (country) {
        GulfCountry.saudiArabia => 'نظام العمل السعودي',
        GulfCountry.uae => 'قانون العمل الإماراتي',
        GulfCountry.qatar => 'قانون العمل القطري',
        GulfCountry.kuwait => 'قانون العمل الكويتي',
        GulfCountry.bahrain => 'قانون العمل البحريني',
        GulfCountry.oman => 'قانون العمل العُماني',
      };

  static String _systemPrompt(GulfCountry country) {
    final law = _referenceLaborLawAr(country);
    return '''
أنت مستشار قانوني متخصص في قانون العمل الخليجي.
الدولة المحددة: ${country.nameAr}
القانون المرجعي: $law

أجب بشكل واضح ومبسط باللغة العربية.
اذكر رقم المادة القانونية عند الإجابة.
إذا كان السؤال خارج نطاق قانون العمل، أخبر المستخدم بذلك بلطف.
لا تتجاوز 200 كلمة في الإجابة.
''';
  }

  static Future<String> ask({
    required GulfCountry country,
    required List<LegalQaMessage> history,
    required String question,
  }) async {
    if (kIsWeb && _proxyUrl.isEmpty) {
      throw LegalQaException(
        'على Web يجب ضبط بروكسي Worker (CORS).\n'
        'flutter run --dart-define=ANTHROPIC_PROXY_URL=https://xxx.workers.dev',
      );
    }

    final apiKey = ApiKeys.claudeApiKey.trim();
    if (!_useProxy && apiKey.isEmpty) {
      throw LegalQaException('أضف مفتاح Claude API في الإعدادات');
    }

    final uri = _useProxy ? Uri.parse(_proxyUrl) : Uri.parse(_directApiUri);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'anthropic-version': _anthropicVersion,
    };
    if (!_useProxy) {
      headers['x-api-key'] = apiKey;
    }

    final recent = history
        .where((m) => !m.isError)
        .toList()
        .reversed
        .take(_maxHistoryMessages)
        .toList()
        .reversed;

    final apiMessages = <Map<String, dynamic>>[
      for (final m in recent)
        {
          'role': m.role == LegalQaRole.user ? 'user' : 'assistant',
          'content': m.text,
        },
      {'role': 'user', 'content': question.trim()},
    ];

    final body = jsonEncode({
      'model': _model,
      'max_tokens': 500,
      'system': _systemPrompt(country),
      'messages': apiMessages,
    });

    final client = http.Client();
    http.Response response;
    try {
      response = await client
          .post(uri, headers: headers, body: body)
          .timeout(_timeout);
    } on TimeoutException {
      throw LegalQaException('انتهت مهلة الاستجابة');
    } finally {
      client.close();
    }

    if (response.statusCode != 200) {
      throw LegalQaException('فشل الاتصال (${response.statusCode})');
    }

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['error'] != null) {
        final err = decoded['error'] as Map<String, dynamic>;
        throw LegalQaException('${err['message']}');
      }
      final contentList = decoded['content'] as List;
      final textContent = contentList.firstWhere(
        (item) => (item as Map)['type'] == 'text',
        orElse: () => throw LegalQaException('لا يوجد نص في الرد'),
      );
      return ((textContent as Map)['text'] as String).trim();
    } catch (e) {
      if (e is LegalQaException) rethrow;
      throw LegalQaException('تعذر قراءة الرد: $e');
    }
  }
}

class LegalQaException implements Exception {
  const LegalQaException(this.message);
  final String message;
  @override
  String toString() => message;
}
