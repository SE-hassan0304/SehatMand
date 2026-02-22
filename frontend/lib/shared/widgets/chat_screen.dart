import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/my_ai/providers/chat_provider.dart';
import '../../shared/models/message_model.dart';
import 'chat_bubble.dart';
import 'chat_input.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sehatmand_pakistan/shared/models/ai_type.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final AiType aiType;

  const ChatScreen({super.key, required this.aiType});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider =
        widget.aiType == AiType.myAi ? myAiChatProvider : doctorAiChatProvider;

    final chatState = ref.watch(provider);
    final user = ref.watch(currentUserProvider);

    // Auto scroll when new messages arrive
    ref.listen(provider, (prev, next) {
      if (prev?.messages.length != next.messages.length || next.isTyping) {
        _scrollToBottom();
      }
    });

    return Column(
      children: [
        // Chat header with greeting
        _ChatHeader(
            aiType: widget.aiType, userName: user?.firstName ?? 'there'),

        // Messages list
        Expanded(
          child: chatState.messages.isEmpty
              ? _EmptyState(aiType: widget.aiType)
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount:
                      chatState.messages.length + (chatState.isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Typing indicator
                    if (chatState.isTyping &&
                        index == chatState.messages.length) {
                      return ChatBubble(
                        message: MessageModel.loadingMessage(),
                        userInitials: user?.initials,
                        aiType: widget.aiType,
                      );
                    }

                    final message = chatState.messages[index];
                    return ChatBubble(
                      message: message,
                      userInitials: user?.initials,
                      aiType: widget.aiType,
                    );
                  },
                ),
        ),

        // Typing indicator text
        if (chatState.isTyping) _TypingStatusBar(aiType: widget.aiType),

        // Input area
        ChatInput(
          isTyping: chatState.isTyping,
          onSend: (msg) => ref.read(provider.notifier).sendMessage(msg),
        ),
      ],
    );
  }
}

class _ChatHeader extends StatelessWidget {
  final AiType aiType;
  final String userName;

  const _ChatHeader({required this.aiType, required this.userName});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    final timeOfDay = hour < 12
        ? 'morning'
        : hour < 17
            ? 'afternoon'
            : 'evening';

    if (aiType == AiType.myAi) {
      return 'Good $timeOfDay, $userName!\nHow are you feeling today?';
    } else {
      return 'Good $timeOfDay, $userName!\nDescribe your symptoms and I\'ll help.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primarySurface,
            AppColors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.sidebarBorder),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              aiType == AiType.myAi ? Icons.psychology : Icons.medical_services,
              color: AppColors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aiType == AiType.myAi ? 'My AI' : 'Doctor AI',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
                Text(
                  _getGreeting(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.greyText,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          // Online badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.success.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'Online',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _TypingStatusBar extends StatelessWidget {
  final AiType aiType;

  const _TypingStatusBar({required this.aiType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          const SizedBox(width: 46), // align with chat bubbles
          Text(
            aiType == AiType.myAi
                ? 'My AI is typing...'
                : 'Doctor AI is typing...',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.primary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AiType aiType;

  const _EmptyState({required this.aiType});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            aiType == AiType.myAi
                ? Icons.psychology_outlined
                : Icons.medical_services_outlined,
            size: 64,
            color: AppColors.primaryLight,
          ),
          const SizedBox(height: 16),
          Text(
            'Start the conversation',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.greyText,
            ),
          ),
        ],
      ),
    );
  }
}
