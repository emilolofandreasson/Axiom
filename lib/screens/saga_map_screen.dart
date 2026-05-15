import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../models/language.dart';
import '../models/language_level.dart';
import '../models/puzzle_level.dart';
import '../providers/generated_puzzles_provider.dart';
import '../providers/language_provider.dart';
import '../providers/saga_provider.dart';
import 'puzzle_screen.dart';
import 'daily_lesson_screen.dart';

class SagaMapScreen extends ConsumerStatefulWidget {
  const SagaMapScreen({super.key});

  @override
  ConsumerState<SagaMapScreen> createState() => _SagaMapScreenState();
}

class _SagaMapScreenState extends ConsumerState<SagaMapScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeGenerate());
  }

  void _maybeGenerate() {
    final lang = ref.read(languageProvider);
    if (!lang.hasContent) {
      ref.read(generatedPuzzlesProvider.notifier).ensureLevels(
        languageCode: lang.code,
        languageName: lang.name,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final saga      = ref.watch(sagaProvider);
    final language  = ref.watch(languageProvider);
    final genState  = ref.watch(generatedPuzzlesProvider);

    // Trigger generation when language changes to one without content.
    ref.listen<Language>(languageProvider, (_, next) {
      if (!next.hasContent) {
        ref.read(generatedPuzzlesProvider.notifier).ensureLevels(
          languageCode: next.code,
          languageName: next.name,
        );
      }
    });

    // Use compiled levels if available, otherwise use AI-generated ones.
    final compiledLevels = kPuzzleLevelsByLanguage[language.code];
    final aiLevels       = genState.levelsByLanguage[language.code] ?? [];
    final levels         = compiledLevels ?? (aiLevels.isNotEmpty ? aiLevels : null);
    final hasLevels      = levels != null;
    final isGenerating   = genState.isGenerating(language.code);

    // First level that is unlocked but not yet completed = "current".
    final currentLevelId = hasLevels
        ? levels.firstWhere(
            (l) => saga.isUnlocked(l) && !saga.isCompleted(l.id),
            orElse: () => levels.last,
          ).id
        : null;

    return Scaffold(
      backgroundColor: FlickColors.background,
      appBar: AppBar(
        title: const Text('Journey'),
        actions: [
          // XP badge
          Padding(
            padding: const EdgeInsets.only(right: FlickSpacing.md),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: FlickSpacing.sm + 2,
                  vertical: FlickSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: FlickColors.primaryDim,
                  borderRadius: const BorderRadius.all(FlickRadius.full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded,
                        size: 14, color: FlickColors.primary),
                    const SizedBox(width: 2),
                    Text(
                      '${saga.xpForLanguage(language.code)} XP',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall!
                          .copyWith(color: FlickColors.primary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          vertical: FlickSpacing.xl,
          horizontal: FlickSpacing.xl,
        ),
        children: [
          // Language header
          _LanguageHeader(language: language, saga: saga),

          const SizedBox(height: FlickSpacing.xl),

          // No puzzle content yet — show generating indicator or placeholder
          if (!hasLevels) ...[
            if (isGenerating)
              _GeneratingPuzzlesIndicator(languageName: language.name)
            else if (!language.hasContent)
              _NoContentPlaceholder(languageName: language.name),
            const SizedBox(height: FlickSpacing.xl),
          ],

          if (hasLevels) ...[
            // Reveal powerup info strip
            if (saga.revealPowerups > 0)
              _PowerupBanner(count: saga.revealPowerups),

            if (saga.revealPowerups > 0) const SizedBox(height: FlickSpacing.lg),

            // Level nodes with path connectors
            for (int i = 0; i < levels.length; i++) ...[
              _LevelNode(
                level:      levels[i],
                isUnlocked: saga.isUnlocked(levels[i]),
                isComplete: saga.isCompleted(levels[i].id),
                isCurrent:  levels[i].id == currentLevelId,
                retries:    saga.retriesFor(levels[i].id),
                index:      i,
                onTap: saga.isUnlocked(levels[i])
                    ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PuzzleScreen(level: levels[i]),
                          ),
                        )
                    : null,
              ),
              if (i < levels.length - 1)
                _PathConnector(complete: saga.isCompleted(levels[i].id)),
            ],

            const SizedBox(height: FlickSpacing.xl),
          ],

          // Grammar lesson gateway — unlocks after 3 puzzle levels
          _LessonGatewayNode(
            unlocked:    saga.completedIds.length >= 3,
            levelsCount: hasLevels ? levels.length : 0,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const DailyLessonScreen()),
            ),
          ),

          const SizedBox(height: FlickSpacing.xxl),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Language header
// ---------------------------------------------------------------------------

class _LanguageHeader extends StatelessWidget {
  const _LanguageHeader({required this.language, required this.saga});
  final Language language;
  final SagaState saga;

  @override
  Widget build(BuildContext context) {
    final xp    = saga.xpForLanguage(language.code);
    final level = levelForXp(xp);
    return Row(
      children: [
        Text(language.flag, style: const TextStyle(fontSize: 38)),
        const SizedBox(width: FlickSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(language.name,
                style: Theme.of(context).textTheme.headlineSmall),
            Text(
              '${level.label} · ${level.cefrCode} path',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(color: FlickColors.textSecondary),
            ),
          ],
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideX(begin: -0.08, end: 0, curve: Curves.easeOut);
  }
}

// ---------------------------------------------------------------------------
// No puzzle content placeholder
// ---------------------------------------------------------------------------

class _GeneratingPuzzlesIndicator extends StatelessWidget {
  const _GeneratingPuzzlesIndicator({required this.languageName});
  final String languageName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(FlickSpacing.xl),
      decoration: BoxDecoration(
        color:        FlickColors.primaryDim,
        borderRadius: const BorderRadius.all(FlickRadius.xl),
        border:       Border.all(color: FlickColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 36, height: 36,
            child: CircularProgressIndicator(strokeWidth: 3, color: FlickColors.primary),
          ),
          const SizedBox(height: FlickSpacing.md),
          Text(
            'Building your $languageName path…',
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: FlickColors.primary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: FlickSpacing.sm),
          Text(
            'Gemini is generating personalised puzzles for you.',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: FlickColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _NoContentPlaceholder extends StatelessWidget {
  const _NoContentPlaceholder({required this.languageName});
  final String languageName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(FlickSpacing.xl),
      decoration: BoxDecoration(
        color:        FlickColors.surfaceDim,
        borderRadius: const BorderRadius.all(FlickRadius.xl),
        border:       Border.all(color: FlickColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.construction_rounded,
              size: 40, color: FlickColors.textMuted),
          const SizedBox(height: FlickSpacing.md),
          Text(
            '$languageName puzzle path coming soon',
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: FlickColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: FlickSpacing.sm),
          Text(
            'Use the AI lesson engine below to practise in the meantime.',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: FlickColors.textMuted,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ---------------------------------------------------------------------------
// Powerup info banner
// ---------------------------------------------------------------------------

class _PowerupBanner extends StatelessWidget {
  const _PowerupBanner({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FlickSpacing.md,
        vertical: FlickSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: FlickColors.primaryDim,
        borderRadius: const BorderRadius.all(FlickRadius.md),
        border: Border.all(color: FlickColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.visibility_rounded,
              size: 16, color: FlickColors.primary),
          const SizedBox(width: FlickSpacing.sm),
          Expanded(
            child: Text(
              'You have $count Reveal ${count == 1 ? "powerup" : "powerups"}. '
              'Use inside a level to hint pair colors.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(color: FlickColors.primary),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

// ---------------------------------------------------------------------------
// Level node — alternates left/right for winding-path feel
// ---------------------------------------------------------------------------

class _LevelNode extends StatelessWidget {
  const _LevelNode({
    required this.level,
    required this.isUnlocked,
    required this.isComplete,
    required this.isCurrent,
    required this.retries,
    required this.index,
    required this.onTap,
  });

  final PuzzleLevel level;
  final bool isUnlocked;
  final bool isComplete;
  final bool isCurrent;
  final int retries;
  final int index;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isLeft = index.isEven;

    final card = GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 210,
        padding: const EdgeInsets.all(FlickSpacing.md),
        decoration: BoxDecoration(
          color: isComplete
              ? FlickColors.successDim
              : isUnlocked
                  ? FlickColors.surface
                  : FlickColors.surfaceDim,
          borderRadius: const BorderRadius.all(FlickRadius.xl),
          border: Border.all(
            color: isCurrent
                ? FlickColors.primary
                : isComplete
                    ? FlickColors.success
                    : isUnlocked
                        ? FlickColors.border
                        : FlickColors.border.withValues(alpha: 0.4),
            width: isCurrent || isComplete ? 2 : 1,
          ),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color:      FlickColors.primary.withValues(alpha: 0.28),
                    blurRadius: 20,
                    spreadRadius: 1,
                    offset:     const Offset(0, 4),
                  )
                ]
              : isUnlocked && !isComplete
                  ? [
                      BoxShadow(
                        color:      FlickColors.primary.withValues(alpha: 0.07),
                        blurRadius: 16,
                        offset:     const Offset(0, 4),
                      )
                    ]
                  : null,
        ),
        child: Row(
          children: [
            // Badge circle
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: isComplete
                    ? FlickColors.success
                    : isUnlocked
                        ? FlickColors.primary
                        : FlickColors.surfaceDim,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isComplete
                    ? const Icon(Icons.check_rounded,
                          size: 20, color: Colors.white)
                    : isUnlocked
                        ? Text(
                            '${level.levelNumber}',
                            style: const TextStyle(
                              color:      Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize:   15,
                            ),
                          )
                        : const Icon(Icons.lock_rounded,
                              size: 16, color: FlickColors.textMuted),
              ),
            ),

            const SizedBox(width: FlickSpacing.sm),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.title,
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: isUnlocked
                              ? FlickColors.textPrimary
                              : FlickColors.textMuted,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${level.cefrLevel}  ·  ${level.xpReward} XP',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall!
                        .copyWith(color: FlickColors.textMuted),
                  ),
                  if (retries > 0 && isComplete)
                    Text(
                      '$retries ${retries == 1 ? "retry" : "retries"}',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall!
                          .copyWith(color: FlickColors.textMuted),
                    ),
                ],
              ),
            ),

            if (isUnlocked && !isComplete)
              const Icon(Icons.chevron_right_rounded,
                  color: FlickColors.textMuted, size: 20),
          ],
        ),
      ),
    );

    return Align(
      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: card
          .animate(delay: Duration(milliseconds: index * 70))
          .fadeIn(duration: 300.ms)
          .slideX(
            begin: isLeft ? -0.08 : 0.08,
            end:   0,
            curve: Curves.easeOut,
          ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dotted vertical connector between nodes
// ---------------------------------------------------------------------------

class _PathConnector extends StatelessWidget {
  const _PathConnector({required this.complete});
  final bool complete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Center(
        child: Container(
          width: 2,
          decoration: BoxDecoration(
            color: complete
                ? FlickColors.success.withValues(alpha: 0.5)
                : FlickColors.border,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gateway node — leads to the AI lesson engine
// ---------------------------------------------------------------------------

class _LessonGatewayNode extends StatelessWidget {
  const _LessonGatewayNode({
    required this.unlocked,
    required this.onTap,
    required this.levelsCount,
  });

  final bool unlocked;
  final VoidCallback onTap;
  final int levelsCount;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: unlocked ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(FlickSpacing.lg),
        decoration: BoxDecoration(
          color: unlocked ? FlickColors.primaryDim : FlickColors.surfaceDim,
          borderRadius: const BorderRadius.all(FlickRadius.xl),
          border: Border.all(
            color: unlocked ? FlickColors.primary : FlickColors.border,
            width: unlocked ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: unlocked ? FlickColors.primary : FlickColors.surfaceDim,
                borderRadius: const BorderRadius.all(FlickRadius.md),
              ),
              child: Icon(
                Icons.school_rounded,
                color:  unlocked ? Colors.white : FlickColors.textMuted,
                size:   24,
              ),
            ),
            const SizedBox(width: FlickSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Grammar Lessons',
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: unlocked
                              ? FlickColors.textPrimary
                              : FlickColors.textMuted,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    unlocked
                        ? 'AI-powered lesson engine — tap to continue'
                        : 'Complete 3 levels to unlock',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(color: FlickColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (!unlocked)
              const Icon(Icons.lock_rounded,
                  color: FlickColors.textMuted, size: 20),
            if (unlocked)
              const Icon(Icons.chevron_right_rounded,
                  color: FlickColors.primary, size: 20),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: levelsCount * 70 + 100),
                duration: 350.ms);
  }
}
