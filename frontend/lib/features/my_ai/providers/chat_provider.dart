// lib/features/my_ai/providers/chat_provider.dart
//
// Connects to: POST /api/chat
// Body: { "message": "...", "mode": "user"|"doctor", "session_id": "..." }

import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/api_service.dart';
import '../../../shared/models/chat_models.dart';
import '../../../shared/models/message_model.dart';
import '../../../shared/models/ai_type.dart';

// ── Which AI panel the user is in ───────────────────────

class ChatState {
  final List<MessageModel> messages;
  final bool isTyping;
  final String? error;
  final ChatResponse? lastResponse;

  const ChatState({
    this.messages = const [],
    this.isTyping = false,
    this.error,
    this.lastResponse,
  });

  ChatState copyWith({
    List<MessageModel>? messages,
    bool? isTyping,
    String? error,
    bool clearError = false,
    ChatResponse? lastResponse,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      error: clearError ? null : (error ?? this.error),
      lastResponse: lastResponse ?? this.lastResponse,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final AiType aiType;

  // Backend expects "user" or "doctor" — NOT 1 or 2
  String get _mode => aiType == AiType.myAi ? 'user' : 'doctor';

  // Unique session ID per chat instance — backend uses this for memory
  final String _sessionId = _generateSessionId();

  ChatNotifier({required this.aiType}) : super(const ChatState()) {
    _addWelcomeMessage();
  }

  static String _generateSessionId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rng = Random.secure();
    return List.generate(12, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  void _addWelcomeMessage() {
    final welcome = aiType == AiType.myAi
        ? 'Assalamu Alaikum! 👋 Main aapka SehatMand AI hoon.\n\n'
            'Apni takleef batayein — main symptoms sun kar aapki madad karoonga. '
            'Aap Urdu ya English dono mein likh sakte hain.'
        : 'Assalamu Alaikum, Doctor! 🩺\n\n'
            'Please describe the clinical presentation and I will provide '
            'evidence-based assessment and management guidance.';

    state = state.copyWith(
      messages: [MessageModel.aiMessage(welcome)],
    );
  }

  Future<void> sendMessage(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;

    // 1. Show user message immediately
    state = state.copyWith(
      messages: [...state.messages, MessageModel.userMessage(trimmed)],
      isTyping: true,
      clearError: true,
    );

    try {
      // 2. Call backend
      final responseJson = await ApiService.sendMessage(
        message: trimmed,
        mode: _mode, // "user" or "doctor"
        sessionId: _sessionId, // server manages history via session
      );

      final chatResponse = ChatResponse.fromJson(responseJson);

      // 3. Build display message
      MessageModel aiMsg;

      if (chatResponse.isEmergency) {
        // Emergency — show as a special red card
        aiMsg = MessageModel.aiMessage(
          chatResponse.reply,
          displayType: MessageDisplayType.emergency,
        );
      } else if (chatResponse.hasDoctors) {
        // Has doctor recommendations — build text + attach doctor cards
        final buffer = StringBuffer(chatResponse.reply);
        buffer.write('\n\n**Recommended Doctors in Karachi:**');
        for (int i = 0; i < chatResponse.doctors.length; i++) {
          final doc = chatResponse.doctors[i];
          buffer.write('\n${i + 1}. ${doc.displayLine}');
          if (doc.specialization.isNotEmpty && doc.specialization != 'N/A') {
            buffer.write('\n   🏥 ${_titleCase(doc.specialization)}');
          }
        }

        aiMsg = MessageModel.aiMessage(
          buffer.toString(),
          displayType: MessageDisplayType.doctors,
          doctorCards: chatResponse.doctors
              .map((d) => {
                    'name': d.name,
                    'hospital_name': d.hospitalName,
                    'specialization': d.specialization,
                    'phone': d.phone,
                    'pmdc': d.pmdc,
                    'city': d.city,
                  })
              .toList(),
        );
      } else {
        aiMsg = MessageModel.aiMessage(chatResponse.reply);
      }

      state = state.copyWith(
        messages: [...state.messages, aiMsg],
        isTyping: false,
        lastResponse: chatResponse,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isTyping: false,
        error: 'Backend error: ${e.message}',
      );
    } catch (e) {
      state = state.copyWith(
        isTyping: false,
        error: 'Server se connect nahi ho saka. '
            'Backend chala raha hai? (python app.py)',
      );
    }
  }

  // Clears local state AND tells the server to drop the session memory
  Future<void> clearChat() async {
    await ApiService.clearSession(_sessionId);
    state = const ChatState();
    _addWelcomeMessage();
  }

  void clearError() => state = state.copyWith(clearError: true);

  String _titleCase(String s) => s
      .split(' ')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

// ── One provider per AI panel ─────────────────────────────
final myAiChatProvider = StateNotifierProvider<ChatNotifier, ChatState>(
    (ref) => ChatNotifier(aiType: AiType.myAi));

final doctorAiChatProvider = StateNotifierProvider<ChatNotifier, ChatState>(
    (ref) => ChatNotifier(aiType: AiType.doctorAi));
