import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:netgulf/core/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:netgulf/features/legal_assistant/models/chat_message.dart';

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
  static const String _model = 'claude-haiku-4-5';
  static const String _apiVersion = '2023-06-01';

  static const String systemPrompt = '''
أنت مساعد قانوني متخصص في نظام العمل السعودي والإماراتي.
تجيب على أسئلة الموظفين حول حقوقهم القانونية.
تستند دائماً للمادة القانونية الصحيحة.
تحسب المبالغ المستحقة بدقة.
تكتب بالعربية الفصحى البسيطة.
أضف تنبيهاً مختصراً أن الإجابة استشارة عامة وليست رأياً قانونياً ملزماً عند الحاجة.
''';

  final http.Client _http;

  bool get hasApiKey => AppConstants.anthropicApiKey.isNotEmpty;

  /// الأسئلة المتبقية اليوم.
  Future<int> getRemainingQuestionsToday() async {
    final used = await _questionsUsedToday();
    return (AppConstants.legalAiDailyQuestionLimit - used)
        .clamp(0, AppConstants.legalAiDailyQuestionLimit);
  }

  Future<bool> canAskQuestion() async {
    if (!hasApiKey) return false;
    return await getRemainingQuestionsToday() > 0;
  }

  /// يرسل سؤالاً ويعيد رد المساعد.
  Future<String> ask({
    required String question,
    required List<ChatMessage> history,
  }) async {
    if (!hasApiKey) {
      throw LegalAiException(
        'مفتاح Anthropic غير مضبوط. أضف ANTHROPIC_API_KEY عند التشغيل.',
      );
    }

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

    try {
      final reply = await _callAnthropic(trimmed, history);
      await _recordQuestionUsed();
      return reply;
    } on LegalAiException {
      rethrow;
    } catch (e) {
      throw LegalAiException(
        'تعذر الاتصال بالمساعد. تحقق من الإنترنت وحاول لاحقاً.',
      );
    }
  }

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
      'max_tokens': 1200,
      'system': systemPrompt,
      'messages': messages,
    });

    final response = await _http
        .post(
          Uri.parse(_apiUrl),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': AppConstants.anthropicApiKey,
            'anthropic-version': _apiVersion,
          },
          body: body,
        )
        .timeout(const Duration(seconds: 60));

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
