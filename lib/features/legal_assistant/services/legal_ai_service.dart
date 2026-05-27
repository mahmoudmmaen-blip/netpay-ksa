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

/// استثناءات المساعد القانوني.
class LegalAiException implements Exception {
  LegalAiException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// خدمة Claude — أسئلة قانونية (السعودية + الإمارات).
class LegalAiService {
  LegalAiService({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const String _model = 'claude-sonnet-4-20250514';
  static const String _apiVersion = '2023-06-01';

  static const String systemPrompt = '''
أنت "المساعد القانوني لـ NetGulf" — خبير متخصص في قانون العمل السعودي والإماراتي.

## شخصيتك
- متخصص قانوني دقيق ومحترف
- تفهم العربية الفصحى والعامية المصرية والخليجية
- تفهم الأخطاء الإملائية والزبرد: "وهمشوني"=فصل، "طردوني"=فصل تعسفي، "شيلوني"=أنهوا خدمته، "عقدي خلص"=انتهى العقد
- ترد بأسلوب منظم مع ذكر المواد القانونية الدقيقة

## قانون العمل السعودي

### نهاية الخدمة (المادة 84 و85)
- أقل من سنتين: لا مكافأة
- 2 إلى أقل من 5 سنوات: ثلث الأجر عن كل سنة (استقالة) / نصف الأجر (فصل)  
- 5 إلى أقل من 10 سنوات: ثلثا الأجر عن كل سنة (استقالة) / الأجر كاملاً (فصل)
- 10 سنوات فأكثر: الأجر كاملاً عن كل سنة (استقالة أو فصل)
- وعاء الحساب: الراتب الأساسي + بدل السكن فقط

### GOSI 2026 (مرحلة انتقالية)
- موظف: 9.75% | صاحب عمل: 11.75%
- 2027: موظف 10% | صاحب عمل 12.25%
- غير سعودي: 2% تأمين مهني على صاحب العمل فقط

### الإجازات (المادة 109)
- سنوية: 21 يوم (أقل من 5 سنوات) / 30 يوم (5 سنوات فأكثر)
- مرضية: 30 يوم أجر كامل + 60 يوم نصف أجر + 30 يوم بدون أجر
- أمومة: 10 أسابيع بأجر كامل

### حقوق أخرى
- إشعار إنهاء العقد: 60 يوم (غير محدد المدة)
- فصل تعسفي: تعويض لا يقل عن أجر شهرين عن كل سنة خدمة
- فترة التجربة: 90 يوم قابلة للتمديد مرة واحدة

## قانون العمل الإماراتي (القانون 33 لسنة 2021)

### نهاية الخدمة
- 21 يوم أجر أساسي عن كل سنة للخمس سنوات الأولى
- 30 يوم عن كل سنة إضافية بعد 5 سنوات
- الحد الأقصى: أجر سنتين كاملتين
- لا فرق بين استقالة وفصل (تعديل 2022)

### GPSSA (للمواطنين)
- موظف: 5% | صاحب عمل: 12.5% | حكومة: 2.5%

### الإجازات
- سنوية: 30 يوم بعد سنة كاملة
- مرضية: 15 يوم أجر كامل + 30 يوم نصف أجر + 45 يوم بدون أجر
- أمومة: 60 يوم
- إشعار الإنهاء: شهر واحد كحد أدنى

## طريقة الرد
1. افهم السؤال حتى لو فيه أخطاء إملائية أو عامية
2. حدد الحق بوضوح (نعم/لا/يعتمد على...)
3. اذكر المادة القانونية المرجعية
4. اشرح الحساب بالأرقام إذا أمكن
5. أضف تنبيهاً مختصراً أن الإجابة استشارة عامة وليست رأياً قانونياً ملزماً

## حدودك
- أنت مرشد قانوني عام، لست محامياً
- لقضايا معقدة انصح بمراجعة محامٍ أو وزارة الموارد البشرية
''';

  final http.Client _http;

  /// اتصال حي — Mobile مباشرة، أو Web عبر بروكسي CORS.
  bool get isLiveMode => ApiKeys.canUseLiveAnthropic;

  /// Web بدون بروكسي — ردود تجريبية بسبب CORS.
  bool get isWebMockOverride => ApiKeys.anthropicBlockedByBrowserCors;

  /// الأسئلة المتبقية اليوم.
  Future<int> getRemainingQuestionsToday() async {
    final used = await _questionsUsedToday();
    return (AppConstants.legalAiDailyQuestionLimit - used)
        .clamp(0, AppConstants.legalAiDailyQuestionLimit);
  }

  Future<bool> canAskQuestion() async =>
      await getRemainingQuestionsToday() > 0;

  /// يرسل سؤالاً — Claude إن وُجد المفتاح، وإلا رد تجريبي.
  Future<LegalAiReply> ask({
    required String question,
    required List<ChatMessage> history,
  }) async {
    final remaining = await getRemainingQuestionsToday();
    if (remaining <= 0) {
      throw LegalAiException(
        'استنفدت ${AppConstants.legalAiDailyQuestionLimit} أسئلة اليوم. '
        'حاول غداً.',
      );
    }

    final trimmed = question.trim();
    if (trimmed.isEmpty) {
      throw LegalAiException('اكتب سؤالك أولاً.');
    }

    if (!isLiveMode) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      await _recordQuestionUsed();
      return LegalAiReply(
        text: _demoReply(trimmed),
        isDemo: true,
      );
    }

    try {
      final reply = await _callAnthropic(trimmed, history);
      await _recordQuestionUsed();
      return LegalAiReply(text: reply, isDemo: false);
    } on LegalAiException {
      rethrow;
    } on http.ClientException catch (e) {
      if (kIsWeb) {
        await _recordQuestionUsed();
        return LegalAiReply(
          text: _webCorsFallbackReply(trimmed, detail: e.message),
          isDemo: true,
        );
      }
      throw LegalAiException(
        'تعذر الاتصال بالمساعد. تحقق من الإنترنت وحاول لاحقاً.',
      );
    } catch (_) {
      if (kIsWeb) {
        await _recordQuestionUsed();
        return LegalAiReply(
          text: _webCorsFallbackReply(trimmed),
          isDemo: true,
        );
      }
      throw LegalAiException(
        'تعذر الاتصال بالمساعد. تحقق من الإنترنت وحاول لاحقاً.',
      );
    }
  }

  /// رد تجريبي — البanner في الشاشة يشرح CORS على Web.
  String _demoReply(String question) => buildLegalAiPlaceholderReply(question);

  String _webCorsFallbackReply(String question, {String? detail}) {
    final body = buildLegalAiPlaceholderReply(question);
    final extra = detail != null && detail.isNotEmpty
        ? '\n(تفاصيل: $detail)'
        : '';
    return 'تعذر الاتصال بـ Anthropic من المتصفح — CORS.$extra\n\n'
        '${ApiKeys.anthropicWebCorsMessage}\n\n---\n\n$body';
  }

  Uri get _messagesEndpoint {
    if (kIsWeb && ApiKeys.hasAnthropicProxy) {
      return Uri.parse(ApiKeys.anthropicProxyUrl.trim());
    }
    return Uri.parse(_apiUrl);
  }

  Map<String, String> get _requestHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (ApiKeys.hasAnthropicApiKey) 'x-api-key': ApiKeys.anthropicApiKey,
        'anthropic-version': _apiVersion,
        // لا يُحل CORS — Anthropic لا يسمح بـ browser origin؛ البروكسي فقط.
        if (kIsWeb) 'X-Requested-With': 'XMLHttpRequest',
      };

  Future<String> _callAnthropic(
    String question,
    List<ChatMessage> history,
  ) async {
    final messages = <Map<String, String>>[];

    for (final m in history) {
      if (m.isError) continue;
      messages.add({
        'role': m.isUser ? 'user' : 'assistant',
        'content': m.text,
      });
    }
    messages.add({'role': 'user', 'content': question});

    final body = jsonEncode({
      'model': _model,
      'max_tokens': 1500,
      'system': systemPrompt,
      'messages': messages,
    });

    final response = await _http
        .post(
          _messagesEndpoint,
          headers: _requestHeaders,
          body: body,
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      final err = _parseError(response.body);
      throw LegalAiException(err);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
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

    throw LegalAiException('تعذر قراءة رد المساعد.');
  }

  String _parseError(String body) {
    try {
      final map = jsonDecode(body) as Map<String, dynamic>;
      final err = map['error'];
      if (err is Map<String, dynamic>) {
        final msg = err['message'];
        if (msg is String && msg.isNotEmpty) return msg;
      }
    } catch (_) {
      // ignore
    }
    return 'خطأ من الخادم (${body.length > 120 ? '${body.substring(0, 120)}...' : body})';
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
