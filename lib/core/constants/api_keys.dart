/// مفاتيح API — من متغيرات البيئة عند البناء (لا تُخزَّن في الكود).
abstract final class ApiKeys {
  ApiKeys._();

  /// `flutter run --dart-define=ANTHROPIC_API_KEY=sk-ant-...`
  static const String anthropicApiKey =
      String.fromEnvironment('ANTHROPIC_API_KEY');

  static bool get hasAnthropicApiKey => anthropicApiKey.trim().isNotEmpty;

  /// رسالة للمطوّر/المستخدم عند غياب المفتاح.
  static const String anthropicKeyMissingMessage =
      'المساعد الذكي الكامل غير مفعّل بعد. جرّب الوضع التجريبي أدناه، '
      'أو أضف المفتاح عند التشغيل:\n'
      'flutter run --dart-define=ANTHROPIC_API_KEY=your_key';
}
