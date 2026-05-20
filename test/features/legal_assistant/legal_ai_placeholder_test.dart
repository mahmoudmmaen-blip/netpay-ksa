import 'package:flutter_test/flutter_test.dart';
import 'package:netgulf/features/legal_assistant/services/legal_ai_placeholder.dart';

void main() {
  test('placeholder mentions GOSI for insurance questions', () {
    final text = buildLegalAiPlaceholderReply('ما هو خصم التأمينات GOSI؟');
    expect(text.toLowerCase(), contains('gosi'));
  });

  test('placeholder mentions EOSB for end of service', () {
    final text = buildLegalAiPlaceholderReply('مكافأة نهاية الخدمة');
    expect(text, contains('84'));
  });
}
