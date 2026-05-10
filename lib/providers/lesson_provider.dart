import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flick_sdk/flick_sdk.dart';
import '../models/lesson.dart';
import '../models/question.dart';
import 'language_provider.dart';
import 'saga_provider.dart';
import 'daily_goal_provider.dart';
import 'hearts_provider.dart';
import '../main.dart' show lessonGenerator;

// ---------------------------------------------------------------------------
// Lesson state
// ---------------------------------------------------------------------------

enum AnswerState { unanswered, correct, wrong }

class QuestionResult {
  const QuestionResult({
    required this.question,
    required this.answerState,
    this.userAnswer,
    this.timeTakenMs,
  });

  final Question question;
  final AnswerState answerState;
  final Object? userAnswer;  // String for MC/speaking, List<String> for WO
  final int? timeTakenMs;
}

class LessonState {
  const LessonState({
    required this.lesson,
    this.lessonIndex = 0,
    this.currentIndex = 0,
    this.results = const [],
    this.status = LessonStatus.idle,
    this.currentAnswerState = AnswerState.unanswered,
    this.questionStartedAt,
    this.isGenerating = false,
    this.lastGenerationFailed = false,
  });

  final Lesson lesson;
  final int lessonIndex;
  final bool isGenerating;
  final bool lastGenerationFailed;
  final int currentIndex;
  final List<QuestionResult> results;
  final LessonStatus status;
  final AnswerState currentAnswerState;
  final DateTime? questionStartedAt;

  Question get currentQuestion => lesson.questions[currentIndex];
  bool get isLastQuestion => currentIndex >= lesson.questions.length - 1;
  int get totalQuestions => lesson.questions.length;
  double get progressFraction =>
      totalQuestions == 0 ? 0.0 : (currentIndex + 1) / totalQuestions;

  int get correctCount =>
      results.where((r) => r.answerState == AnswerState.correct).length;

  double get accuracy =>
      results.isEmpty ? 0 : correctCount / results.length;

