import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flick_sdk/flick_sdk.dart';
import '../../core/theme/app_theme.dart';
import '../../models/lesson.dart';
import '../../models/question.dart';

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

  @override
  void initState() {
    super.initState();
    // Seed the conversation with the tutor's opening prompt.
    _addMessage(ChatMessage(
      id:        '0',
      role:      ChatRole.assistant,
      text:      widget.question.promptText,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
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

    // Phase-2 stub: replace with real edge inference.
    final reply = await _sendToEdgeAI(
      userInput: text,
      context:   widget.question.conversationContext,
      history:   _messages,
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
                Text('Edge AI · on-device',
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
                decoration: InputDecoration(
                  hintText:    'Write in Spanish…',
                  suffixIcon:  _controller.text.isNotEmpty
                      ? null
                      : const Icon(Icons.mic_none_rounded,
                            color: FlickColors.textMuted, size: 20),
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
// Stub edge inference — swap for llama.cpp FFI call in Phase 2.
// ---------------------------------------------------------------------------
Future<String> _sendToEdgeAI({
  required String userInput,
  required String context,
  required List<ChatMessage> history,
}) async {
  await Future.delayed(const Duration(milliseconds: 900));

  final lower = userInput.toLowerCase();
  if (lower.contains('no sé') || lower.contains('no se') || lower.contains('?')) {
    return "That's okay! Let's try together. "
        "Can you tell me one thing you do every morning? "
        "Start with \"Yo ___\" — for example: \"Yo tomo café.\"";
  }
  if (lower.contains('yo ')) {
    return "¡Muy bien! That's a great sentence. "
        "Notice the verb form — you've correctly used the first-person present tense. "
        "Can you try to add when you do this? "
        "For example: \"Yo tomo café *por la mañana*.\"";
  }
  return "Nice try! Remember: in Spanish, the subject pronoun (Yo, Tú, Él) "
      "often comes before the verb. Give it another shot — you're almost there!";
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
