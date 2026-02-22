// lib/shared/models/message_model.dart

enum MessageSender { user, ai }

enum MessageDisplayType {
  text,
  emergency,
  doctors,
  loading, // typing indicator
}

class MessageModel {
  final String id;
  final String content;
  final MessageSender sender;
  final DateTime timestamp;
  final MessageDisplayType displayType;
  final List<Map<String, dynamic>> doctorCards;

  const MessageModel({
    required this.id,
    required this.content,
    required this.sender,
    required this.timestamp,
    this.displayType = MessageDisplayType.text,
    this.doctorCards = const [],
  });

  // ── Convenience getters ───────────────────────────────────
  bool get isUser => sender == MessageSender.user;
  bool get isAi => sender == MessageSender.ai;
  bool get isLoading => displayType == MessageDisplayType.loading;

  // ── Factories ─────────────────────────────────────────────
  factory MessageModel.userMessage(String content) => MessageModel(
        id: _uid(),
        content: content,
        sender: MessageSender.user,
        timestamp: DateTime.now(),
      );

  factory MessageModel.aiMessage(
    String content, {
    MessageDisplayType displayType = MessageDisplayType.text,
    List<Map<String, dynamic>> doctorCards = const [],
  }) =>
      MessageModel(
        id: _uid(),
        content: content,
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
        displayType: displayType,
        doctorCards: doctorCards,
      );

  /// Typing indicator bubble — shown while waiting for backend response
  factory MessageModel.loadingMessage() => MessageModel(
        id: _uid(),
        content: '',
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
        displayType: MessageDisplayType.loading,
      );

  static String _uid() => DateTime.now().microsecondsSinceEpoch.toString();
}
