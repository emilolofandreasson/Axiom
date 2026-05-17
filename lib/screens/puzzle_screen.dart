import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flick_sdk/flick_sdk.dart';
import '../core/theme/app_theme.dart';
import '../models/puzzle_level.dart';
import '../models/language_level.dart';
import '../models/question.dart';
import '../providers/language_provider.dart';
import '../providers/lesson_provider.dart' show AnswerState;
import '../providers/saga_provider.dart';
import '../widgets/puzzle/match_grid.dart';
import '../widgets/exercises/multiple_choice_card.dart';
import '../widgets/exercises/word_order_puzzle.dart';
import '../main.dart' show questionLibrary;

class PuzzleScreen extends ConsumerStatefulWidget {
  const PuzzleScreen({super.key, required this.level});

  final PuzzleLevel level;

  @override
  ConsumerState<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends ConsumerState<PuzzleScreen> {
  int  _attempt     = 1;
  bool _complete    = false;
  int  _timeSeconds = 0;

  // Quiz phase
  bool           _matchComplete   = false;
  List<Question> _quizQuestions   = [];
  int            _quizIndex       = 0;
  AnswerState    _quizAnswerState = AnswerState.unanswered;

  Future<void> _onMatchComplete(int timeSeconds) async {
    setState(() { _timeSeconds = timeSeconds; _matchComplete = true; });

    final questions = await questionLibrary.fetchForLevel(
      languageCode: widget.level.courseLanguage,
      cefrLevel:    widget.level.cefrLevel,
    );

    if (questions.isEmpty) {
      _completeLevel();
      return;
    }
    setState(() {
      _quizQuestions  = questions;
      _quizIndex      = 0;
      _quizAnswerState = AnswerState.unanswered;
    });
  }

  void _completeLevel() {
    setState(() => _complete = true);
    final langCode = ref.read(languageProvider).code;
    final langXp   = ref.read(sagaProvider).xpForLanguage(langCode);
    final xpReward = levelForXp(langXp).xpReward;
    ref.read(sagaProvider.notifier).completeLevel(
      widget.level.id,
      xpReward,
      languageCode: langCode,
    );
    EventSensor.instance.emit('level_completed', {
      'lesson_id':       widget.level.id,
      'cefr_level':      widget.level.cefrLevel,
      'course_language': widget.level.courseLanguage,
      'attempts':        _attempt,
      'time_seconds':    _timeSeconds,
      'xp_earned':       xpReward,
      'quiz_questions':  _quizQuestions.length,
    });
  }

  void _onRetry() {
    EventSensor.instance.emit('level_retried', {
      'lesson_id': widget.level.id,
      'attempt':   _attempt,
    });
    ref.read(sagaProvider.notifier).recordRetry(widget.level.id);
    setState(() {
      _attempt++;
      _complete      = false;
      _matchComplete = false;
      _quizQuestions = [];
      _quizIndex     = 0;
      _quizAnswerState = AnswerState.unanswered;
    });
  }

  void _onUseReveal() {
    ref.read(sagaProvider.notifier).useRevealPowerup();
  }

  void _onQuizAnswer(Object answer) {
    final q = _quizQuestions[_quizIndex];
    final isCorrect = switch (q) {
      MultipleChoiceQuestion mc =>
          answer is int && answer == mc.correctIndex,
      WordOrderQuestion wo =>
          answer is List<String> &&
          _listEquals(answer, wo.correctSentence),
      _ => false,
    };

    setState(() => _quizAnswerState =
        isCorrect ? AnswerState.correct : AnswerState.wrong);

    if (q.globalId != null) {
      questionLibrary.recordAnswer(
        questionId: q.globalId!,
        isCorrect:  isCorrect,
        lessonId:   'path-${widget.level.id}',
      );
    }
  }

  void _onQuizAdvance() {
    if (_quizIndex >= _quizQuestions.length - 1) {
      _completeLevel();
      return;
    }
    setState(() {
      _quizIndex++;
      _quizAnswerState = AnswerState.unanswered;
    });
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final saga = ref.watch(sagaProvider);

    if (_complete) {
      return _CompletionScreen(
        level:       widget.level,
        timeSeconds: _timeSeconds,
        attempts:    _attempt,
        onContinue:  () => Navigator.pop(context),
      );
    }

    if (_matchComplete && _quizQuestions.isNotEmpty) {
      return _QuizPhase(
        level:       widget.level,
        questions:   _quizQuestions,
        index:       _quizIndex,
        answerState: _quizAnswerState,
        onAnswer:    _onQuizAnswer,
        onAdvance:   _onQuizAdvance,
      );
    }

    return Scaffold(
      backgroundColor: FlickColors.background,
      appBar: AppBar(
        title: Text(widget.level.title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: FlickSpacing.sm),
            child: Center(
              child: Text(
                'Level ${widget.level.levelNumber}  ·  ${widget.level.cefrLevel}',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall!
                    .copyWith(color: FlickColors.textMuted),
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'restart') _onRetry();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'restart',
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Restart level'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            FlickSpacing.lg, FlickSpacing.md,
            FlickSpacing.lg, FlickSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Match the pairs',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 2),
              Text(
                'Tap a word, then its translation',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(color: FlickColors.textSecondary),
              ),

              const SizedBox(height: FlickSpacing.md),

              Expanded(
                child: MatchGrid(
                  key:             ValueKey(_attempt),
                  level:           widget.level,
                  onLevelComplete: _onMatchComplete,
                  onRetry:         _onRetry,
                  revealCount:     saga.revealPowerups,
                  onUseReveal:     _onUseReveal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quiz phase
// ---------------------------------------------------------------------------

class _QuizPhase extends StatelessWidget {
  const _QuizPhase({
    required this.level,
    required this.questions,
    required this.index,
    required this.answerState,
    required this.onAnswer,
    required this.onAdvance,
  });

  final PuzzleLevel      level;
  final List<Question>   questions;
  final int              index;
  final AnswerState      answerState;
  final ValueChanged<Object> onAnswer;
  final VoidCallback         onAdvance;

  @override
  Widget build(BuildContext context) {
    final q          = questions[index];
    final isAnswered = answerState != AnswerState.unanswered;
    final total      = questions.length;
    final progress   = (index + (isAnswered ? 1 : 0)) / total;

    return Scaffold(
      backgroundColor: FlickColors.background,
      appBar: AppBar(
        title: Text('Practice — ${index + 1} / $total'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 4,
            child: LinearProgressIndicator(
              value:           progress,
              backgroundColor: FlickColors.surfaceDim,
              color:           FlickColors.primary,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: FlickSpacing.lg,
            vertical:   FlickSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: switch (q) {
                  MultipleChoiceQuestion mc => MultipleChoiceCard(
                      question:    mc,
                      answerState: answerState,
                      onAnswer:    (i) => onAnswer(i),
                    ),
                  WordOrderQuestion wo => WordOrderPuzzle(
                      question:    wo,
                      answerState: answerState,
                      onAnswer:    (words) => onAnswer(words),
                    ),
                  _ => const SizedBox.shrink(),
                },
              ),

              if (isAnswered) ...[
                const SizedBox(height: FlickSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onAdvance,
                    child: Text(
                      index >= questions.length - 1 ? 'Finish' : 'Continue',
                    ),
                  ),
                ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1),
              ],

              const SizedBox(height: FlickSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _formatTime(int seconds) {
  if (seconds < 60) return '${seconds}s';
  final m = seconds ~/ 60;
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

// ---------------------------------------------------------------------------
// Completion screen
// ---------------------------------------------------------------------------

class _CompletionScreen extends StatelessWidget {
  const _CompletionScreen({
    required this.level,
    required this.timeSeconds,
    required this.attempts,
    required this.onContinue,
  });

  final PuzzleLevel level;
  final int timeSeconds;
  final int attempts;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final cleanRun = attempts == 1;

    return Scaffold(
      backgroundColor: FlickColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(FlickSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              Container(
                width: 80, height: 80,
                decoration: const BoxDecoration(
                  color: FlickColors.primaryDim,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events_rounded,
                    size: 40, color: FlickColors.primary),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0, 0),
                    end:   const Offset(1, 1),
                    duration: 400.ms,
                    curve: Curves.elasticOut,
                  ),

              const SizedBox(height: FlickSpacing.xl),

              Text('Level Complete!',
                      style: Theme.of(context).textTheme.displaySmall)
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 350.ms),

              const SizedBox(height: FlickSpacing.sm),

              Text(
                level.title,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge!
                    .copyWith(color: FlickColors.textSecondary),
              ).animate().fadeIn(delay: 300.ms),

              if (cleanRun) ...[
                const SizedBox(height: FlickSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: FlickSpacing.md,
                    vertical: FlickSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: FlickColors.successDim,
                    borderRadius: const BorderRadius.all(FlickRadius.full),
                  ),
                  child: Text(
                    'Perfect run!',
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: FlickColors.success,
                        ),
                  ),
                ).animate().fadeIn(delay: 400.ms),
              ],

              const SizedBox(height: FlickSpacing.xl),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatCard(label: 'Time',     value: _formatTime(timeSeconds)),
                  _StatCard(label: 'Attempts', value: '$attempts'),
                  _StatCard(label: 'XP',       value: '+${level.xpReward}'),
                ],
              ).animate().fadeIn(delay: 450.ms, duration: 400.ms),

              const Spacer(flex: 2),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onContinue,
                  child: const Text('Back to Map'),
                ),
              ).animate().fadeIn(delay: 550.ms),

              const SizedBox(height: FlickSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                color:      FlickColors.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall!
              .copyWith(color: FlickColors.textMuted),
        ),
      ],
    );
  }
}
