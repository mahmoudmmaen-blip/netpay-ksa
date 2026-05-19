import 'package:flutter_test/flutter_test.dart';
import 'package:netgulf/core/constants/app_constants.dart';
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
  });
}
