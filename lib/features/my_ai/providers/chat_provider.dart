import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/message_model.dart';

class ChatState {
  final List<MessageModel> messages;
  final bool isTyping;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isTyping = false,
    this.error,
  });

  ChatState copyWith({
    List<MessageModel>? messages,
    bool? isTyping,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      error: error,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final AiType aiType;

  ChatNotifier({required this.aiType}) : super(const ChatState()) {
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    final welcome = aiType == AiType.myAi
        ? 'Assalamu Alaikum! Main aapka personal health companion hoon. Batayein, kya takleef hai? Aap Urdu ya English dono mein baat kar sakte hain.'
        : 'Assalamu Alaikum! I\'m Doctor AI. Please describe your symptoms and I\'ll provide appropriate medical guidance. You can type in Urdu or English.';

    state = state.copyWith(
      messages: [MessageModel.aiMessage(welcome)],
    );
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // Add user message
    final userMsg = MessageModel.userMessage(content.trim());
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isTyping: true,
    );

    try {
      // TODO: Call Groq / LLaMA API via Django backend
      await Future.delayed(const Duration(seconds: 2)); // simulate AI response

      final aiResponse = _getMockResponse(content, aiType);
      final aiMsg = MessageModel.aiMessage(aiResponse);

      state = state.copyWith(
        messages: [...state.messages, aiMsg],
        isTyping: false,
      );
    } catch (e) {
      state = state.copyWith(
        isTyping: false,
        error: 'Failed to get response. Please try again.',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearChat() {
    state = const ChatState();
    _addWelcomeMessage();
  }

  // Mock responses — replace with real API calls
  String _getMockResponse(String userMessage, AiType type) {
    final lower = userMessage.toLowerCase();

    if (type == AiType.myAi) {
      if (lower.contains('headache') || lower.contains('sir dard')) {
        return 'Headache ke kai reasons ho sakte hain. Kuch sawal puchna chahta hoon:\n\n1. Aapki neend kaisi hai? Kia raat ko 7-8 ghante so rahe hain?\n2. Pani kitna pee rahe hain?\n3. Koi stress ya tension hai?\n\nIn sab ka jawab dein toh main better suggest kar sakta hoon.';
      }
      if (lower.contains('heart') || lower.contains('dil')) {
        return 'Heart specialist ko "Cardiologist" kehte hain. Karachi mein kuch top cardiologists hain:\n\n• Dr. Tahir Saghir – Aga Khan Hospital\n• Dr. Azhar Iqbal – NICVD Karachi\n• Dr. Syed Nadeem – South City Hospital\n\nAga Khan Hospital ka number: 021-34930051\nNICVD: 021-99201271';
      }
      return 'Shukriya batane ke liye. Main samajhne ki koshish kar raha hoon. Kya aap thoda aur detail mein bata sakte hain? Jaise ye takleef kab se hai aur kitni teez hai?';
    } else {
      // Doctor AI
      if (lower.contains('fever') || lower.contains('bukhar')) {
        return '**Fever (Bukhar) – Guidance:**\n\nCommon causes: Viral infection, Flu, Dehydration\n\n**Medications:**\n• Paracetamol 500mg – 1 tablet every 4-6 hrs (max 4 tabs/day)\n• ORS (Oral Rehydration Solution) – stay hydrated\n\n**Home care:** Rest, fluids, cool compress\n\n⚠️ **See a doctor immediately if:** Fever > 103°F, lasts > 3 days, or with rash/difficulty breathing.';
      }
      if (lower.contains('ulcer') || lower.contains('stomach')) {
        return '**Peptic Ulcer – Guidance:**\n\nSymptoms you might have: Burning stomach pain, nausea, bloating\n\n**Medications (OTC):**\n• Omeprazole 20mg – once daily before breakfast\n• Antacids (Maalox/Gaviscon) for quick relief\n\n**Avoid:** Spicy food, tea/coffee, NSAIDs like Ibuprofen\n\n🩺 **Consult:** Gastroenterologist if no improvement in 2 weeks.';
      }
      return 'Please describe your symptoms in more detail — including since when, severity (1-10), and any other symptoms. This will help me give you accurate guidance.';
    }
  }
}

// Separate providers for each AI type
final myAiChatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(aiType: AiType.myAi);
});

final doctorAiChatProvider =
    StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(aiType: AiType.doctorAi);
});
