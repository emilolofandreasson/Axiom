import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flick_sdk/flick_sdk.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
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
    this.cefrLevel    = 'A1',
    this.languageName = 'the target language',
  });

  final SpeakingQuestion question;
  final VoidCallback onComplete;
  final String cefrLevel;
  final String languageName;

  @override
  State<AIChatPanel> createState() => _AIChatPanelState();
}

class _AIChatPanelState extends State<AIChatPanel> {
  final _controller  = TextEditingController();
  final _scrollCtrl  = ScrollController();
  final _focusNode   = FocusNode();
  final List<ChatMessage> _messages = [];
  bool _isTyping     = false;
  bool _canFinish    = false;

  // Speech-to-text
  final _speech      = stt.SpeechToText();
  bool _sttAvailable = false;
  bool _sttListening = false;

  void _onControllerChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    _speech.initialize(onStatus: (s) {
      if (mounted) setState(() => _sttListening = s == 'listening');
    }).then((ok) {
      if (mounted) setState(() => _sttAvailable = ok);
    });
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
    _speech.stop();
    super.dispose();
  }

  Future<void> _toggleStt() async {
    if (_sttListening) {
      await _speech.stop();
      return;
    }
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          _controller.text = result.recognizedWords;
          _controller.selection = TextSelection.collapsed(
              offset: _controller.text.length);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor:  const Duration(seconds: 3),
    );
    setState(() => _sttListening = true);
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
      cefrLevel:           widget.cefrLevel,
      languageName:        widget.languageName,
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
    if (!_canFinish && _messages.any((m) => m.role == ChatRole.user)) {
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
            if (_sttAvailable) ...[
              _MicButton(
                listening: _sttListening,
                onTap:     _toggleStt,
              ),
              const SizedBox(width: FlickSpacing.sm),
            ],
            Expanded(
              child: TextField(
                controller:      _controller,
                focusNode:       _focusNode,
                textInputAction: TextInputAction.send,
                onSubmitted:     (_) => _send(),
                decoration: InputDecoration(
                  hintText: _sttListening ? 'Listening…' : 'Write your answer…',
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
  String cefrLevel = 'A1',
  String languageName = 'the target language',
}) async {
  try {
    // Keep only the last 8 messages (4 turns) to bound token usage.
    final recentHistory = history.length > 8 ? history.sublist(history.length - 8) : history;
    final historyText = recentHistory
        .map((m) => '${m.role == ChatRole.assistant ? "Tutor" : "Student"}: ${m.text}')
        .join('\n');

    final prompt =
        'You are a friendly, encouraging language tutor helping a student practise $languageName '
        'at CEFR level $cefrLevel. '
        'Keep your replies to 1–3 short sentences. '
        'Gently correct grammar mistakes by showing the correct form in brackets. '
        'Always end with a follow-up question in $languageName (with a brief English translation) '
        'to keep the conversation going. '
        'Match your vocabulary and sentence complexity to CEFR $cefrLevel.\n\n'
        'Exercise context: $conversationContext\n\n'
        'Conversation so far:\n$historyText\n\n'
        'Student: $userInput\n\n'
        'Tutor:';

    final result = await lessonGenerator.bridge.complete(InferenceRequest(
      prompt:      prompt,
      maxTokens:   220,
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

class _MicButton extends StatelessWidget {
  const _MicButton({required this.listening, required this.onTap});
  final bool listening;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: listening
              ? FlickColors.error.withValues(alpha: 0.15)
              : FlickColors.surfaceDim,
          borderRadius: const BorderRadius.all(FlickRadius.full),
          border: Border.all(
            color: listening ? FlickColors.error : FlickColors.border,
            width: listening ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          listening ? Icons.mic_rounded : Icons.mic_none_rounded,
          color: listening ? FlickColors.error : FlickColors.textMuted,
          size: 20,
        ),
      ),
    );

    if (!listening) return button;

    // Pulse while listening — repeating scale animation.
    return button
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 1.0, end: 1.08, duration: 600.ms, curve: Curves.easeInOut);
  }
}
