import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/core/providers/gulf_country_provider.dart';
import 'package:netgulf/features/legal_qa/models/legal_qa_message.dart';
import 'package:netgulf/features/legal_qa/services/legal_qa_service.dart';

class LegalQaState {
  const LegalQaState({
    this.country = GulfCountry.saudiArabia,
    this.messages = const [],
    this.isTyping = false,
    this.error,
  });

  final GulfCountry country;
  final List<LegalQaMessage> messages;
  final bool isTyping;
  final String? error;

  LegalQaState copyWith({
    GulfCountry? country,
    List<LegalQaMessage>? messages,
    bool? isTyping,
    String? error,
    bool clearError = false,
  }) {
    return LegalQaState(
      country: country ?? this.country,
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class LegalQaNotifier extends StateNotifier<LegalQaState> {
  LegalQaNotifier(this._ref) : super(const LegalQaState()) {
    final home = _ref.read(gulfCountryProvider);
    state = state.copyWith(country: home);
  }

  final Ref _ref;

  void setCountry(GulfCountry country) {
    state = state.copyWith(country: country, clearError: true);
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isTyping) return;

    final userMsg = LegalQaMessage(role: LegalQaRole.user, text: trimmed);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isTyping: true,
      clearError: true,
    );

    try {
      final reply = await LegalQaService.ask(
        country: state.country,
        history: state.messages.where((m) => m != userMsg).toList(),
        question: trimmed,
      );
      final assistantMsg =
          LegalQaMessage(role: LegalQaRole.assistant, text: reply);
      state = state.copyWith(
        messages: [...state.messages, assistantMsg],
        isTyping: false,
      );
    } on LegalQaException catch (e) {
      state = state.copyWith(
        messages: [
          ...state.messages,
          LegalQaMessage(
            role: LegalQaRole.assistant,
            text: e.message,
            isError: true,
          ),
        ],
        isTyping: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        messages: [
          ...state.messages,
          LegalQaMessage(
            role: LegalQaRole.assistant,
            text: 'حدث خطأ غير متوقع. حاول مرة أخرى.',
            isError: true,
          ),
        ],
        isTyping: false,
        error: e.toString(),
      );
    }
  }

  void clearChat() {
    state = LegalQaState(country: state.country);
  }
}

final legalQaProvider =
    StateNotifierProvider<LegalQaNotifier, LegalQaState>((ref) {
  return LegalQaNotifier(ref);
});
