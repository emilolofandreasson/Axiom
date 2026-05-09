import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_theme.dart';
import '../models/lesson.dart';
import '../models/question.dart';
import '../providers/lesson_provider.dart';
import '../widgets/exercises/multiple_choice_card.dart';
import '../widgets/exercises/word_order_puzzle.dart';
import '../widgets/chat/ai_chat_panel.dart';
import 'lesson_complete_screen.dart';

class DailyLessonScreen extends ConsumerWidget {
  const DailyLessonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lessonProvider);
    final notifier = ref.read(lessonProvider.notifier);

    // Route to completion screen when done.
    if (state.status == LessonStatus.completed) {
      return LessonCompleteScreen(
        correctCount:  state.correctCount,
        totalCount:    state.totalQuestions,
        xpEarned:      state.lesson.xpReward,
        onContinue:    () => notifier.startLesson(),
      );
    }

    // Idle = show the lesson intro card.
    if (state.status == LessonStatus.idle) {
      return _LessonIntroScreen(
        lesson: state.lesson,
        onStart: notifier.startLesson,
      );
    }

    return Scaffold(
      backgroundColor: FlickColors.background,
      appBar: _LessonAppBar(
        lessonTitle:  state.lesson.title,
        progress:     state.progressFraction,
        onClose:      () => _confirmExit(context, ref),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: FlickSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: FlickSpacing.md),

              // CEFR + skill badge row
              _LessonMeta(
                cefrLevel: state.currentQuestion.cefrLevel,
                skillTag:  state.currentQuestion.skillTag,
                qIndex:    state.currentIndex,
                qTotal:    state.totalQuestions,
              ),

              const SizedBox(height: FlickSpacing.lg),

              // Exercise body
              Expanded(
                child: _ExerciseBody(
                  key:      ValueKey(state.currentQuestion.id),
                  state:    state,
                  notifier: notifier,
                ),
              ),

              // Continue button — only shown after answering MC/WO.
              _ContinueButton(state: state, notifier: notifier),

              const SizedBox(height: FlickSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmExit(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: FlickColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(FlickRadius.xl),
        ),
        title: const Text('Leave lesson?'),
        content: const Text(
          'Your progress in this lesson will not be saved.',
          style: TextStyle(color: FlickColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: FlickColors.error),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

// ---------------------------------------------------------------------------
// AppBar with inline progress bar
// ---------------------------------------------------------------------------

class _LessonAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _LessonAppBar({
    required this.lessonTitle,
    required this.progress,
    required this.onClose,
  });

  final String lessonTitle;
  final double progress;
  final VoidCallback onClose;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: onClose,
            tooltip: 'Exit lesson',
          ),
          title: Text(lessonTitle),
          actions: [
            // XP streak indicator (non-aggressive — no counter, just a glow)
            Container(
              margin: const EdgeInsets.only(right: FlickSpacing.md),
              padding: const EdgeInsets.symmetric(
                horizontal: FlickSpacing.sm + 2,
                vertical: FlickSpacing.xs,
              ),
              decoration: BoxDecoration(
                color:        FlickColors.primaryDim,
                borderRadius: const BorderRadius.all(FlickRadius.full),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded,
                      size: 14, color: FlickColors.primary),
                  const SizedBox(width: 2),
                  Text('Focus',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall!
                          .copyWith(color: FlickColors.primary)),
                ],
              ),
            ),
          ],
        ),

        // Progress bar
        Padding(
          padding: const EdgeInsets.fromLTRB(
            FlickSpacing.lg, 0, FlickSpacing.lg, FlickSpacing.sm),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: 400.ms,
            curve: Curves.easeOut,
            builder: (_, value, __) => LinearProgressIndicator(
              value:            value,
              backgroundColor:  FlickColors.surfaceDim,
              valueColor:       const AlwaysStoppedAnimation(FlickColors.primary),
              borderRadius:     const BorderRadius.all(FlickRadius.full),
              minHeight:        5,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Meta badge row
// ---------------------------------------------------------------------------

class _LessonMeta extends StatelessWidget {
  const _LessonMeta({
    required this.cefrLevel,
    required this.skillTag,
    required this.qIndex,
    required this.qTotal,
  });

  final String cefrLevel;
  final String skillTag;
  final int qIndex;
  final int qTotal;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Badge(label: cefrLevel, color: FlickColors.primary),
        const SizedBox(width: FlickSpacing.sm),
        _Badge(
          label:  skillTag.split('/').last.replaceAll('-', ' '),
          color:  FlickColors.textSecondary,
        ),
        const Spacer(),
        Text(
          '${qIndex + 1} / $qTotal',
          style: Theme.of(context)
              .textTheme
              .labelSmall!
              .copyWith(color: FlickColors.textMuted),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FlickSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.1),
        borderRadius: const BorderRadius.all(FlickRadius.full),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall!.copyWith(color: color),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Exercise body — dispatches to the right widget based on question type.
// ---------------------------------------------------------------------------

class _ExerciseBody extends ConsumerWidget {
  const _ExerciseBody({
    super.key,
    required this.state,
    required this.notifier,
  });

  final LessonState state;
  final LessonNotifier notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = state.currentQuestion;

    return switch (q) {
      MultipleChoiceQuestion mc => MultipleChoiceCard(
          question:    mc,
          answerState: state.currentAnswerState,
          onAnswer:    notifier.submitAnswer,
        ),
      WordOrderQuestion wo => WordOrderPuzzle(
          question:    wo,
          answerState: state.currentAnswerState,
          onAnswer:    notifier.submitAnswer,
        ),
      SpeakingQuestion sp => AIChatPanel(
          question:   sp,
          onComplete: notifier.advance,
        ),
    };
  }
}

// ---------------------------------------------------------------------------
// Continue / Check button
// ---------------------------------------------------------------------------

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.state, required this.notifier});
  final LessonState state;
  final LessonNotifier notifier;

  @override
  Widget build(BuildContext context) {
    // Speaking questions manage their own advance button.
    if (state.currentQuestion is SpeakingQuestion) return const SizedBox.shrink();

    final answered = state.currentAnswerState != AnswerState.unanswered;
    if (!answered) return const SizedBox.shrink();

    final isCorrect = state.currentAnswerState == AnswerState.correct;

    return AnimatedSlide(
      offset: answered ? Offset.zero : const Offset(0, 0.3),
      duration: 300.ms,
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: answered ? 1.0 : 0.0,
        duration: 200.ms,
        child: Column(
          children: [
            // Inline feedback strip
            Container(
              width:   double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: FlickSpacing.md,
                vertical: FlickSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isCorrect ? FlickColors.successDim : FlickColors.errorDim,
                borderRadius: const BorderRadius.all(FlickRadius.md),
              ),
              child: Text(
                isCorrect ? '✓  Correct!' : '✗  Keep practising — you\'ll get it.',
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: isCorrect ? FlickColors.success : FlickColors.error,
                    ),
              ),
            ),

            const SizedBox(height: FlickSpacing.md),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: notifier.advance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCorrect
                      ? FlickColors.success
                      : FlickColors.primary,
                ),
                child: Text(
                  state.isLastQuestion ? 'Complete lesson' : 'Continue',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lesson intro screen
// ---------------------------------------------------------------------------

class _LessonIntroScreen extends StatelessWidget {
  const _LessonIntroScreen({required this.lesson, required this.onStart});

  final dynamic lesson;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlickColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(FlickSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),

              Text(
                'Today\'s Lesson',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall!
                    .copyWith(color: FlickColors.textMuted, letterSpacing: 1.2),
              ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: FlickSpacing.sm),

              Text(
                lesson.title as String,
                style: Theme.of(context).textTheme.displaySmall,
              )
                  .animate()
                  .fadeIn(delay: 80.ms, duration: 350.ms)
                  .slideY(begin: 0.1),

              const SizedBox(height: FlickSpacing.md),

              Text(
                lesson.description as String,
                style: Theme.of(context).textTheme.bodyLarge,
              )
                  .animate()
                  .fadeIn(delay: 150.ms, duration: 350.ms),

              const SizedBox(height: FlickSpacing.xl),

              // Stats chips
              Row(
                children: [
                  _StatChip(
                    icon:  Icons.timer_outlined,
                    label: '~${lesson.estimatedMinutes} min',
                  ),
                  const SizedBox(width: FlickSpacing.sm),
                  _StatChip(
                    icon:  Icons.bolt_rounded,
                    label: '${lesson.xpReward} XP',
                  ),
                  const SizedBox(width: FlickSpacing.sm),
                  _StatChip(
                    icon:  Icons.quiz_outlined,
                    label: '${(lesson.questions as List).length} exercises',
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms, duration: 350.ms),

              const Spacer(flex: 2),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onStart,
                  child: const Text('Begin'),
                ),
              ).animate().fadeIn(delay: 350.ms, duration: 350.ms),

              const SizedBox(height: FlickSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FlickSpacing.md,
        vertical: FlickSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color:        FlickColors.surfaceDim,
        borderRadius: const BorderRadius.all(FlickRadius.full),
        border:       Border.all(color: FlickColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: FlickColors.textSecondary),
          const SizedBox(width: FlickSpacing.xs),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium!
                .copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