  LessonState copyWith({
    Lesson? lesson,
    int? lessonIndex,
    int? currentIndex,
    List<QuestionResult>? results,
    LessonStatus? status,
    AnswerState? currentAnswerState,
    DateTime? questionStartedAt,
    bool? isGenerating,
    bool? lastGenerationFailed,
  }) =>
      LessonState(
        lesson:                lesson               ?? this.lesson,
        lessonIndex:           lessonIndex          ?? this.lessonIndex,
        currentIndex:          currentIndex         ?? this.currentIndex,
        results:               results              ?? this.results,
        status:                status               ?? this.status,
        currentAnswerState:    currentAnswerState   ?? this.currentAnswerState,
        questionStartedAt:     questionStartedAt    ?? this.questionStartedAt,
        isGenerating:          isGenerating         ?? this.isGenerating,
        lastGenerationFailed:  lastGenerationFailed ?? this.lastGenerationFailed,
      );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class LessonNotifier extends Notifier<LessonState> {
  DateTime? _lessonStartedAt;

  @override
  LessonState build() {
    final language = ref.watch(languageProvider);
    // Use seed lessons for this language if available, else Spanish seeds as
    // emergency fallback. For AI-only languages the initial lesson is replaced
    // by generateInitialLesson() immediately after the first frame.
    final seeds = kLessonsByLanguage[language.code] ?? kLessonsByLanguage['es']!;
    return LessonState(lesson: seeds[0], lessonIndex: 0, status: LessonStatus.idle);
  }

  void startLesson() {
    _lessonStartedAt = DateTime.now();
    state = state.copyWith(
      status:            LessonStatus.inProgress,
      currentIndex:      0,
      results:           [],
      questionStartedAt: DateTime.now(),
    );

    final now = DateTime.now();
    EventSensor.instance.emit('lesson_started', {
      'lesson_id':       state.lesson.id,
      'cefr_level':      state.lesson.cefrLevel,
      'skill_tag':       state.lesson.skillTag,
      'skill_category':  state.lesson.skillTag.split('/').first, // 'vocabulary' | 'grammar' | 'conversation'
      'question_count':  state.totalQuestions,
      'hour_of_day':     now.hour,
      'day_of_week':     now.weekday,
      'course_language': state.lesson.courseLanguage,
    });
  }

  Future<void> nextLesson() async {
    final language = ref.read(languageProvider);
    final saga     = ref.read(sagaProvider);

    state = state.copyWith(isGenerating: true, lastGenerationFailed: false);

    final generated = await lessonGenerator.generate(
      languageCode: language.code,
      languageName: language.name,
      userXp:       saga.xpForLanguage(language.code),
    );

    if (generated != null) {
      state = state.copyWith(
        lesson:               generated,
        lessonIndex:          state.lessonIndex + 1,
        status:               LessonStatus.idle,
        isGenerating:         false,
        lastGenerationFailed: false,
      );
    } else {
      // AI failed — fall back to seed lessons for this language.
      // For languages without seed content, keep the current lesson so the
      // user sees a retry prompt rather than wrong-language content.
      final seeds = kLessonsByLanguage[language.code];
      if (seeds != null) {
        final nextIndex = seeds.length > 1
            ? (state.lessonIndex + 1) % seeds.length
            : 0;
        state = state.copyWith(
          lesson:               seeds[nextIndex],
          lessonIndex:          state.lessonIndex + 1,
          status:               LessonStatus.idle,
          isGenerating:         false,
          lastGenerationFailed: true,
        );
      } else {
        // No seeds for this language — stay on current lesson, flag failed.
        state = state.copyWith(
          isGenerating:         false,
          lastGenerationFailed: true,
          status:               LessonStatus.idle,
        );
      }
    }
    // Lesson intro screen drives startLesson() explicitly via "Begin" button.
  }

  Future<void> generateInitialLesson() async {
    final language = ref.read(languageProvider);
    final saga     = ref.read(sagaProvider);

    state = state.copyWith(isGenerating: true, lastGenerationFailed: false);

    final generated = await lessonGenerator.generate(
      languageCode: language.code,
      languageName: language.name,
      userXp:       saga.xpForLanguage(language.code),
    );

    if (generated != null) {
      state = state.copyWith(
        lesson:               generated,
        lessonIndex:          0,
        status:               LessonStatus.idle,
        isGenerating:         false,
        lastGenerationFailed: false,
      );
    } else {
      state = state.copyWith(
        isGenerating:         false,
        lastGenerationFailed: true,
      );
    }
  }

  void submitAnswer(Object answer) {
    final q = state.currentQuestion;
    final elapsed = state.questionStartedAt != null
        ? DateTime.now().difference(state.questionStartedAt!).inMilliseconds
        : null;

    final isCorrect = switch (q) {
      MultipleChoiceQuestion mc =>
          answer is int && answer == mc.correctIndex,
      WordOrderQuestion wo =>
          answer is List<String> &&
          _listEquals(answer, wo.correctSentence),
      SpeakingQuestion _ =>
          true, // AI grades these; always advance
    };

    final result = QuestionResult(
      question:     q,
      answerState:  isCorrect ? AnswerState.correct : AnswerState.wrong,
      userAnswer:   answer,
      timeTakenMs:  elapsed,
    );

    state = state.copyWith(
      currentAnswerState: result.answerState,
      results: [...state.results, result],
    );

    if (!isCorrect) {
      ref.read(heartsProvider.notifier).loseHeart();
      // If hearts are now empty, end the lesson.
      if (ref.read(heartsProvider).isEmpty) {
        state = state.copyWith(status: LessonStatus.outOfHearts);
      }
    }

    EventSensor.instance.emit('answer_submitted', {
      'lesson_id':     state.lesson.id,
      'question_id':   q.id,
      'question_type': q.runtimeType.toString(),
      'skill_tag':     q.skillTag,
      'is_correct':    isCorrect,
      'time_taken_ms': elapsed,
      'cefr_level':    q.cefrLevel,
    });
  }

  void abandonLesson() {
    if (state.status != LessonStatus.inProgress) return;
    final elapsed = _lessonStartedAt != null
        ? DateTime.now().difference(_lessonStartedAt!).inSeconds
        : 0;
    EventSensor.instance.emit('lesson_abandoned', {
      'lesson_id':       state.lesson.id,
      'course_language': state.lesson.courseLanguage,
      'cefr_level':      state.lesson.cefrLevel,
      'skill_tag':       state.lesson.skillTag,
      'progress_pct':    state.progressFraction,
      'question_index':  state.currentIndex,
      'time_seconds':    elapsed,
    });
    state = state.copyWith(status: LessonStatus.abandoned);
  }

  void advance() {
    if (state.isLastQuestion) {
      _completeLesson();
      return;
    }

    state = state.copyWith(
      currentIndex:      state.currentIndex + 1,
      currentAnswerState: AnswerState.unanswered,
      questionStartedAt:  DateTime.now(),
    );
  }

  void _completeLesson() {
    state = state.copyWith(status: LessonStatus.completed);

    final xp = state.lesson.xpReward;

    // Award XP to saga (persists to Firestore) and daily goal.
    ref.read(sagaProvider.notifier).awardLessonXp(
          xp, languageCode: state.lesson.courseLanguage);
    ref.read(dailyGoalProvider.notifier).addXp(xp);

    // Refill hearts on lesson complete (reward for finishing).
    if (state.accuracy >= 0.8) {
      ref.read(heartsProvider.notifier).refillAll();
    }

    EventSensor.instance.emit('lesson_completed', {
      'lesson_id':        state.lesson.id,
      'course_language':  state.lesson.courseLanguage,
      'cefr_level':       state.lesson.cefrLevel,
      'skill_tag':        state.lesson.skillTag,
      'exercise_count':   state.totalQuestions,
      'correct_count':    state.correctCount,
      'accuracy_pct':     state.accuracy,
      'duration_seconds': _lessonStartedAt != null
          ? DateTime.now().difference(_lessonStartedAt!).inSeconds
          : 0,
      'xp_earned':        xp,
    });
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

final lessonProvider =
    NotifierProvider<LessonNotifier, LessonState>(LessonNotifier.new);
