import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_theme.dart';
import '../models/language.dart';
import '../models/lesson.dart';
import '../models/puzzle_level.dart';
import '../models/language_level.dart';
import '../main.dart' show authService;
import '../models/user_profile.dart';
import '../providers/daily_goal_provider.dart';
import '../providers/language_provider.dart';
import '../providers/lesson_provider.dart';
import '../providers/review_provider.dart';
import '../providers/saga_provider.dart';
import '../services/friend_service.dart';
import 'ai_practice_screen.dart';
import 'daily_lesson_screen.dart';
import 'friends_screen.dart';
import 'language_picker_screen.dart';
import 'review_screen.dart';
import 'saga_map_screen.dart';
import 'profile_screen.dart';

String _greeting(String langCode) {
  final h = DateTime.now().hour;
  final (m, a, e) = switch (langCode) {
    'es' => ('Buenos días.',     'Buenas tardes.',     'Buenas noches.'),
    'fr' => ('Bonjour.',         'Bon après-midi.',    'Bonsoir.'),
    'de' => ('Guten Morgen.',    'Guten Tag.',         'Guten Abend.'),
    'it' => ('Buongiorno.',      'Buon pomeriggio.',   'Buonasera.'),
    'pt' => ('Bom dia.',         'Boa tarde.',         'Boa noite.'),
    'ja' => ('おはようございます。',   'こんにちは。',          'こんばんは。'),
    'ko' => ('좋은 아침이에요.',     '안녕하세요.',           '좋은 저녁이에요.'),
    'zh' => ('早上好。',           '下午好。',              '晚上好。'),
    'ar' => ('صباح الخير.',      'مساء النهار.',       'مساء الخير.'),
    'ru' => ('Доброе утро.',     'Добрый день.',       'Добрый вечер.'),
    'nl' => ('Goedemorgen.',     'Goedemiddag.',       'Goedenavond.'),
    'sv' => ('God morgon.',      'God eftermiddag.',   'God kväll.'),
    'no' => ('God morgen.',      'God ettermiddag.',   'God kveld.'),
    'da' => ('God morgen.',      'God eftermiddag.',   'God aften.'),
    'pl' => ('Dzień dobry.',     'Dzień dobry.',       'Dobry wieczór.'),
    'tr' => ('Günaydın.',        'İyi öğleden sonra.', 'İyi akşamlar.'),
    'hi' => ('सुप्रभात।',         'नमस्ते।',             'शुभ संध्या।'),
    'el' => ('Καλημέρα.',        'Καλό απόγευμα.',     'Καλησπέρα.'),
    'he' => ('בוקר טוב.',        'צהריים טובים.',      'ערב טוב.'),
    'vi' => ('Chào buổi sáng.', 'Chào buổi chiều.',  'Chào buổi tối.'),
    _    => ('Good morning.',    'Good afternoon.',    'Good evening.'),
  };
  return h < 12 ? m : h < 20 ? a : e;
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
    final reviewItems = ref.watch(reviewProvider);
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
                  // Axiom icon mark
                  SvgPicture.asset(
                    'assets/images/icon.svg',
                    width: 34,
                    height: 34,
                  ),
                  const SizedBox(width: FlickSpacing.sm),
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

              Builder(builder: (context) {
                final langXp = sagaState.xpForLanguage(language.code);
                return Row(
                  children: [
                    _StatPill(icon: '🔥', label: '${sagaState.streakCount} day streak'),
                    if (langXp > 0) ...[
                      const SizedBox(width: FlickSpacing.sm),
                      _StatPill(icon: '⚡', label: '$langXp XP'),
                      const SizedBox(width: FlickSpacing.sm),
                      _StatPill(
                        icon: '🎓',
                        label: levelLabelForXp(langXp),
                      ),
                    ],
                  ],
                );
              }).animate().fadeIn(delay: 80.ms, duration: 300.ms),

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

              if (reviewItems.isNotEmpty)
                _ReviewCard(count: reviewItems.length)
                    .animate()
                    .fadeIn(delay: 220.ms, duration: 300.ms),

              if (reviewItems.isNotEmpty)
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

              const SizedBox(height: FlickSpacing.md),

              _FriendLeaderboardCard(myUid: authService.currentUser?.id ?? '')
                  .animate()
                  .fadeIn(delay: 360.ms, duration: 300.ms),

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

    return Semantics(
      label: hasContent ? 'Daily Lesson: ${lessonState.lesson.title}' : 'Daily Lesson',
      button: hasContent && !generating,
      child: GestureDetector(
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

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Review: $count words to practice',
      button: true,
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReviewScreen()),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(FlickSpacing.lg),
          decoration: BoxDecoration(
            color:        FlickColors.surface,
            borderRadius: const BorderRadius.all(FlickRadius.lg),
            border:       Border.all(
                color: FlickColors.warning.withValues(alpha: 0.5), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color:        FlickColors.warning.withValues(alpha: 0.15),
                  borderRadius: const BorderRadius.all(FlickRadius.md),
                ),
                child: const Icon(Icons.refresh_rounded,
                    color: FlickColors.warning, size: 22),
              ),
              const SizedBox(width: FlickSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Review mistakes',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 2),
                    Text(
                      '$count word${count == 1 ? '' : 's'} waiting for review',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: FlickColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded,
                  color: FlickColors.warning),
            ],
          ),
        ),
      ),
    );
  }
}

