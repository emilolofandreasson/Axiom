import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../models/question.dart';
import '../../providers/lesson_provider.dart';

class MultipleChoiceCard extends StatefulWidget {
  const MultipleChoiceCard({
    super.key,
    required this.question,
    required this.answerState,
    required this.onAnswer,
  });

  final MultipleChoiceQuestion question;
  final AnswerState answerState;
  final ValueChanged<int> onAnswer;

  @override
  State<MultipleChoiceCard> createState() => _MultipleChoiceCardState();
}

class _MultipleChoiceCardState extends State<MultipleChoiceCard> {
  int? _selectedIndex;

  @override
  void didUpdateWidget(MultipleChoiceCard old) {
    super.didUpdateWidget(old);
    // New question arrived — reset local selection.
    if (old.question.id != widget.question.id) {
      _selectedIndex = null;
    }
  }

  void _select(int index) {
    if (widget.answerState != AnswerState.unanswered) return;
    HapticFeedback.lightImpact();
    setState(() => _selectedIndex = index);
    widget.onAnswer(index);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Prompt
        Text(
          widget.question.prompt,
          style: Theme.of(context).textTheme.displaySmall,
        )
            .animate()
            .fadeIn(duration: 300.ms)
            .slideY(begin: 0.08, end: 0, duration: 300.ms),

        const SizedBox(height: FlickSpacing.xl),

        // Options
        ...List.generate(widget.question.options.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: FlickSpacing.sm),
            child: _OptionTile(
              label:        widget.question.options[i],
              index:        i,
              state:        _tileState(i),
              onTap:        () => _select(i),
              animDelay:    (i * 60).ms,
            ),
          );
        }),

        // Hint
        if (widget.question.hintText != null) ...[
          const SizedBox(height: FlickSpacing.md),
          _HintChip(text: widget.question.hintText!),
        ],
      ],
    );
  }

  _TileState _tileState(int i) {
    if (widget.answerState == AnswerState.unanswered) {
      return _selectedIndex == i ? _TileState.selected : _TileState.idle;
    }
    if (i == widget.question.correctIndex) return _TileState.correct;
    if (i == _selectedIndex) return _TileState.wrong;
    return _TileState.idle;
  }
}

enum _TileState { idle, selected, correct, wrong }

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.index,
    required this.state,
    required this.onTap,
    required this.animDelay,
  });

  final String label;
  final int index;
  final _TileState state;
  final VoidCallback onTap;
  final Duration animDelay;

  static const _letters = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg, badgeBg) = switch (state) {
      _TileState.idle     => (FlickColors.surface,     FlickColors.border,
                              FlickColors.textPrimary,  FlickColors.surfaceDim),
      _TileState.selected => (FlickColors.primaryDim,  FlickColors.primary,
                              FlickColors.primary,      FlickColors.primary),
      _TileState.correct  => (FlickColors.successDim,  FlickColors.success,
                              FlickColors.success,      FlickColors.success),
      _TileState.wrong    => (FlickColors.errorDim,    FlickColors.error,
                              FlickColors.error,        FlickColors.error),
    };

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 220.ms,
        padding: const EdgeInsets.symmetric(
          horizontal: FlickSpacing.md,
          vertical: FlickSpacing.md - 2,
        ),
        decoration: BoxDecoration(
          color:        bg,
          borderRadius: const BorderRadius.all(FlickRadius.lg),
          border:       Border.all(color: border, width: 1.5),
        ),
        child: Row(
          children: [
            // Letter badge
            AnimatedContainer(
              duration: 200.ms,
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color:        badgeBg,
                borderRadius: const BorderRadius.all(FlickRadius.sm),
              ),
              alignment: Alignment.center,
              child: Text(
                _letters[index],
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: state == _TileState.idle
                          ? FlickColors.textSecondary
                          : Colors.white,
                      fontSize: 13,
                    ),
              ),
            ),

            const SizedBox(width: FlickSpacing.md),

            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: fg,
                      fontWeight: state != _TileState.idle
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
              ),
            ),

            if (state == _TileState.correct)
              const Icon(Icons.check_rounded, color: FlickColors.success, size: 20),
            if (state == _TileState.wrong)
              const Icon(Icons.close_rounded, color: FlickColors.error, size: 20),
          ],
        ),
      ),
    )
        .animate(delay: animDelay)
        .fadeIn(duration: 250.ms)
        .slideX(begin: 0.04, end: 0, duration: 250.ms);
  }
}

class _HintChip extends StatefulWidget {
  const _HintChip({required this.text});
  final String text;

  @override
  State<_HintChip> createState() => _HintChipState();
}

class _HintChipState extends State<_HintChip> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _revealed = true),
      child: AnimatedContainer(
        duration: 300.ms,
        padding: const EdgeInsets.symmetric(
          horizontal: FlickSpacing.md,
          vertical: FlickSpacing.sm,
        ),
        decoration: BoxDecoration(
          color:        FlickColors.surfaceDim,
          borderRadius: const BorderRadius.all(FlickRadius.full),
          border:       Border.all(color: FlickColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lightbulb_outline_rounded,
                size: 14, color: FlickColors.warning),
            const SizedBox(width: FlickSpacing.xs),
            Text(
              _revealed ? widget.text : 'Show hint',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: _revealed ? FlickColors.textPrimary : FlickColors.textMuted,
                    fontStyle: _revealed ? FontStyle.italic : FontStyle.normal,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
