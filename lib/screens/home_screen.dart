import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_theme.dart';
import '../models/language.dart';
import '../models/lesson.dart';
import '../models/puzzle_level.dart';
import '../models/language_level.dart';
import '../providers/daily_goal_provider.dart';
import '../providers/language_provider.dart';
import '../providers/lesson_provider.dart';
import '../providers/saga_provider.dart';
import 'ai_practice_screen.dart';
import 'daily_lesson_screen.dart';
import 'language_picker_screen.dart';
import 'saga_map_screen.dart';
import 'profile_screen.dart';

String _greeting(String langCode) {
  final h = DateTime.now().hour;
  return switch (langCode) {
    'es' => h < 12 ? 'Buenos días.' : h < 20 ? 'Buenas tardes.' : 'Buenas noches.',
    'fr' => h < 12 ? 'Bonjour.' : h < 20 ? 'Bon après-midi.' : 'Bonsoir.',
    'de' => h < 12 ? 'Guten Morgen.' : h < 20 ? 'Guten Tag.' : 'Guten Abend.',
    _    => h < 12 ? 'Good morning.' : h < 20 ? 'Good afternoon.' : 'Good evening.',
  };
}

WordPair? _wordOfDay(String langCode) {
  final levels = kPuzzleLevelsByLanguage[langCode];
  if (levels == null || levels.isEmpty) return null;
  final allPairs = levels.expand((l) => l.pairs).toList();
  if (allPairs.isEmpty) return null;
  final index = DateTime.now().day % allPairs.length;
  return allPairs[index];
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = ref.read(lessonProvider);
      // Only generate if no AI lesson is already loaded or being generated.
      if (!s.isGenerating && !s.lesson.isAiGenerated) {
        ref.read(lessonProvider.notifier).generateInitialLesson();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final language    = ref.watch(languageProvider);
    final lessonState = ref.watch(lessonProvider);
    final sagaState   = ref.watch(sagaProvider);
    final dailyGoal   = ref.watch(dailyGoalProvider);
    final word        = _wordOfDay(language.code);
    final lessons     = kLessonsByLanguage[language.code] ?? kLessonsByLanguage['es']!;

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
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      _greeting(language.code),
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                  ),
                  _LanguageChip(language: language),
                  const SizedBox(width: FlickSpacing.sm),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ProfileScreen()),
                    ),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color:        FlickColors.surface,
                        shape:        BoxShape.circle,
                        border:       Border.all(color: FlickColors.border),
                      ),
                      child: const Icon(Icons.person_rounded,
                          size: 20, color: FlickColors.textSecondary),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: FlickSpacing.md),

              Row(
                children: [
                  _StatPill(icon: '🔥', label: '${sagaState.streakCount} day streak'),
                  const SizedBox(width: FlickSpacing.sm),
                  _StatPill(icon: '⚡', label: '${sagaState.xpForLanguage(language.code)} XP'),
                  const SizedBox(width: FlickSpacing.sm),
                  _StatPill(
                    icon: '🎓',
                    label: levelLabelForXp(sagaState.xpForLanguage(language.code)),
                  ),
                ],
              ).animate().fadeIn(delay: 80.ms, duration: 300.ms),

              const SizedBox(height: FlickSpacing.md),

              _DailyGoalBar(goalState: dailyGoal)
                  .animate().fadeIn(delay: 120.ms, duration: 300.ms),

              const SizedBox(height: FlickSpacing.lg),

              _DailyLessonCard(
                language:    language,
                lessonState: lessonState,
                totalLessons: lessons.length,
              ).animate().fadeIn(delay: 160.ms, duration: 300.ms),

              const SizedBox(height: FlickSpacing.md),

              _PuzzlePathCard()
                  .animate()
                  .fadeIn(delay: 240.ms, duration: 300.ms),

              const SizedBox(height: FlickSpacing.md),

              _AiPracticeCard()
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 300.ms),

              if (word != null) ...[
                const SizedBox(height: FlickSpacing.md),
                _WordOfDayCard(word: word, language: language)
                    .animate()
                    .fadeIn(delay: 320.ms, duration: 300.ms),
              ],

              const SizedBox(height: FlickSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyGoalBar extends StatelessWidget {
  const _DailyGoalBar({required this.goalState});
  final DailyGoalState goalState;

  @override
  Widget build(BuildContext context) {
    final met = goalState.goalMet;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FlickSpacing.md,
        vertical: FlickSpacing.sm,
      ),
      decoration: BoxDecoration(
        color:        FlickColors.surface,
        borderRadius: const BorderRadius.all(FlickRadius.md),
        border:       Border.all(color: FlickColors.border),
      ),
      child: Row(
        children: [
          Text(met ? '🎯' : '📅', style: const TextStyle(fontSize: 14)),
          const SizedBox(width: FlickSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      met ? 'Daily goal reached!' : 'Daily goal',
                      style: Theme.of(context).textTheme.labelMedium!.copyWith(
                            color: met ? FlickColors.success : FlickColors.textPrimary,
                          ),
                    ),
                    Text(
                      '${goalState.xpToday} / $kDailyXpGoal XP',
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                            color: FlickColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: const BorderRadius.all(FlickRadius.full),
                  child: LinearProgressIndicator(
                    value:           goalState.progress,
                    backgroundColor: FlickColors.surfaceDim,
                    valueColor:      AlwaysStoppedAnimation(
                        met ? FlickColors.success : FlickColors.primary),
                    minHeight:       4,
                  ),
                ),
              ],
            ),
          ),
        ],
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
    required this.totalLessons,
  });

  final Language    language;
  final LessonState lessonState;
  final int         totalLessons;

  @override
  Widget build(BuildContext context) {
    final hasContent = language.hasContent;
    final lesson     = lessonState.lesson;
    final lessonNum  = lessonState.lessonIndex + 1;
    final generating = lessonState.isGenerating;
    final failed     = lessonState.lastGenerationFailed;

    return GestureDetector(
      onTap: hasContent && !generating
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
          border: Border.all(
            color: lesson.isAiGenerated
                ? FlickColors.primary.withValues(alpha: 0.4)
                : FlickColors.border,
            width: lesson.isAiGenerated ? 1.5 : 1,
          ),
        ),
        child: hasContent
            ? generating
                ? _GeneratingContent()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'DAILY LESSON',
                            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                                  color: FlickColors.textMuted, letterSpacing: 1.2),
                          ),
                          const Spacer(),
                          if (lesson.isAiGenerated)
                            _AiBadge()
                          else if (failed)
                            _FallbackBadge()
                          else
                            Text(
                              '$lessonNum / $totalLessons',
                              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                                    color: FlickColors.primary, letterSpacing: 0.5),
                            ),
                        ],
                      ),
                      const SizedBox(height: FlickSpacing.sm),
                      Text(lesson.title,
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: FlickSpacing.xs),
                      Text(lesson.description,
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: FlickSpacing.md),
                      Row(
                        children: [
                          _MiniChip(
                            icon:  Icons.signal_cellular_alt_rounded,
                            label: lesson.cefrLevel,
                          ),
                          const SizedBox(width: FlickSpacing.sm),
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
                          color: FlickColors.textMuted, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: FlickSpacing.sm),
                  Text(
                    'Content coming soon for ${language.name}',
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: FlickColors.textMuted),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GeneratingContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('DAILY LESSON',
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
              color: FlickColors.textMuted, letterSpacing: 1.2)),
      const SizedBox(height: FlickSpacing.md),
      Row(
        children: [
          const SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: FlickColors.primary),
          ),
          const SizedBox(width: FlickSpacing.sm),
          Text('Generating your lesson…',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    ],
  );
}

