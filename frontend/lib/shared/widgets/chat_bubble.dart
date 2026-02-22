import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/models/message_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sehatmand_pakistan/shared/models/ai_type.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;
  final String? userInitials;
  final AiType aiType;

  const ChatBubble({
    super.key,
    required this.message,
    this.userInitials,
    required this.aiType,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _AiAvatar(aiType: aiType),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Bubble
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.55,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.userBubble : AppColors.aiBubble,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: isUser
                          ? const Radius.circular(18)
                          : const Radius.circular(4),
                      bottomRight: isUser
                          ? const Radius.circular(4)
                          : const Radius.circular(18),
                    ),
                    border: isUser
                        ? null
                        : Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: message.isLoading
                      ? _TypingIndicator()
                      : _MessageText(
                          content: message.content,
                          isUser: isUser,
                        ),
                ),

                const SizedBox(height: 4),

                // Timestamp
                if (!message.isLoading)
                  Text(
                    DateFormat('h:mm a').format(message.timestamp),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.greyText,
                    ),
                  ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 10),
            _UserAvatar(initials: userInitials ?? 'U'),
          ],
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.1, end: 0, duration: 300.ms);
  }
}

class _MessageText extends StatelessWidget {
  final String content;
  final bool isUser;

  const _MessageText({required this.content, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Text(
      content,
      style: GoogleFonts.inter(
        fontSize: 14,
        color: AppColors.charcoal,
        height: 1.5,
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      )..repeat(reverse: true),
    );

    _animations = _controllers
        .asMap()
        .entries
        .map((e) => Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(
                parent: e.value,
                curve: Curves.easeInOut,
              ),
            ))
        .toList();

    // Stagger the animations
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 180), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _animations[i],
          builder: (context, child) {
            return Container(
              margin: EdgeInsets.only(
                left: i == 0 ? 0 : 4,
              ),
              width: 8,
              height: 8 + (_animations[i].value * 4),
              decoration: BoxDecoration(
                color: AppColors.primary
                    .withOpacity(0.4 + (_animations[i].value * 0.6)),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}

class _AiAvatar extends StatelessWidget {
  final AiType aiType;

  const _AiAvatar({required this.aiType});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
        ),
      ),
      child: Icon(
        aiType == AiType.myAi ? Icons.psychology : Icons.medical_services,
        color: AppColors.primary,
        size: 18,
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final String initials;

  const _UserAvatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}
