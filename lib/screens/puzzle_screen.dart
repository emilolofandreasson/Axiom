import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flick_sdk/flick_sdk.dart';
import '../core/theme/app_theme.dart';
import '../models/puzzle_level.dart';
import '../providers/saga_provider.dart';
import '../widgets/puzzle/match_grid.dart';

class PuzzleScreen extends ConsumerStatefulWidget {
  const PuzzleScreen({super.key, required this.level});

  final PuzzleLevel level;

  @override
  ConsumerState<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends ConsumerState<PuzzleScreen> {
  int  _attempt  = 1;
  bool _complete = false;
  int  _timeSeconds = 0;

  void _onLevelComplete(int timeSeconds) {
    setState(() {
      _complete     = true;
      _timeSeconds  = timeSeconds;
    });

    ref.read(sagaProvider.notifier).completeLevel(
          widget.level.id,
          widget.level.xpReward,
        );

    EventSensor.instance.emit('level_completed', {
      'lesson_id':       widget.level.id,
      'cefr_level':      widget.level.cefrLevel,
      'course_language': widget.level.courseLanguage,
      'attempts':        _attempt,
      'time_seconds':    timeSeconds,
      'xp_earned':       widget.level.xpReward,
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
      _complete = false;
    });
  }

  void _onUseReveal() {
    ref.read(sagaProvider.notifier).useRevealPowerup();
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

    return Scaffold(
      backgroundColor: FlickColors.background,
      appBar: AppBar(
        title: Text(widget.level.title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: FlickSpacing.md),
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
                  onLevelComplete: _onLevelComplete,
                  onRetry:         _onRetry,
                  revealCount:     saga.revealPowerups,
                  onUseReveal:     _onUseReveal,
                ),
              ),

              const SizedBox(height: FlickSpacing.sm),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _onRetry,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: FlickColors.textSecondary,
                    side: const BorderSide(color: FlickColors.border),
                  ),
                  child: const Text('Restart level'),
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

              // Trophy
              Container(
                width: 80, height: 80,
                decoration: const BoxDecoration(
                  color:  FlickColors.primaryDim,
                  shape:  BoxShape.circle,
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

              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatCard(label: 'Time',     value: '${timeSeconds}s'),
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