class _AiBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color:        FlickColors.primaryDim,
      borderRadius: const BorderRadius.all(FlickRadius.full),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.auto_awesome_rounded,
            size: 11, color: FlickColors.primary),
        const SizedBox(width: 3),
        Text('AI',
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: FlickColors.primary, fontSize: 10)),
      ],
    ),
  );
}

class _FallbackBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color:        FlickColors.surfaceDim,
      borderRadius: const BorderRadius.all(FlickRadius.full),
      border:       Border.all(color: FlickColors.border),
    ),
    child: Text('Seed',
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
            color: FlickColors.textMuted, fontSize: 10)),
  );
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
  const _PuzzlePathCard();

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
                  Text('Puzzle Path',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: FlickSpacing.xs),
                  Text('Match words, build vocab',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: FlickColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _AiPracticeCard extends StatelessWidget {
  const _AiPracticeCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AiPracticeScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(FlickSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              FlickColors.primary.withValues(alpha: 0.12),
              FlickColors.primaryDim,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.all(FlickRadius.lg),
          border: Border.all(
              color: FlickColors.primary.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color:        FlickColors.primary,
                borderRadius: const BorderRadius.all(FlickRadius.md),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: FlickSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('AI Practice',
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(width: FlickSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: FlickColors.primary,
                          borderRadius:
                              const BorderRadius.all(FlickRadius.full),
                        ),
                        child: Text('NEW',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall!
                                .copyWith(
                                    color: Colors.white,
                                    fontSize: 9,
                                    letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('Pick a topic, get 4 AI exercises instantly',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: FlickColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded,
                color: FlickColors.primary),
          ],
        ),
      ),
    );
  }
}

class _WordOfDayCard extends StatelessWidget {
  const _WordOfDayCard({required this.word, required this.language});
  final WordPair word;
  final Language language;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(FlickSpacing.lg),
      decoration: BoxDecoration(
        color:        FlickColors.primaryDim,
        borderRadius: const BorderRadius.all(FlickRadius.lg),
        border:       Border.all(color: FlickColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Text('✨', style: TextStyle(fontSize: 22)),
          const SizedBox(width: FlickSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WORD OF THE DAY',
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                        color: FlickColors.primary, letterSpacing: 1.2),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: word.targetWord,
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                              color: FlickColors.primary),
                      ),
                      TextSpan(
                        text: '  —  ${word.sourceWord}',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: FlickColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
