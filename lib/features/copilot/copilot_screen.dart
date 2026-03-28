import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/backend_api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';

class CopilotScreen extends StatefulWidget {
  const CopilotScreen({super.key});

  @override
  State<CopilotScreen> createState() => _CopilotScreenState();
}

class _CopilotScreenState extends State<CopilotScreen> {
  final _api = BackendApiService();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      isUser: false,
      text: 'Welcome to Velocity Copilot.',
    ),
    const _ChatMessage(
      isUser: false,
      text:
          'Ask about a destination, nearby routes, ETAs, or faster transit options and I will analyze the available backend data for you.',
    ),
  ];
  final TextEditingController _controller = TextEditingController();
  bool _isSending = false;

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.add(_ChatMessage(isUser: true, text: text));
      _controller.clear();
      _isSending = true;
    });

    try {
      final answer = await _api.askCopilot(
        question: text,
        history: _messages
            .map(
              (message) => {
                'role': message.isUser ? 'user' : 'assistant',
                'text': message.text,
              },
            )
            .toList(),
      );

      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(isUser: false, text: answer));
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMessage(
            isUser: false,
            text: _readableError(error),
            isError: true,
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  String _readableError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    if (message.contains('Authentication token missing')) {
      return 'Please sign in again before using Copilot.';
    }
    if (message.contains('Gemini API key is missing')) {
      return 'Copilot is not configured on the backend yet.';
    }
    if (message.contains('503') || message.contains('500')) {
      return 'Copilot is temporarily unavailable. Please try again in a moment.';
    }
    return message.isEmpty ? 'Copilot could not answer right now.' : message;
  }

  Widget _buildTypingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(6),
            bottomRight: Radius.circular(18),
          ),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textSecondary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Analyzing transit data...',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildPromptStrip(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                itemCount: _messages.length + (_isSending ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isSending && index == _messages.length) {
                    return _buildTypingBubble()
                        .animate()
                        .fadeIn(duration: 220.ms);
                  }

                  final msg = _messages[index];
                  return Align(
                    alignment: msg.isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child:
                        _buildMessageBubble(
                              text: msg.text,
                              isUser: msg.isUser,
                              isError: msg.isError,
                            )
                            .animate()
                            .fadeIn(duration: 320.ms)
                            .slideY(begin: 0.06, end: 0),
                  );
                },
              ),
            ),
            _buildComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 50,
            height: 50,
            decoration: ShapeDecoration(
              color: const Color(0xFFD8E0F3),
              shape: AppShapes.star,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF213A63),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Velocity Copilot',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Transit guidance with nearby route context',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptStrip() {
    final prompts = [
      'Nearest fast route',
      'Compare two buses',
      'Best stop to walk to',
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final prompt = prompts[index];
          return GestureDetector(
            onTap: () => _controller.text = prompt,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                prompt,
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemCount: prompts.length,
      ),
    );
  }

  Widget _buildMessageBubble({
    required String text,
    required bool isUser,
    bool isError = false,
  }) {
    final bubbleColor = isUser
        ? const Color(0xFFE8EEF9)
        : isError
            ? AppColors.error.withValues(alpha: 0.08)
            : AppColors.backgroundCard;
    final borderColor = isUser
        ? const Color(0xFFC9D5EB)
        : isError
            ? AppColors.error.withValues(alpha: 0.22)
            : AppColors.border;
    final textColor = isError ? AppColors.error : AppColors.textPrimary;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.78,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isUser ? 18 : 6),
          bottomRight: Radius.circular(isUser ? 6 : 18),
        ),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: GoogleFonts.spaceGrotesk(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isUser ? 'You' : 'Copilot',
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.backgroundSheet,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                enabled: !_isSending,
                onSubmitted: (_) => _sendMessage(),
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Ask about routes, ETAs, or nearby stops',
                  hintStyle: GoogleFonts.spaceGrotesk(
                    color: AppColors.textTertiary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isSending ? null : _sendMessage,
            child: Container(
              width: 52,
              height: 52,
              decoration: ShapeDecoration(
                color: const Color(0xFFD8E0F3),
                shape: AppShapes.hex,
              ),
              child: const Icon(
                Icons.arrow_upward_rounded,
                color: Color(0xFF213A63),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.isUser,
    required this.text,
    this.isError = false,
  });

  final bool isUser;
  final String text;
  final bool isError;
}
