import 'package:flutter_test/flutter_test.dart';
import 'package:netgulf/core/constants/api_keys.dart';
import 'package:netgulf/core/constants/app_constants.dart';
import 'package:netgulf/features/legal_assistant/services/legal_ai_placeholder.dart';
import 'package:netgulf/features/legal_assistant/services/legal_ai_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LegalAiService quota', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('remaining starts at daily limit', () async {
      final service = LegalAiService();
      final remaining = await service.getRemainingQuestionsToday();
      expect(remaining, AppConstants.legalAiDailyQuestionLimit);
    });

    test('isLiveMode matches ApiKeys.canUseLiveAnthropic', () {
      final service = LegalAiService();
      expect(service.isLiveMode, ApiKeys.canUseLiveAnthropic);
    });

    test(
      'demo mode returns placeholder when live mode is off',
      () async {
        final service = LegalAiService();
        expect(service.isLiveMode, isFalse);

        final reply = await service.ask(
          question: 'كم يوم إجازة؟',
          history: const [],
        );

        expect(reply.isDemo, isTrue);
        expect(reply.text, contains('109'));
      },
      skip: ApiKeys.canUseLiveAnthropic
          ? 'Proxy or ANTHROPIC_API_KEY enables live mode'
          : false,
    );

    test('placeholder covers colloquial dismissal keywords', () {
      final reply = buildLegalAiPlaceholderReply('وهمشوني من الشغل');
      expect(reply, contains('فصل'));
    });
  });
}
