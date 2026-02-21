import 'package:uuid/uuid.dart';

enum MessageSender { user, ai }

enum AiType { myAi, doctorAi }

class MessageModel {
  final String id;
  final String content;
  final MessageSender sender;
  final DateTime timestamp;
  final bool isLoading;

  MessageModel({
    String? id,
    required this.content,
    required this.sender,
    DateTime? timestamp,
    this.isLoading = false,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  MessageModel copyWith({
    String? id,
    String? content,
    MessageSender? sender,
    DateTime? timestamp,
    bool? isLoading,
  }) {
    return MessageModel(
      id: id ?? this.id,
      content: content ?? this.content,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  factory MessageModel.userMessage(String content) => MessageModel(
        content: content,
        sender: MessageSender.user,
      );

  factory MessageModel.aiMessage(String content, {bool isLoading = false}) =>
      MessageModel(
        content: content,
        sender: MessageSender.ai,
        isLoading: isLoading,
      );

  factory MessageModel.loadingMessage() => MessageModel(
        content: '',
        sender: MessageSender.ai,
        isLoading: true,
      );
}
