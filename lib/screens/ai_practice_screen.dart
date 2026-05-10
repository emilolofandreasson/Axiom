import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_theme.dart';
import '../models/question.dart';
import '../providers/ai_practice_provider.dart';
import '../providers/language_provider.dart';
import '../providers/lesson_provider.dart' show AnswerState;
import '../widgets/exercises/multiple_choice_card.dart';
import '../widgets/exercises/word_order_puzzle.dart';

// ---------------------------------------------------------------------------
// Topics available for AI practice
// ---------------------------------------------------------------------------

const _kTopics = [
  (name: 'Greetings',   icon: Icons.waving_hand_rounded,     skill: 'vocabulary/greetings'),
  (name: 'Numbers',     icon: Icons.tag_rounded,              skill: 'vocabulary/numbers'),
  (name: 'Food & Drink',icon: Icons.restaurant_rounded,       skill: 'vocabulary/food'),
  (name: 'Family',      icon: Icons.people_rounded,           skill: 'vocabulary/family'),
  (name: 'Daily Life',  icon: Icons.wb_sunny_rounded,         skill: 'vocabulary/daily-life'),
  (name: 'Verbs',       icon: Icons.bolt_rounded,             skill: 'grammar/verb-conjugation'),
  (name: 'Sentences',   icon: Icons.short_text_rounded,       skill: 'grammar/sentence-structure'),
  (name: 'Questions',   icon: Icons.help_outline_rounded,     skill: 'conversation/questions'),
];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class AiPracticeScreen extends ConsumerWidget {
  const AiPracticeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(aiPracticeProvider);
    final notifier = ref.read(aiPracticeProvider.notifier);

    return Scaffold(
      backgroundColor: FlickColors.background,
      appBar: AppBar(
        title: const Text('AI Practice'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            notifier.reset();
            Navigator.pop(context);
          },
        ),
        actions: [
          if (state.status == AiPracticeStatus.inProgress ||
              state.status == AiPracticeStatus.completed)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'New drill',
              onPressed: notifier.reset,
            ),
        ],
      ),
      body: switch (state.status) {
        AiPracticeStatus.idle       => _TopicPicker(notifier: notifier),
        AiPracticeStatus.generating => _GeneratingView(topic: state.topicName),
        AiPracticeStatus.inProgress => _ExerciseView(state: state, notifier: notifier),
        AiPracticeStatus.completed  => _ResultsView(state: state, notifier: notifier),
        AiPracticeStatus.failed     => _FailedView(notifier: notifier),
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Topic picker
// ---------------------------------------------------------------------------

class _TopicPicker extends ConsumerWidget {
  const _TopicPicker({required this.notifier});
  final AiPracticeNotifier notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(FlickSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What do you want to practise?',
              style: Theme.of(context).textTheme.headlineMedium,
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: FlickSpacing.xs),
            Text(
              'AI will generate 4 exercises in ${lang.name} just for you.',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: FlickColors.textSecondary),
            ).animate().fadeIn(delay: 60.ms, duration: 300.ms),
            const SizedBox(height: FlickSpacing.xl),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:    2,
                  mainAxisSpacing:   FlickSpacing.md,
                  crossAxisSpacing:  FlickSpacing.md,
                  childAspectRatio:  1.25,
                ),
                itemCount: _kTopics.length,
                itemBuilder: (context, i) {
                  final topic = _kTopics[i];
                  return _TopicCard(
                    name:  topic.name,
                    icon:  topic.icon,
                    skill: topic.skill,
                    onTap: () => notifier.generate(topic.name, topic.skill),
                  )
                      .animate(delay: (i * 40).ms)
                      .fadeIn(duration: 250.ms)
                      .slideY(begin: 0.1, end: 0, duration: 250.ms);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.name,
    required this.icon,
    required this.skill,
    required this.onTap,
  });

  final String     name;
  final IconData   icon;
  final String     skill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(FlickSpacing.md),
        decoration: BoxDecoration(
          color:        FlickColors.surface,
          borderRadius: const BorderRadius.all(FlickRadius.lg),
          border:       Border.all(color: FlickColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color:        FlickColors.primaryDim,
                borderRadius: const BorderRadius.all(FlickRadius.md),
              ),
              child: Icon(icon, color: FlickColors.primary, size: 22),
            ),
            const SizedBox(height: FlickSpacing.sm),
            Text(
              name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Generating state
// ---------------------------------------------------------------------------

class _GeneratingView extends StatelessWidget {
  const _GeneratingView({this.topic});
  final String? topic;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 48, height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: FlickColors.primary,
            ),
          ),
          const SizedBox(height: FlickSpacing.lg),
          Text(
            'Generating ${topic ?? 'exercises'}…',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: FlickSpacing.xs),
          Text(
            'AI is crafting questions just for you',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: FlickColors.textMuted),
          ),
        ],
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .fadeIn(duration: 600.ms),
    );
  }
}

// ---------------------------------------------------------------------------
// Exercise view
// ---------------------------------------------------------------------------

class _ExerciseView extends StatelessWidget {
  const _ExerciseView({required this.state, required this.notifier});
  final AiPracticeState    state;
  final AiPracticeNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final q        = state.currentQuestion!;
    final answered = state.currentAnswerState != AnswerState.unanswered;
    final correct  = state.currentAnswerState == AnswerState.correct;

