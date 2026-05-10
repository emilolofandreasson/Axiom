import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flick_sdk/flick_sdk.dart';
import '../../core/theme/app_theme.dart';
import '../../models/lesson.dart';
import '../../models/question.dart';
import '../../main.dart' show lessonGenerator;

// ---------------------------------------------------------------------------
// AIChatPanel
//
// Phase 1: Simulates a tutor reply with a stub.
// Phase 2: Replace _sendToEdgeAI() with a llama.cpp / Gemini Nano FFI call.
// ---------------------------------------------------------------------------

class AIChatPanel extends StatefulWidget {
  const AIChatPanel({
    super.key,
    required this.question,
    required this.onComplete,
  });

  final SpeakingQuestion question;
  final VoidCallback onComplete;

  @override
  State<AIChatPanel> createState() => _AIChatPanelState();
}

class _AIChatPanelState extends State<AIChatPanel> {
  final _controller  = TextEditingController();
  final _scrollCtrl  = ScrollController();
  final _focusNode   = FocusNode();
  final List<ChatMessage> _messages = [];
  bool _isTyping   = false;
  bool _canFinish  = false;

  void _onControllerChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    _addMessage(ChatMessage(
      id:        '0',
      role:      ChatRole.assistant,
      text:      widget.question.promptText,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    final userMsg = ChatMessage(
      id:        DateTime.now().millisecondsSinceEpoch.toString(),
      role:      ChatRole.user,
      text:      text,
      timestamp: DateTime.now(),
    );
    _addMessage(userMsg);

    EventSensor.instance.emit('chat_message_sent', {
      'lesson_id':   widget.question.lessonId,
      'question_id': widget.question.id,
      'message_len': text.length,
      'turn_number': _messages.length,
    });

    setState(() => _isTyping = true);
    _scrollToBottom();

    final reply = await _sendToAI(
      userInput:           text,
      conversationContext: widget.question.conversationContext,
      history:             _messages,
    );

    if (!mounted) return;
    setState(() => _isTyping = false);

    _addMessage(ChatMessage(
      id:        DateTime.now().millisecondsSinceEpoch.toString(),
      role:      ChatRole.assistant,
      text:      reply,
      timestamp: DateTime.now(),
    ));

    // Allow finishing after at least one exchange.
    if (!_canFinish && _messages.where((m) => m.role == ChatRole.user).length >= 1) {
      setState(() => _canFinish = true);
    }
  }

  void _addMessage(ChatMessage msg) {
    setState(() => _messages.add(msg));
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (!_scrollCtrl.hasClients) return;
    _scrollCtrl.animateTo(
      _scrollCtrl.position.maxScrollExtent + 80,
      duration: 300.ms,
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: const BoxDecoration(
                color:        FlickColors.primaryDim,
                borderRadius: BorderRadius.all(FlickRadius.full),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  size: 18, color: FlickColors.primary),
            ),
            const SizedBox(width: FlickSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Tutor',
                    style: Theme.of(context).textTheme.labelLarge),
                Text('Gemini · AI tutor',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall!
                        .copyWith(color: FlickColors.success)),
              ],
            ),
          ],
        ).animate().fadeIn(duration: 300.ms),

        const SizedBox(height: FlickSpacing.md),

        // Chat area
        Expanded(
          child: ListView.separated(
            controller:  _scrollCtrl,
            padding:     const EdgeInsets.symmetric(vertical: FlickSpacing.sm),
            itemCount:   _messages.length + (_isTyping ? 1 : 0),
            separatorBuilder: (_, __) =>
                const SizedBox(height: FlickSpacing.sm),
            itemBuilder: (context, i) {
              if (i == _messages.length) {
                return const _TypingIndicator();
              }
              return _ChatBubble(message: _messages[i], index: i);
            },
          ),
        ),

        const SizedBox(height: FlickSpacing.sm),

        // Input row
        Row(
          children: [
            Expanded(
              child: TextField(
                controller:   _controller,
                focusNode:    _focusNode,
                textInputAction: TextInputAction.send,
                onSubmitted:  (_) => _send(),
                decoration: const InputDecoration(
                  hintText: 'Write your answer…',
                ),
              ),
            ),
            const SizedBox(width: FlickSpacing.sm),
            _SendButton(onTap: _send),
          ],
        ),

        // "I'm done" button — appears after first exchange
        if (_canFinish) ...[
          const SizedBox(height: FlickSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onComplete,
              icon:  const Icon(Icons.check_rounded, size: 18),
              label: const Text('Done — next question'),
              style: OutlinedButton.styleFrom(
                foregroundColor: FlickColors.success,
                side: const BorderSide(color: FlickColors.success),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(FlickRadius.full),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: FlickSpacing.md,
                ),
              ),
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Gemini-powered tutor reply
// ---------------------------------------------------------------------------
Future<String> _sendToAI({
  required String userInput,
  required String conversationContext,
  required List<ChatMessage> history,
}) async {
  try {
    // Keep only the last 6 messages (3 turns) to bound token usage.
    final recentHistory = history.length > 6 ? history.sublist(history.length - 6) : history;
    final historyText = recentHistory
        .map((m) => '${m.role == ChatRole.assistant ? "Tutor" : "Student"}: ${m.text}')
        .join('\n');

    final prompt =
        'You are a friendly language tutor helping a student practise. '
        'Keep replies to 1–3 short sentences. Be encouraging, gently correct '
        'mistakes, and always end with a follow-up question to keep the student '
        'talking. Use the target language with brief English explanations when '
        'needed.\n\n'
        'Context: $conversationContext\n\n'
        'Conversation so far:\n$historyText\n\n'
        'Student: $userInput\n\n'
        'Tutor:';

    final result = await lessonGenerator.bridge.complete(InferenceRequest(
      prompt:      prompt,
      maxTokens:   200,
      temperature: 0.7,
    ));

    if (result.isSuccess && result.text.isNotEmpty) return result.text.trim();
  } catch (_) {}
  return "Great effort! Keep going — you're doing well. Can you try again?";
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.index});

  final ChatMessage message;
  final int index;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: FlickSpacing.md,
            vertical: FlickSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            color: isUser ? FlickColors.primary : FlickColors.surface,
            borderRadius: BorderRadius.only(
              topLeft:     const Radius.circular(18),
              topRight:    const Radius.circular(18),
              bottomLeft:  isUser
                  ? const Radius.circular(18)
                  : const Radius.circular(4),
              bottomRight: isUser
                  ? const Radius.circular(4)
                  : const Radius.circular(18),
            ),
            border: isUser
                ? null
                : Border.all(color: FlickColors.border),
          ),
          child: Text(
            message.text,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: isUser ? Colors.white : FlickColors.textPrimary,
                  height: 1.5,
                ),
          ),
        ),
      ),
    )
        .animate(delay: (index * 40).ms)
        .fadeIn(duration: 250.ms)
        .slideY(begin: 0.1, end: 0, duration: 250.ms);
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: FlickSpacing.md,
          vertical: FlickSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color:        FlickColors.surface,
          borderRadius: const BorderRadius.all(FlickRadius.lg),
          border:       Border.all(color: FlickColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return Container(
              width: 6, height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: const BoxDecoration(
                color:        FlickColors.textMuted,
                shape:        BoxShape.circle,
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(
                  begin: 0,
                  end: -4,
                  duration: 400.ms,
                  delay: (i * 120).ms,
                  curve: Curves.easeInOut,
                );
          }),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: const BoxDecoration(
          color:        FlickColors.primary,
          borderRadius: BorderRadius.all(FlickRadius.full),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.arrow_upward_rounded,
            color: Colors.white, size: 20),
      ),
    );
  }
}
