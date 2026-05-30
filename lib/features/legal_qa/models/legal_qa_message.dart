enum LegalQaRole { user, assistant }

class LegalQaMessage {
  const LegalQaMessage({
    required this.role,
    required this.text,
    this.isError = false,
  });

  final LegalQaRole role;
  final String text;
  final bool isError;

  LegalQaMessage copyWith({String? text, bool? isError}) {
    return LegalQaMessage(
      role: role,
      text: text ?? this.text,
      isError: isError ?? this.isError,
    );
  }
}