    return SafeArea(
      child: Column(
        children: [
          // Progress header
          Padding(
            padding: const EdgeInsets.fromLTRB(
                FlickSpacing.lg, FlickSpacing.md, FlickSpacing.lg, 0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _AiChip(topic: state.topicName ?? ''),
                    Text(
                      '${state.currentIndex + 1} / ${state.totalQuestions}',
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                            color: FlickColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: FlickSpacing.sm),
                TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: 0,
                    end: state.totalQuestions > 0
                        ? state.currentIndex / state.totalQuestions
                        : 0.0,
                  ),
                  duration: 400.ms,
                  curve: Curves.easeOut,
                  builder: (_, v, __) => LinearProgressIndicator(
                    value:           v,
                    backgroundColor: FlickColors.surfaceDim,
                    valueColor:
                        const AlwaysStoppedAnimation(FlickColors.primary),
                    borderRadius: const BorderRadius.all(FlickRadius.full),
                    minHeight:    5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: FlickSpacing.lg),

          // Exercise body
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: FlickSpacing.lg),
              child: switch (q) {
                MultipleChoiceQuestion mc => MultipleChoiceCard(
                    key:         ValueKey(q.id),
                    question:    mc,
                    answerState: state.currentAnswerState,
                    onAnswer:    notifier.submitAnswer,
                  ),
                WordOrderQuestion wo => WordOrderPuzzle(
                    key:         ValueKey(q.id),
                    question:    wo,
                    answerState: state.currentAnswerState,
                    onAnswer:    notifier.submitAnswer,
                  ),
                SpeakingQuestion _ => const SizedBox.shrink(),
              },
            ),
          ),

          // Feedback + continue
          if (answered)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  FlickSpacing.lg, 0, FlickSpacing.lg, FlickSpacing.lg),
              child: Column(
                children: [
                  Container(
                    width:   double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: FlickSpacing.md, vertical: FlickSpacing.sm),
                    decoration: BoxDecoration(
                      color:        correct ? FlickColors.successDim : FlickColors.errorDim,
                      borderRadius: const BorderRadius.all(FlickRadius.md),
                    ),
                    child: Text(
                      correct ? '✓  Correct!' : '✗  Not quite — keep practising.',
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            color: correct ? FlickColors.success : FlickColors.error),
                    ),
                  ),
                  const SizedBox(height: FlickSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: notifier.advance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            correct ? FlickColors.success : FlickColors.primary,
                      ),
                      child: Text(
                          state.isLastQuestion ? 'See results' : 'Continue'),
                    ),
                  ),
                ],
              )
                  .animate()
                  .slideY(begin: 0.3, end: 0, duration: 300.ms, curve: Curves.easeOut)
                  .fadeIn(duration: 200.ms),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Results view
// ---------------------------------------------------------------------------

class _ResultsView extends StatelessWidget {
  const _ResultsView({required this.state, required this.notifier});
  final AiPracticeState    state;
  final AiPracticeNotifier notifier;

  String get _headline {
    if (state.accuracy >= 0.9) return 'Outstanding!';
    if (state.accuracy >= 0.7) return 'Well done!';
    return 'Good effort!';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(FlickSpacing.xl),
        child: Column(
          children: [
            const Spacer(),

            // Score ring
            SizedBox(
              width: 120, height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: state.accuracy),
                    duration: 700.ms,
                    curve: Curves.easeOut,
                    builder: (_, v, __) => CircularProgressIndicator(
                      value:           v,
                      strokeWidth:     8,
                      backgroundColor: FlickColors.surfaceDim,
                      valueColor:      AlwaysStoppedAnimation(
                          state.accuracy >= 0.7
                              ? FlickColors.success
                              : FlickColors.warning),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Text(
                    '${(state.accuracy * 100).round()}%',
                    style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                          fontWeight: FontWeight.w700,
                          color: state.accuracy >= 0.7
                              ? FlickColors.success
                              : FlickColors.warning),
                  ),
                ],
              ),
            ).animate().scale(
                  begin: const Offset(0.6, 0.6),
                  duration: 500.ms,
                  curve: Curves.elasticOut),

            const SizedBox(height: FlickSpacing.xl),

            Text(
              _headline,
              style: Theme.of(context).textTheme.displaySmall,
            ).animate().fadeIn(delay: 200.ms, duration: 350.ms),

            const SizedBox(height: FlickSpacing.xs),

            Text(
              '${state.correctCount} of ${state.totalQuestions} correct'
              '  ·  ${state.topicName}',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: FlickColors.textSecondary),
            ).animate().fadeIn(delay: 300.ms, duration: 350.ms),

            const Spacer(flex: 2),

            // CTA buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => notifier.generate(
                    state.topicName!, state.skillTag!),
                child: const Text('Try again — same topic'),
              ),
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: FlickSpacing.md),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: notifier.reset,
                child: const Text('Pick a new topic'),
              ),
            ).animate().fadeIn(delay: 460.ms),

            const SizedBox(height: FlickSpacing.lg),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Failed view
// ---------------------------------------------------------------------------

class _FailedView extends StatelessWidget {
  const _FailedView({required this.notifier});
  final AiPracticeNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(FlickSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 48, color: FlickColors.textMuted),
            const SizedBox(height: FlickSpacing.lg),
            Text('Couldn\'t generate exercises',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: FlickSpacing.sm),
            Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: FlickColors.textSecondary),
            ),
            const SizedBox(height: FlickSpacing.xl),
            ElevatedButton(
              onPressed: notifier.reset,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _AiChip extends StatelessWidget {
  const _AiChip({required this.topic});
  final String topic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: FlickSpacing.sm + 2, vertical: 3),
      decoration: BoxDecoration(
        color:        FlickColors.primaryDim,
        borderRadius: const BorderRadius.all(FlickRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome_rounded,
              size: 11, color: FlickColors.primary),
          const SizedBox(width: 4),
          Text(
            'AI · $topic',
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: FlickColors.primary, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
