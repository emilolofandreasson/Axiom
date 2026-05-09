import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../models/question.dart';
import '../../providers/lesson_provider.dart';

class WordOrderPuzzle extends StatefulWidget {
  const WordOrderPuzzle({
    super.key,
    required this.question,
    required this.answerState,
    required this.onAnswer,
  });

  final WordOrderQuestion question;
  final AnswerState answerState;
  final ValueChanged<List<String>> onAnswer;

  @override
  State<WordOrderPuzzle> createState() => _WordOrderPuzzleState();
}

class _WordOrderPuzzleState extends State<WordOrderPuzzle> {
  late List<String?> _bank;   // null = word has been placed
  late List<String?> _slots;  // null = slot is empty

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void didUpdateWidget(WordOrderPuzzle old) {
    super.didUpdateWidget(old);
    if (old.question.id != widget.question.id) _reset();
  }

  void _reset() {
    _bank  = List.of(widget.question.shuffledWords);
    _slots = List.filled(widget.question.shuffledWords.length, null);
  }

  void _placeWord(int bankIndex) {
    if (widget.answerState != AnswerState.unanswered) return;
    final word = _bank[bankIndex];
    if (word == null) return;

    final emptySlot = _slots.indexOf(null);
    if (emptySlot == -1) return;

    HapticFeedback.selectionClick();
    setState(() {
      _slots[emptySlot] = word;
      _bank[bankIndex]  = null;
    });
    _checkIfComplete();
  }

  void _removeSlot(int slotIndex) {
    if (widget.answerState != AnswerState.unanswered) return;
    final word = _slots[slotIndex];
    if (word == null) return;

    // Return word to its original bank position.
    final origIndex = widget.question.shuffledWords.indexOf(word,
        _bank.indexWhere((w) => w == null));

    HapticFeedback.selectionClick();
    setState(() {
      _slots[slotIndex] = null;
      // Find first empty bank slot and restore
      final empty = _bank.indexOf(null);
      if (empty != -1) _bank[empty] = word;
    });
  }

  void _checkIfComplete() {
    if (_slots.any((s) => s == null)) return;
    widget.onAnswer(_slots.whereType<String>().toList());
  }

  @override
  Widget build(BuildContext context) {
    final isAnswered = widget.answerState != AnswerState.unanswered;
    final correct    = widget.question.correctSentence;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.question.prompt,
          style: Theme.of(context).textTheme.displaySmall,
        ).animate().fadeIn(duration: 300.ms),

        const SizedBox(height: FlickSpacing.xl),

        // Answer slots
        _SlotRow(
          slots:      _slots,
          isAnswered: isAnswered,
          correct:    correct,
          onRemove:   _removeSlot,
        ),

        const SizedBox(height: FlickSpacing.lg),

        // Word bank
        Wrap(
          spacing:   FlickSpacing.sm,
          runSpacing: FlickSpacing.sm,
          children: List.generate(_bank.length, (i) {
            final word = _bank[i];
            return _WordChip(
              word:       word,
              onTap:      word != null ? () => _placeWord(i) : null,
              animDelay:  (i * 50).ms,
            );
          }),
        ),

        // Feedback
        if (isAnswered) ...[
          const SizedBox(height: FlickSpacing.lg),
          _FeedbackBanner(
            isCorrect:  widget.answerState == AnswerState.correct,
            correction: correct.join(' '),
          ),
        ],
      ],
    );
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({
    required this.slots,
    required this.isAnswered,
    required this.correct,
    required this.onRemove,
  });

  final List<String?> slots;
  final bool isAnswered;
  final List<String> correct;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing:   FlickSpacing.sm,
      runSpacing: FlickSpacing.sm,
      children: List.generate(slots.length, (i) {
        final word = slots[i];
        Color borderColor = FlickColors.border;
        Color bgColor     = FlickColors.surfaceDim;

        if (isAnswered && word != null) {
          final isCorrectPos = i < correct.length && word == correct[i];
          borderColor = isCorrectPos ? FlickColors.success : FlickColors.error;
          bgColor     = isCorrectPos ? FlickColors.successDim : FlickColors.errorDim;
        }

        return GestureDetector(
          onTap: () => onRemove(i),
          child: AnimatedContainer(
            duration: 200.ms,
            constraints: const BoxConstraints(minWidth: 52, minHeight: 44),
            padding: const EdgeInsets.symmetric(
              horizontal: FlickSpacing.md,
              vertical: FlickSpacing.sm,
            ),
            decoration: BoxDecoration(
              color:        bgColor,
              borderRadius: const BorderRadius.all(FlickRadius.md),
              border:       Border.all(color: borderColor, width: 1.5),
            ),
            alignment: Alignment.center,
            child: word != null
                ? Text(
                    word,
                    style: Theme.of(context).textTheme.labelLarge,
                  )
                : const SizedBox(width: 32),
          ),
        );
      }),
    );
  }
}

class _WordChip extends StatelessWidget {
  const _WordChip({
    required this.word,
    required this.onTap,
    required this.animDelay,
  });

  final String? word;
  final VoidCallback? onTap;
  final Duration animDelay;

  @override
  Widget build(BuildContext context) {
    final isGone = word == null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: 180.ms,
        opacity: isGone ? 0.25 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: FlickSpacing.md,
            vertical: FlickSpacing.sm,
          ),
          decoration: BoxDecoration(
            color:        FlickColors.surface,
            borderRadius: const BorderRadius.all(FlickRadius.md),
            border:       Border.all(
              color: isGone ? FlickColors.border : FlickColors.primary,
              width: 1.5,
            ),
          ),
          child: Text(
            word ?? '   ',
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: FlickColors.primary,
                ),
          ),
        ),
      ),
    )
        .animate(delay: animDelay)
        .fadeIn(duration: 220.ms)
        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.isCorrect, required this.correction});

  final bool isCorrect;
  final String correction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(FlickSpacing.md),
      decoration: BoxDecoration(
        color:        isCorrect ? FlickColors.successDim : FlickColors.errorDim,
        borderRadius: const BorderRadius.all(FlickRadius.lg),
        border:       Border.all(
          color: isCorrect ? FlickColors.success : FlickColors.error,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCorrect ? Icons.check_circle_outline : Icons.info_outline,
            color: isCorrect ? FlickColors.success : FlickColors.error,
          ),
          const SizedBox(width: FlickSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCorrect ? 'Correct!' : 'Not quite',
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: isCorrect ? FlickColors.success : FlickColors.error,
                      ),
                ),
                if (!isCorrect) ...[
                  const SizedBox(height: 2),
                  Text(
                    correction,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: FlickColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.1, end: 0, duration: 300.ms);
  }
}
