import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_theme.dart';
import '../models/language.dart';
import '../providers/language_provider.dart';
import '../providers/lesson_provider.dart';
import '../providers/saga_provider.dart';
import 'daily_lesson_screen.dart';
import 'language_picker_screen.dart';
import 'saga_map_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language   = ref.watch(languageProvider);
    final lessonState = ref.watch(lessonProvider);
    final sagaState  = ref.watch(sagaProvider);

    return Scaffold(
      backgroundColor: FlickColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: FlickSpacing.lg,
            vertical: FlickSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting + language chip
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'Good morning.',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                  ),
                  _LanguageChip(language: language),
                ],
              ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: FlickSpacing.md),

              // Stats row
              Row(
                children: [
                  _StatPill(icon: '🔥', label: '${sagaState.streakCount} day streak'),
                  const SizedBox(width: FlickSpacing.sm),
                  _StatPill(icon: '⚡', label: '${sagaState.totalXp} XP'),
                ],
              ).animate().fadeIn(delay: 80.ms, duration: 300.ms),

              const SizedBox(height: FlickSpacing.xl),

              // Daily lesson card
              _DailyLessonCard(
                language:   language,
                lessonState: lessonState,
              ).animate().fadeIn(delay: 160.ms, duration: 300.ms),

              const SizedBox(height: FlickSpacing.md),

              // Puzzle path card
              _PuzzlePathCard()
                  .animate()
                  .fadeIn(delay: 240.ms, duration: 300.ms),

              const SizedBox(height: FlickSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageChip extends ConsumerWidget {
  const _LanguageChip({required this.language});
  final Language language;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LanguagePickerScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: FlickSpacing.md,
          vertical: FlickSpacing.sm,
        ),
        decoration: BoxDecoration(
          color:        FlickColors.surface,
          borderRadius: const BorderRadius.all(FlickRadius.full),
          border:       Border.all(color: FlickColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(language.flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: FlickSpacing.xs),
            Text(
              language.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: FlickColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more_rounded,
                size: 16, color: FlickColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.label});
  final String icon;
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
          Text(icon, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: FlickSpacing.xs),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: FlickColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyLessonCard extends StatelessWidget {
  const _DailyLessonCard({
    required this.language,
    required this.lessonState,
  });

  final Language language;
  final LessonState lessonState;

  @override
  Widget build(BuildContext context) {
    final hasContent = language.hasContent;
    final lesson     = lessonState.lesson;

    return GestureDetector(
      onTap: hasContent
          ? () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DailyLessonScreen()),
              )
          : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(FlickSpacing.lg),
        decoration: BoxDecoration(
          color:        hasContent ? FlickColors.surface : FlickColors.surfaceDim,
          borderRadius: const BorderRadius.all(FlickRadius.lg),
          border:       Border.all(color: FlickColors.border),
        ),
        child: hasContent
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DAILY LESSON',
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color:           FlickColors.textMuted,
                          letterSpacing:   1.2,
                        ),
                  ),
                  const SizedBox(height: FlickSpacing.sm),
                  Text(
                    lesson.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: FlickSpacing.xs),
                  Text(
                    lesson.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: FlickSpacing.md),
                  Row(
                    children: [
                      _MiniChip(
                        icon:  Icons.timer_outlined,
                        label: '~${lesson.estimatedMinutes} min',
                      ),
                      const SizedBox(width: FlickSpacing.sm),
                      _MiniChip(
                        icon:  Icons.bolt_rounded,
                        label: '${lesson.xpReward} XP',
                      ),
                    ],
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DAILY LESSON',
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color:         FlickColors.textMuted,
                          letterSpacing: 1.2,
                        ),
                  ),
                  const SizedBox(height: FlickSpacing.sm),
                  Text(
                    'Content coming soon for ${language.name}',
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: FlickColors.textMuted,
                        ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FlickSpacing.sm + 2,
        vertical: FlickSpacing.xs,
      ),
      decoration: BoxDecoration(
        color:        FlickColors.surfaceDim,
        borderRadius: const BorderRadius.all(FlickRadius.full),
        border:       Border.all(color: FlickColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: FlickColors.textSecondary),
          const SizedBox(width: FlickSpacing.xs),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: FlickColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PuzzlePathCard extends StatelessWidget {
  const _PuzzlePathCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SagaMapScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(FlickSpacing.lg),
        decoration: BoxDecoration(
          color:        FlickColors.surface,
          borderRadius: const BorderRadius.all(FlickRadius.lg),
          border:       Border.all(color: FlickColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Puzzle Path',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: FlickSpacing.xs),
                  Text(
                    'Match words, build vocab',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              color: FlickColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
