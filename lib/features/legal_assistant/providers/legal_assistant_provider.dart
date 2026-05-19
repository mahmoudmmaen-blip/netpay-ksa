import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netgulf/features/legal_assistant/services/legal_ai_service.dart';

final legalAiServiceProvider = Provider<LegalAiService>((ref) {
  final service = LegalAiService();
  ref.onDispose(service.dispose);
  return service;
});

final legalAiRemainingProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(legalAiServiceProvider);
  return service.getRemainingQuestionsToday();
});
