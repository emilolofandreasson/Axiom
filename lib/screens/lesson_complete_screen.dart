import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_theme.dart';
import '../models/question.dart';
import '../providers/lesson_provider.dart';

class LessonCompleteScreen extends StatelessWidget {
  const LessonCompleteScreen({
    super.key,
    required this.correctCount,
    required this.totalCount,
    required this.xpEarned,
    required this.onContinue,
    this.wrongAnswers = const [],
  });

  final int correctCount;
  final int totalCount;
  final int xpEarned;
  final VoidCallback onContinue;
  final List<QuestionResult> wrongAnswers;

  double get _accuracy => correctCount / totalCount;

  String get _headline {
    if (_accuracy >= 0.9) return 'Excellent work.';
    if (_accuracy >= 0.7) return 'Good progress.';
    return 'Keep going.';
  }

  String get _subline {
    if (_accuracy >= 0.9) return 'You\'re building real fluency.';
    if (_accuracy >= 0.7) return 'Every lesson sharpens your edge.';
    return 'Mistakes are how languages are learned.';
  }

  void _showReview(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: FlickColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: FlickRadius.xl),
      ),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(FlickSpacing.lg),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: FlickSpacing.lg),
                decoration: BoxDecoration(
                  color: FlickColors.border,
                  borderRadius: const BorderRadius.all(FlickRadius.full),
                ),
              ),
            ),
            Text(
              'Review mistakes',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: FlickColors.textPrimary,
              ),
            ),
            const SizedBox(height: FlickSpacing.md),
            ...wrongAnswers.map((r) => _ReviewCard(result: r)),
          ],
        ),
      ),
    );
  }

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

              // Accuracy ring
              Center(
                child: _AccuracyRing(accuracy: _accuracy),
              ).animate().scale(
                    begin: const Offset(0.7, 0.7),
                    duration: 500.ms,
                    curve: Curves.elasticOut,
                  ),

              const SizedBox(height: FlickSpacing.xxl),

              Text(
                _headline,
                style: Theme.of(context).textTheme.displaySmall,
              ).animate().fadeIn(delay: 200.ms, duration: 350.ms),

              const SizedBox(height: FlickSpacing.sm),

              Text(
                _subline,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: FlickColors.textSecondary,
                    ),
              ).animate().fadeIn(delay: 280.ms, duration: 350.ms),

              const SizedBox(height: FlickSpacing.xl),

              // Stats row
              Row(
                children: [
                  _ResultStat(
                    value: '$correctCount / $totalCount',
                    label: 'Correct',
                    color: FlickColors.success,
                  ),
                  const SizedBox(width: FlickSpacing.md),
                  _ResultStat(
                    value: '+$xpEarned XP',
                    label: 'Earned',
                    color: FlickColors.primary,
                  ),
                  const SizedBox(width: FlickSpacing.md),
                  _ResultStat(
                    value: '${(_accuracy * 100).round()}%',
                    label: 'Accuracy',
                    color: _accuracy >= 0.7
                        ? FlickColors.success
                        : FlickColors.warning,
                  ),
                ],
              ).animate().fadeIn(delay: 360.ms, duration: 350.ms),

              const Spacer(flex: 2),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onContinue,
                  child: const Text('Next lesson'),
                ),
              ).animate().fadeIn(delay: 450.ms),

              const SizedBox(height: FlickSpacing.md),

              if (wrongAnswers.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => _showReview(context),
                    child: const Text(
                      'Review mistakes',
                      style: TextStyle(color: FlickColors.textSecondary),
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: FlickSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.result});
  final QuestionResult result;

  @override
  Widget build(BuildContext context) {
    final (prompt, correct) = switch (result.question) {
      MultipleChoiceQuestion mc => (mc.prompt, mc.correctAnswer),
      WordOrderQuestion wo      => (wo.prompt, wo.correctSentence.join(' ')),
      SpeakingQuestion _        => ('Speaking exercise', '—'),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: FlickSpacing.md),
      padding: const EdgeInsets.all(FlickSpacing.md),
      decoration: BoxDecoration(
        color: FlickColors.errorDim,
        borderRadius: const BorderRadius.all(FlickRadius.lg),
        border: Border.all(color: FlickColors.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            prompt,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: FlickColors.textPrimary,
            ),
          ),
          const SizedBox(height: FlickSpacing.xs),
          Row(
            children: [
              const Icon(Icons.check_rounded, size: 14, color: FlickColors.success),
              const SizedBox(width: FlickSpacing.xs),
              Expanded(
                child: Text(
                  correct,
                  style: const TextStyle(
                    fontSize: 14,
                    color: FlickColors.success,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccuracyRing extends StatelessWidget {
  const _AccuracyRing({required this.accuracy});
  final double accuracy;

  @override
  Widget build(BuildContext context) {
    final color = accuracy >= 0.9
        ? FlickColors.success
        : accuracy >= 0.7
            ? FlickColors.primary
            : FlickColors.warning;

    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: accuracy),
            duration: 700.ms,
            curve: Curves.easeOut,
            builder: (_, value, __) => CircularProgressIndicator(
              value:           value,
              strokeWidth:     8,
              backgroundColor: FlickColors.surfaceDim,
              valueColor:      AlwaysStoppedAnimation(color),
              strokeCap:       StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(accuracy * 100).round()}%',
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                'accuracy',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(color: FlickColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  const _ResultStat({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: FlickSpacing.md,
          horizontal: FlickSpacing.sm,
        ),
        decoration: BoxDecoration(
          color:        FlickColors.surface,
          borderRadius: const BorderRadius.all(FlickRadius.lg),
          border:       Border.all(color: FlickColors.border),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(color: FlickColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
