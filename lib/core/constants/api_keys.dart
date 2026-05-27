import 'package:flutter/foundation.dart';
import 'package:netgulf/core/constants/api_keys.local.dart';

/// مفاتيح API وإعدادات النقل — Web / Mobile.
abstract final class ApiKeys {
  ApiKeys._();

  /// `flutter run --dart-define=ANTHROPIC_API_KEY=sk-ant-...`
  static String get anthropicApiKey =>
      const String.fromEnvironment('ANTHROPIC_API_KEY', defaultValue: '');

  /// بروكسي Cloudflare Worker (أو محلي) — يتجاوز CORS على Web.
  static String get anthropicProxyUrl {
    const env = String.fromEnvironment('ANTHROPIC_PROXY_URL');
    return env.isNotEmpty ? env : kLocalProxyUrl;
  }

  static bool get hasAnthropicApiKey => anthropicApiKey.trim().isNotEmpty;

  static bool get hasAnthropicProxy => anthropicProxyUrl.trim().isNotEmpty;

  /// Web بدون بروكسي — لا يمكن الاتصال المباشر بـ api.anthropic.com.
  static bool get anthropicBlockedByBrowserCors =>
      kIsWeb && !hasAnthropicProxy;

  /// وضع حي:
  /// - بروكسي مضبوط (Worker) — لا يحتاج مفتاحاً في التطبيق
  /// - أو مفتاح `--dart-define` على Android/iOS/Desktop
  static bool get canUseLiveAnthropic {
    if (hasAnthropicProxy) return true;
    if (!hasAnthropicApiKey) return false;
    return !anthropicBlockedByBrowserCors;
  }

  static const String anthropicKeyMissingMessage =
      'المساعد الذكي غير مفعّل.\n'
      'أضف المفتاح عند التشغيل:\n'
      'flutter run --dart-define=ANTHROPIC_API_KEY=your_key\n\n'
      'أو استخدم بروكسي Worker على Web:\n'
      'flutter run -d chrome '
      '--dart-define=ANTHROPIC_PROXY_URL=https://your-worker.workers.dev';

  static const String anthropicWebCorsMessage =
      'على Chrome/Web يجب استخدام بروكسي Worker (CORS).\n'
      'أضف:\n'
      '--dart-define=ANTHROPIC_PROXY_URL=https://netgulf-proxy.mahmoud-mma-en.workers.dev';
}
