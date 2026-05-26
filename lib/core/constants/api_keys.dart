import 'package:flutter/foundation.dart';

/// مفاتيح API — Web: ثابت للاختبار | Mobile: `--dart-define=ANTHROPIC_API_KEY=...`
abstract final class ApiKeys {
  ApiKeys._();

  /// Web testing only — replace with your real `sk-ant-...` key locally.
  /// ⚠️ Never commit a real production key to git.
  static const String _webAnthropicApiKey =
      'حط_مفتاحك_الحقيقي_هنا_مكان_الكلّام_ده';

  /// `flutter run --dart-define=ANTHROPIC_API_KEY=sk-ant-...` (non-Web)
  static String get anthropicApiKey {
    if (kIsWeb) return _webAnthropicApiKey;
    return const String.fromEnvironment('ANTHROPIC_API_KEY');
  }

  static bool get hasAnthropicApiKey => anthropicApiKey.trim().isNotEmpty;

  /// رسالة للمطوّر/المستخدم عند غياب المفتاح.
  static const String anthropicKeyMissingMessage =
      'المساعد الذكي الكامل غير مفعّل بعد. جرّب الوضع التجريبي أدناه، '
      'أو أضف المفتاح عند التشغيل:\n'
      'flutter run --dart-define=ANTHROPIC_API_KEY=your_key';
}
