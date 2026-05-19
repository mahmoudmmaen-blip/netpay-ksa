/// رسالة في محادثة المساعد القانوني.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });

  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    bool? isError,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isError: isError ?? this.isError,
    );
  }
}
