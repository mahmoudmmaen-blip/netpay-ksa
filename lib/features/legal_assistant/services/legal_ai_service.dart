import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:netgulf/core/constants/api_keys.dart';
import 'package:netgulf/core/constants/app_constants.dart';
import 'package:netgulf/features/legal_assistant/models/chat_message.dart';
import 'package:netgulf/features/legal_assistant/services/legal_ai_placeholder.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// نتيجة سؤال للمساعد القانوني.
class LegalAiReply {
  const LegalAiReply({required this.text, required this.isDemo});

  final String text;
  final bool isDemo;
}

/// استثناءات المساعد القانوني — رسالة عربية واضحة للمستخدم.
class LegalAiException implements Exception {
  LegalAiException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// خدمة Claude — قانون العمل السعودي والإماراتي.
class LegalAiService {
  LegalAiService({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  static const String _anthropicMessagesUrl =
      'https://api.anthropic.com/v1/messages';
  static const String _model = 'claude-3-5-sonnet-20240620';
  static const String _apiVersion = '2023-06-01';
  static const Duration _httpTimeout = Duration(seconds: 60);
  static const int _maxTokens = 1500;

  static const String systemPrompt = '''
أنت "المساعد القانوني لـ NetGulf" — خبير في قانون العمل السعودي والإماراتي.

## شخصيتك
- دقيق ومحترف، ترد بالعربية الفصحى البسيطة
- تفهم العامية: "وهمشوني/همشوني"=فصل، "طردوني"=فصل تعسفي، "شيلوني"=إنهاء خدمة، "عقدي خلص"=انتهاء العقد
- تذكر المواد القانونية عند الإمكان

## السعودية — ملخص
- نهاية الخدمة (84-85): حسب المدة وسبب الإنهاء؛ الوعاء: أساسي + سكن
- GOSI 2026: موظف ~9.75% | صاحب عمل ~11.75% | غير سعودي: 2% مهني على صاحب العمل
- إجازة سنوية: 21/30 يوم | مرضية: 30 كامل + 60 نصف + 30 بدون أجر
- إشعار إنهاء: 60 يوم (غير محدد) | فترة تجربة: 90 يوم

## الإمارات — ملخص
- نهاية خدمة: 21 يوم/سنة (5 سنوات أولى) ثم 30 يوم؛ حد أقصى سنتان أجر
- GPSSA مواطنين: 5% موظف + 12.5% صاحب عمل
- إجازة سنوية: 30 يوم بعد سنة

## طريقة الرد
1. افهم السؤال رغم الأخطاء الإملائية
2. حدد الحق (نعم/لا/يعتمد)
3. اذكر المادة إن أمكن
4. أرقام ومثال حسابي عند الحاجة
5. تنبيه مختصر: استشارة عامة وليست رأياً قانونياً ملزماً

## حدودك
مرشد عام ولست محامياً؛ للقضايا المعقدة راجع محامياً أو الجهة الرسمية.
''';

  final http.Client _http;

  bool get isLiveMode => ApiKeys.canUseLiveAnthropic;

  bool get isWebMockOverride =>
      !isLiveMode && ApiKeys.anthropicBlockedByBrowserCors;

  bool get _viaProxy => ApiKeys.hasAnthropicProxy;

  Future<int> getRemainingQuestionsToday() async {
    final used = await _questionsUsedToday();
    return (AppConstants.legalAiDailyQuestionLimit - used)
        .clamp(0, AppConstants.legalAiDailyQuestionLimit);
  }

  Future<bool> canAskQuestion() async =>
      await getRemainingQuestionsToday() > 0;

  Future<LegalAiReply> ask({
    required String question,
    required List<ChatMessage> history,
  }) async {
    debugPrint('=== LEGAL AI ASK STARTED === Question: $question');
    debugPrint(
      '=== Live: ${ApiKeys.canUseLiveAnthropic} | Proxy: ${ApiKeys.hasAnthropicProxy} | '
      'KeyLen: ${ApiKeys.anthropicApiKey.length}',
    );

    final remaining = await getRemainingQuestionsToday();
    if (remaining <= 0) {
      throw LegalAiException(
        'استنفدت ${AppConstants.legalAiDailyQuestionLimit} أسئلة اليوم. حاول غداً.',
      );
    }

    final trimmed = question.trim();
    if (trimmed.isEmpty) {
      throw LegalAiException('اكتب سؤالك أولاً.');
    }

    if (!isLiveMode) {
      debugPrint('=== LEGAL AI: demo mode (no proxy/key or Web CORS)');
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await _recordQuestionUsed();
      return LegalAiReply(
        text: buildLegalAiPlaceholderReply(trimmed),
        isDemo: true,
      );
    }

    try {
      final reply = await _callAnthropic(trimmed, history)
          .timeout(_httpTimeout);
      await _recordQuestionUsed();
      return LegalAiReply(text: reply, isDemo: false);
    } on TimeoutException {
      debugPrint('=== LEGAL AI TIMEOUT (60s)');
      throw LegalAiException(
        'انتهت مهلة الاتصال (60 ثانية). تحقق من الإنترنت وحاول مرة أخرى.',
      );
    } on LegalAiException {
      rethrow;
    } on http.ClientException catch (e) {
      debugPrint('=== LEGAL AI NETWORK: $e');
      throw LegalAiException(
        'تعذر الاتصال بالخادم. تحقق من الإنترنت أو إعدادات البروكسي.',
      );
    } catch (e, stack) {
      debugPrint('=== LEGAL AI ERROR: $e');
      debugPrint('=== STACK: $stack');
      throw LegalAiException(
        'حدث خطأ غير متوقع. حاول مرة أخرى لاحقاً.',
      );
    }
  }

  Uri get _messagesEndpoint {
    if (_viaProxy) {
      final raw = ApiKeys.anthropicProxyUrl.trim();
      final uri = Uri.parse(raw);
      if (uri.path.isEmpty || uri.path == '/') {
        return uri.replace(path: '/v1/messages');
      }
      if (!uri.path.endsWith('/messages')) {
        return uri.replace(
          path: '${uri.path.replaceAll(RegExp(r'/$'), '')}/v1/messages',
        );
      }
      return uri;
    }
    return Uri.parse(_anthropicMessagesUrl);
  }

  Map<String, String> get _requestHeaders {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'anthropic-version': _apiVersion,
    };
    // البروكسي (Worker) يحتفظ بالمفتاح — التطبيق لا يرسله على Web.
    if (!_viaProxy && ApiKeys.hasAnthropicApiKey) {
      headers['x-api-key'] = ApiKeys.anthropicApiKey;
    }
    return headers;
  }

  Future<String> _callAnthropic(
    String question,
    List<ChatMessage> history,
  ) async {
    final messages = _buildMessagePayload(history, question);
    final body = jsonEncode({
      'model': _model,
      'max_tokens': _maxTokens,
      'system': systemPrompt,
      'messages': messages,
    });

    final endpoint = _messagesEndpoint;
    debugPrint('=== LEGAL AI POST: $endpoint');
    debugPrint('=== LEGAL AI MODEL: $_model | viaProxy: $_viaProxy');

    final response = await _http
        .post(
          endpoint,
          headers: _requestHeaders,
          body: body,
        )
        .timeout(_httpTimeout);

    debugPrint('=== LEGAL AI STATUS: ${response.statusCode}');
    debugPrint(
      '=== LEGAL AI BODY: ${response.body.substring(0, response.body.length.clamp(0, 300))}',
    );

    if (response.statusCode != 200) {
      throw LegalAiException(_messageForHttpStatus(response));
    }

    return _extractAssistantText(response.body);
  }

  List<Map<String, String>> _buildMessagePayload(
    List<ChatMessage> history,
    String question,
  ) {
    final messages = <Map<String, String>>[];
    for (final m in history) {
      if (m.isError) continue;
      messages.add({
        'role': m.isUser ? 'user' : 'assistant',
        'content': m.text,
      });
    }
    messages.add({'role': 'user', 'content': question});
    return messages;
  }

  String _extractAssistantText(String responseBody) {
    try {
      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      final content = data['content'];
      if (content is! List || content.isEmpty) {
        throw LegalAiException('رد فارغ من المساعد.');
      }
      final first = content.first;
      if (first is Map<String, dynamic>) {
        final text = first['text'];
        if (text is String && text.trim().isNotEmpty) {
          return text.trim();
        }
      }
    } catch (e) {
      if (e is LegalAiException) rethrow;
      debugPrint('=== LEGAL AI PARSE ERROR: $e');
    }
    throw LegalAiException('تعذر قراءة رد المساعد. حاول مرة أخرى.');
  }

  String _messageForHttpStatus(http.Response response) {
    final parsed = _tryParseApiErrorMessage(response.body);
    if (parsed != null && parsed.isNotEmpty) return parsed;

    return switch (response.statusCode) {
      401 => 'مفتاح API غير صالح. تحقق من إعدادات البروكسي أو --dart-define.',
      403 => 'رفض الوصول. تحقق من صلاحيات المفتاح أو البروكسي.',
      404 => 'النموذج أو المسار غير موجود (404). تحقق من إعدادات Worker والنموذج.',
      429 => 'تم تجاوز حد الطلبات. انتظر قليلاً ثم حاول مرة أخرى.',
      500 || 502 || 503 || 504 =>
        'الخادم غير متاح مؤقتاً. حاول بعد دقائق.',
      _ => 'خطأ من الخادم (${response.statusCode}). حاول لاحقاً.',
    };
  }

  String? _tryParseApiErrorMessage(String body) {
    try {
      final map = jsonDecode(body) as Map<String, dynamic>;
      final err = map['error'];
      if (err is Map<String, dynamic>) {
        final msg = err['message'];
        if (msg is String && msg.trim().isNotEmpty) return msg.trim();
      }
      final msg = map['message'];
      if (msg is String && msg.trim().isNotEmpty) return msg.trim();
    } catch (_) {
      // ignore
    }
    return null;
  }

  Future<int> _questionsUsedToday() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _todayKey();
      final savedDate =
          prefs.getString(AppConstants.prefLegalAiQuestionsDate) ?? '';
      if (savedDate != today) return 0;
      return prefs.getInt(AppConstants.prefLegalAiQuestionsCount) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _recordQuestionUsed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _todayKey();
      final savedDate =
          prefs.getString(AppConstants.prefLegalAiQuestionsDate) ?? '';
      var count = savedDate == today
          ? (prefs.getInt(AppConstants.prefLegalAiQuestionsCount) ?? 0)
          : 0;
      count += 1;
      await prefs.setString(AppConstants.prefLegalAiQuestionsDate, today);
      await prefs.setInt(AppConstants.prefLegalAiQuestionsCount, count);
    } catch (_) {
      // quota not persisted
    }
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  void dispose() {
    _http.close();
  }
}