class _PuzzlePathCard extends StatelessWidget {
  const _PuzzlePathCard();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Puzzle Path — Match words, build vocabulary',
      button: true,
      child: GestureDetector(
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
      ),
    );
  }
}

class _AiPracticeCard extends StatefulWidget {
  const _AiPracticeCard();

  @override
  State<_AiPracticeCard> createState() => _AiPracticeCardState();
}

class _AiPracticeCardState extends State<_AiPracticeCard> {
  static const _kPrefsKey = 'ai_practice_used';
  bool _isNew = true;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => _isNew = !(p.getBool(_kPrefsKey) ?? false));
    });
  }

  Future<void> _onTap() async {
    if (_isNew) {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_kPrefsKey, true);
      if (mounted) setState(() => _isNew = false);
    }
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AiPracticeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
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
                      if (_isNew) ...[
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

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: FlickColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: FlickRadius.xl),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(FlickSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: FlickColors.border,
                  borderRadius: const BorderRadius.all(FlickRadius.full),
                ),
              ),
            ),
            const SizedBox(height: FlickSpacing.lg),
            Text(
              'WORD OF THE DAY',
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: FlickColors.primary, letterSpacing: 1.2),
            ),
            const SizedBox(height: FlickSpacing.md),
            Text(
              word.targetWord,
              style: Theme.of(context).textTheme.displaySmall!.copyWith(
                    color: FlickColors.primary),
            ),
            const SizedBox(height: FlickSpacing.sm),
            Row(
              children: [
                Text(language.flag, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: FlickSpacing.sm),
                Text(
                  language.name,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: FlickColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: FlickSpacing.lg),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(FlickSpacing.md),
              decoration: BoxDecoration(
                color: FlickColors.surfaceDim,
                borderRadius: const BorderRadius.all(FlickRadius.md),
                border: Border.all(color: FlickColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.translate_rounded,
                      size: 18, color: FlickColors.textMuted),
                  const SizedBox(width: FlickSpacing.sm),
                  Text(
                    word.sourceWord,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: FlickColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: FlickSpacing.xl),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
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
            const Icon(Icons.chevron_right_rounded,
                color: FlickColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Friend leaderboard preview card
// ---------------------------------------------------------------------------

class _FriendLeaderboardCard extends StatefulWidget {
  const _FriendLeaderboardCard({required this.myUid});
  final String myUid;

  @override
  State<_FriendLeaderboardCard> createState() => _FriendLeaderboardCardState();
}

class _FriendLeaderboardCardState extends State<_FriendLeaderboardCard> {
  List<UserProfile> _entries = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    FriendService().leaderboard().then((list) {
      if (mounted) setState(() { _entries = list; _loaded = true; });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loaded && _entries.length <= 1) return const SizedBox.shrink();

    final preview = _entries.take(3).toList();

    return GestureDetector(
      onTap: () {
        final profile = UserProfile(uid: widget.myUid);
        Navigator.push(context, MaterialPageRoute(
            builder: (_) => FriendsScreen(myProfile: profile)));
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(FlickSpacing.md),
        decoration: BoxDecoration(
          color:        FlickColors.surface,
          borderRadius: const BorderRadius.all(FlickRadius.lg),
          border:       Border.all(color: FlickColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('FRIEND LEADERBOARD',
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                        color: FlickColors.textMuted, letterSpacing: 1.2)),
                const Spacer(),
                const Icon(Icons.arrow_forward_rounded,
                    size: 14, color: FlickColors.textMuted),
              ],
            ),
            const SizedBox(height: FlickSpacing.sm),
            if (!_loaded)
              const LinearProgressIndicator()
            else
              ...preview.asMap().entries.map((e) {
                final rank  = e.key + 1;
                final entry = e.value;
                final isMe  = entry.uid == widget.myUid;
                final name  = entry.name.isNotEmpty ? entry.name : 'Player';
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        child: Text('$rank.',
                            style: Theme.of(context).textTheme.labelSmall!
                                .copyWith(color: FlickColors.textMuted)),
                      ),
                      const SizedBox(width: FlickSpacing.sm),
                      Expanded(
                        child: Text(
                          isMe ? '$name (you)' : name,
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontWeight: isMe ? FontWeight.w600 : FontWeight.normal,
                              color: isMe
                                  ? FlickColors.primary
                                  : FlickColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text('${entry.totalXp} XP',
                          style: Theme.of(context).textTheme.labelSmall!
                              .copyWith(color: FlickColors.textSecondary)),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
