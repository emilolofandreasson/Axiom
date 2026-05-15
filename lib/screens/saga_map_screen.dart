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

            // Level nodes with world banners and path connectors
            for (int i = 0; i < levels.length; i++) ...[
              // Inject world banner when CEFR level changes
              if (i == 0 || levels[i].cefrLevel != levels[i - 1].cefrLevel)
                _WorldBanner(cefrLevel: levels[i].cefrLevel, index: i),

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
// World banner — shown when CEFR level changes in the path
// ---------------------------------------------------------------------------

class _WorldBanner extends StatelessWidget {
  const _WorldBanner({required this.cefrLevel, required this.index});

  final String cefrLevel;
  final int    index;

  static const _worlds = {
    'A1': (emoji: '🌱', name: 'Beginner Plaza',     colors: [Color(0xFF43A047), Color(0xFFAED581)]),
    'A2': (emoji: '🌱', name: 'Beginner Plaza',     colors: [Color(0xFF43A047), Color(0xFFAED581)]),
    'B1': (emoji: '📚', name: 'Language Library',   colors: [Color(0xFF1976D2), Color(0xFF64B5F6)]),
    'B2': (emoji: '📚', name: 'Language Library',   colors: [Color(0xFF1976D2), Color(0xFF64B5F6)]),
    'C1': (emoji: '🎓', name: "Master's University",colors: [Color(0xFF6A1B9A), Color(0xFFCE93D8)]),
    'C2': (emoji: '🎓', name: "Master's University",colors: [Color(0xFF6A1B9A), Color(0xFFCE93D8)]),
  };

  @override
  Widget build(BuildContext context) {
    final world = _worlds[cefrLevel] ??
        (emoji: '⭐', name: 'New World', colors: const [Color(0xFF546E7A), Color(0xFF90A4AE)]);

    return Padding(
      padding: EdgeInsets.only(
        top: index == 0 ? 0 : FlickSpacing.xl,
        bottom: FlickSpacing.lg,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: FlickSpacing.md,
          horizontal: FlickSpacing.lg,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: world.colors,
            begin: Alignment.centerLeft,
            end:   Alignment.centerRight,
          ),
          borderRadius: const BorderRadius.all(FlickRadius.xl),
        ),
        child: Row(
          children: [
            Text(world.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: FlickSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    world.name,
                    style: const TextStyle(
                      color:      Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize:   16,
                    ),
                  ),
                  Text(
                    cefrLevel,
                    style: const TextStyle(
                      color:   Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 40))
        .fadeIn(duration: 350.ms)
        .slideY(begin: -0.06, end: 0, curve: Curves.easeOut);
  }
}

// ---------------------------------------------------------------------------
// Level node — Candy Crush-style circular node with stars + avatar
// ---------------------------------------------------------------------------

int _starCount(bool isComplete, int retries) {
  if (!isComplete) return 0;
  if (retries == 0) return 3;
  if (retries <= 2) return 2;
  return 1;
}

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

  final PuzzleLevel    level;
  final bool           isUnlocked;
  final bool           isComplete;
  final bool           isCurrent;
  final int            retries;
  final int            index;
  final VoidCallback?  onTap;

  Color get _circleColor {
    if (isComplete)   return FlickColors.success;
    if (isUnlocked)   return FlickColors.primary;
    return FlickColors.surfaceDim;
  }

  @override
  Widget build(BuildContext context) {
    final isLeft = index.isEven;
    final stars  = _starCount(isComplete, retries);

    Widget circle = GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 300.ms,
        width:  64,
        height: 64,
        decoration: BoxDecoration(
          color:  _circleColor,
          shape:  BoxShape.circle,
          boxShadow: isCurrent
              ? [BoxShadow(
                  color:      FlickColors.primary.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 4,
                )]
              : isComplete
                  ? [BoxShadow(
                      color:      FlickColors.success.withValues(alpha: 0.25),
                      blurRadius: 12,
                    )]
                  : null,
        ),
        child: Center(
          child: isComplete
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 28)
              : isUnlocked
                  ? Text(
                      '${level.levelNumber}',
                      style: const TextStyle(
                        color:      Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize:   20,
                      ),
                    )
                  : const Icon(Icons.lock_rounded,
                        color: FlickColors.textMuted, size: 20),
        ),
      ),
    );

    // Pulsing scale animation for the current level
    if (isCurrent) {
      circle = circle
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(
            begin: 1.0,
            end:   1.12,
            duration: 900.ms,
            curve: Curves.easeInOut,
          );
    }

    final node = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Floating avatar emoji above current node
        if (isCurrent)
          const Text('🦊', style: TextStyle(fontSize: 22))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: 0, end: -5, duration: 700.ms, curve: Curves.easeInOut)
        else
          const SizedBox(height: 22),

        const SizedBox(height: 4),
        circle,
        const SizedBox(height: 6),

        // Star rating
        if (isComplete)
          _StarRow(stars: stars),

        const SizedBox(height: 4),

        // Level title
        SizedBox(
          width: 90,
          child: Text(
            level.title,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color:  isUnlocked ? FlickColors.textPrimary : FlickColors.textMuted,
                  fontSize: 11,
                ),
            textAlign: TextAlign.center,
            maxLines:  2,
            overflow:  TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    return Align(
      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: Padding(
        padding: EdgeInsets.only(
          left:  isLeft  ? FlickSpacing.xl : 0,
          right: !isLeft ? FlickSpacing.xl : 0,
        ),
        child: node
            .animate(delay: Duration(milliseconds: index * 70))
            .fadeIn(duration: 300.ms)
            .slideX(
              begin: isLeft ? -0.08 : 0.08,
              end:   0,
              curve: Curves.easeOut,
            ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.stars});
  final int stars;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) => Icon(
        i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
        size:  14,
        color: i < stars ? const Color(0xFFFFC107) : FlickColors.border,
      )),
    );
  }
}

// ---------------------------------------------------------------------------
// Dashed vertical connector between nodes
// ---------------------------------------------------------------------------

class _PathConnector extends StatelessWidget {
  const _PathConnector({required this.complete});
  final bool complete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Center(
        child: AnimatedContainer(
          duration: 600.ms,
          width: 36,
          height: 36,
          child: CustomPaint(
            painter: _DashedLinePainter(
              color: complete
                  ? FlickColors.success.withValues(alpha: 0.7)
                  : FlickColors.border,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const dashHeight = 5.0;
    const dashSpace  = 3.0;
    final paint = Paint()
      ..color       = color
      ..strokeWidth = 2.5
      ..strokeCap   = StrokeCap.round;

    double y = 0;
    final x = size.width / 2;
    while (y < size.height) {
      canvas.drawLine(Offset(x, y), Offset(x, y + dashHeight), paint);
      y += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color;
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
