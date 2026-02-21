import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSend;
  final bool isTyping;

  const ChatInput({
    super.key,
    required this.onSend,
    required this.isTyping,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText = false;
  bool _isListening = false; // Voice input state

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isTyping) return;
    widget.onSend(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  void _handleVoiceInput() {
    // TODO: Integrate speech_to_text package
    setState(() => _isListening = !_isListening);
    // Mock: stops listening after 3 seconds
    if (_isListening) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _isListening = false);
          // Simulated voice input
          _controller.text = 'Mujhe sir dard ho raha hai...';
          setState(() => _hasText = true);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.sidebarBorder),
        ),
      ),
      child: Row(
        children: [
          // Voice Button
          _VoiceButton(
            isListening: _isListening,
            onTap: _handleVoiceInput,
          ),
          const SizedBox(width: 12),

          // Text Field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.grey,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _focusNode.hasFocus
                      ? AppColors.primary.withOpacity(0.4)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                onSubmitted: (_) => _handleSend(),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.charcoal,
                ),
                decoration: InputDecoration(
                  hintText:
                      _isListening ? '🎤 Listening...' : AppStrings.typeMessage,
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.greyText,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Send Button
          _SendButton(
            enabled: _hasText && !widget.isTyping,
            onTap: _handleSend,
          ),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _SendButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: enabled ? AppColors.primary : AppColors.greyMid,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.send_rounded,
            color: enabled ? AppColors.white : AppColors.greyText,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _VoiceButton extends StatelessWidget {
  final bool isListening;
  final VoidCallback onTap;

  const _VoiceButton({required this.isListening, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color:
              isListening ? AppColors.coral.withOpacity(0.1) : AppColors.grey,
          shape: BoxShape.circle,
          border:
              isListening ? Border.all(color: AppColors.coral, width: 2) : null,
        ),
        child: Icon(
          isListening ? Icons.mic : Icons.mic_none_outlined,
          color: isListening ? AppColors.coral : AppColors.greyText,
          size: 22,
        ),
      ),
    );
  }
}
