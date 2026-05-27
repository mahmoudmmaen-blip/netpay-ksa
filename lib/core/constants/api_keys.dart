import 'package:flutter/foundation.dart';
import 'package:netgulf/core/constants/api_keys.local.dart';

/// مفاتيح API وإعدادات النقل — Web / Mobile.
abstract final class ApiKeys {
  ApiKeys._();

  /// `flutter run --dart-define=ANTHROPIC_API_KEY=sk-ant-...` (non-Web)
  static String get anthropicApiKey {
    if (kIsWeb) {
      return const String.fromEnvironment(
        'ANTHROPIC_API_KEY',
        defaultValue: '',
      );
    }
    return const String.fromEnvironment('ANTHROPIC_API_KEY');
  }

  /// اختياري — بروكسي محلي يضيف CORS headers ويُمرّر الطلب لـ Anthropic.
  ///
  /// مثال:
  /// `flutter run -d chrome --dart-define=ANTHROPIC_PROXY_URL=http://localhost:8787/v1/messages`
  ///
  /// Anthropic لا يسمح باستدعاءات المتصفح مباشرة؛ البروكسي ضروري للوضع الحي على Web.
  static String get anthropicProxyUrl {
    const env = String.fromEnvironment('ANTHROPIC_PROXY_URL');
    return env.isNotEmpty ? env : kLocalProxyUrl;
  }

  static bool get hasAnthropicApiKey => anthropicApiKey.trim().isNotEmpty;

  static bool get hasAnthropicProxy =>
      anthropicProxyUrl.trim().isNotEmpty;

  /// Web بدون بروكسي — CORS يمنع الاتصال المباشر بـ api.anthropic.com.
  static bool get anthropicBlockedByBrowserCors =>
      kIsWeb && !hasAnthropicProxy;

  /// اتصال حي ممكن:
  /// - عبر البروكسي (Worker) حتى بدون مفتاح محلي
  /// - أو Mobile مباشرة عبر المفتاح (عند عدم توفر بروكسي)
  static bool get canUseLiveAnthropic =>
      (hasAnthropicProxy || hasAnthropicApiKey) && !anthropicBlockedByBrowserCors;

  /// رسالة للمطوّر/المستخدم عند غياب المفتاح.
  static const String anthropicKeyMissingMessage =
      'المساعد الذكي الكامل غير مفعّل بعد. جرّب الوضع التجريبي أدناه، '
      'أو أضف المفتاح عند التشغيل:\n'
      'flutter run --dart-define=ANTHROPIC_API_KEY=your_key';

  /// رسالة Web — CORS / بروكسي.
  static const String anthropicWebCorsMessage =
      'على Chrome/Web لا يمكن استدعاء Anthropic مباشرة من المتصفح (CORS). '
      'يُستخدم الوضع التجريبي تلقائياً.\n\n'
      'للاختبار الحي: شغّل بروكسي محلي ثم:\n'
      'flutter run -d chrome '
      '--dart-define=ANTHROPIC_PROXY_URL=http://localhost:8787/v1/messages';
}
