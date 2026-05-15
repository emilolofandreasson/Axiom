import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../providers/review_provider.dart';
import '../widgets/exercises/multiple_choice_card.dart';
import '../providers/lesson_provider.dart' show AnswerState;

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  int _index        = 0;
  int _correct      = 0;
  int _answered     = 0;
  AnswerState _answerState = AnswerState.unanswered;

  void _onAnswer(int selectedIndex, ReviewItem item) {
    if (_answerState != AnswerState.unanswered) return;
    final isCorrect = selectedIndex == item.question.correctIndex;
    setState(() {
      _answerState = isCorrect ? AnswerState.correct : AnswerState.wrong;
      if (isCorrect) _correct++;
      _answered++;
    });

    ref.read(reviewProvider.notifier)
        .markReviewed(item.question.id, correct: isCorrect);

    Future.delayed(1200.ms, () {
      if (!mounted) return;
      final items = ref.read(reviewProvider);
      if (_index + 1 < items.length) {
        setState(() {
          _index++;
          _answerState = AnswerState.unanswered;
        });
      } else {
        _showSummary();
      }
    });
  }

  void _showSummary() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: FlickColors.surface,
        title: Text(
          _correct == _answered ? 'Perfect review!' : 'Review done',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        content: Text(
          '$_correct / $_answered correct.\n'
          '${_correct == _answered ? "All items cleared from your review queue!" : "Keep reviewing — practice makes perfect."}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              // Reset review session state so tab shows fresh next time.
              setState(() {
                _index       = 0;
                _correct     = 0;
                _answered    = 0;
                _answerState = AnswerState.unanswered;
              });
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(reviewProvider);

    if (items.isEmpty) {
      return Scaffold(
        backgroundColor: FlickColors.background,
        appBar: AppBar(title: const Text('Review')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 16),
              Text('No items to review!',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Complete more lessons to build your review queue.',
                style: Theme.of(context).textTheme.bodyMedium!
                    .copyWith(color: FlickColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final safeIndex = _index.clamp(0, items.length - 1);
    final item      = items[safeIndex];

    return Scaffold(
      backgroundColor: FlickColors.background,
      appBar: AppBar(
        title: Text('Review (${safeIndex + 1}/${items.length})'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value:           (safeIndex + 1) / items.length,
            backgroundColor: FlickColors.surfaceDim,
            valueColor:      const AlwaysStoppedAnimation(FlickColors.primary),
            minHeight:       4,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(FlickSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: FlickSpacing.sm + 2,
                  vertical:   FlickSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color:        FlickColors.primaryDim,
                  borderRadius: const BorderRadius.all(FlickRadius.full),
                ),
                child: Text(
                  '🔁 Spaced review',
                  style: Theme.of(context).textTheme.labelSmall!
                      .copyWith(color: FlickColors.primary),
                ),
              ).animate().fadeIn(),
              const SizedBox(height: FlickSpacing.lg),
              Expanded(
                child: MultipleChoiceCard(
                  key:         ValueKey(item.question.id),
                  question:    item.question,
                  answerState: _answerState,
                  onAnswer:    (i) => _onAnswer(i, item),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
