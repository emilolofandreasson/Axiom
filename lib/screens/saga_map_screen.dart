import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../models/puzzle_level.dart';
import '../providers/saga_provider.dart';
import 'puzzle_screen.dart';
import 'daily_lesson_screen.dart';

// Cultural accent colors and flags keyed by ISO 639-1 language code
extension _LanguageTheme on String {
  Color get accentColor => switch (this) {
    'es' => const Color(0xFFC0392B), // Spanish red
    'fr' => const Color(0xFF1A5276), // French navy
    'de' => const Color(0xFF1E8449), // German green
    'pt' => const Color(0xFF1A5276), // Portuguese blue
    'it' => const Color(0xFF27AE60), // Italian green
    _    => FlickColors.primary,
  };

  String get flag => switch (this) {
    'es' => '🇪🇸',
    'fr' => '🇫🇷',
    'de' => '🇩🇪',
    'pt' => '🇵🇹',
    'it' => '🇮🇹',
    _    => '🌍',
  };

  String get fullName => switch (this) {
    'es' => 'Spanish',
    'fr' => 'French',
    'de' => 'German',
    'pt' => 'Portuguese',
    'it' => 'Italian',
    _    => 'Unknown',
  };
}

class SagaMapScreen extends ConsumerWidget {
  const SagaMapScreen({super.key});

  static const _language = 'es';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saga = ref.watch(sagaProvider);

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
                      '${saga.totalXp} XP',
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
          _LanguageHeader(language: _language),

          const SizedBox(height: FlickSpacing.xl),

          // Reveal powerup info strip
          if (saga.revealPowerups > 0)
            _PowerupBanner(count: saga.revealPowerups),

          if (saga.revealPowerups > 0) const SizedBox(height: FlickSpacing.lg),

          // Level nodes with path connectors
          for (int i = 0; i < kPuzzleLevels.length; i++) ...[
            _LevelNode(
              level:      kPuzzleLevels[i],
              isUnlocked: saga.isUnlocked(kPuzzleLevels[i]),
              isComplete: saga.isCompleted(kPuzzleLevels[i].id),
              retries:    saga.retriesFor(kPuzzleLevels[i].id),
              index:      i,
              onTap: saga.isUnlocked(kPuzzleLevels[i])
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PuzzleScreen(level: kPuzzleLevels[i]),
                        ),
                      )
                  : null,
            ),
            if (i < kPuzzleLevels.length - 1)
              _PathConnector(complete: saga.isCompleted(kPuzzleLevels[i].id)),
          ],

          const SizedBox(height: FlickSpacing.xl),

          // Grammar lesson gateway — unlocks after 3 puzzle levels
          _LessonGatewayNode(
            unlocked: saga.completedIds.length >= 3,
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
  const _LanguageHeader({required this.language});
  final String language;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(language.flag, style: const TextStyle(fontSize: 38)),
        const SizedBox(width: FlickSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(language.fullName,
                style: Theme.of(context).textTheme.headlineSmall),
            Text(
              'Beginner path · A1–A2',
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
        border: Border.all(color: FlickColors.primary.withOpacity(0.3)),
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
    required this.retries,
    required this.index,
    required this.onTap,
  });

  final PuzzleLevel level;
  final bool isUnlocked;
  final bool isComplete;
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
            color: isComplete
                ? FlickColors.success
                : isUnlocked
                    ? FlickColors.border
                    : FlickColors.border.withOpacity(0.4),
            width: isComplete ? 2 : 1,
          ),
          boxShadow: isUnlocked && !isComplete
              ? [
                  BoxShadow(
                    color:      FlickColors.primary.withOpacity(0.07),
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
                ? FlickColors.success.withOpacity(0.5)
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
  });

  final bool unlocked;
  final VoidCallback onTap;

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
        .fadeIn(delay: Duration(milliseconds: kPuzzleLevels.length * 70 + 100),
                duration: 350.ms);
  }
}
