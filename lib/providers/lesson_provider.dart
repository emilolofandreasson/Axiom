import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flick_sdk/flick_sdk.dart';
import '../models/lesson.dart';
import '../models/question.dart';

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
    this.currentIndex = 0,
    this.results = const [],
    this.status = LessonStatus.idle,
    this.currentAnswerState = AnswerState.unanswered,
    this.questionStartedAt,
  });

  final Lesson lesson;
  final int currentIndex;
  final List<QuestionResult> results;
  final LessonStatus status;
  final AnswerState currentAnswerState;
  final DateTime? questionStartedAt;

  Question get currentQuestion => lesson.questions[currentIndex];
  bool get isLastQuestion => currentIndex >= lesson.questions.length - 1;
  int get totalQuestions => lesson.questions.length;
  double get progressFraction => currentIndex / totalQuestions;

  int get correctCount =>
      results.where((r) => r.answerState == AnswerState.correct).length;

  double get accuracy =>
      results.isEmpty ? 0 : correctCount / results.length;

  LessonState copyWith({
    int? currentIndex,
    List<QuestionResult>? results,
    LessonStatus? status,
    AnswerState? currentAnswerState,
    DateTime? questionStartedAt,
  }) =>
      LessonState(
        lesson:               lesson,
        currentIndex:         currentIndex         ?? this.currentIndex,
        results:              results              ?? this.results,
        status:               status               ?? this.status,
        currentAnswerState:   currentAnswerState   ?? this.currentAnswerState,
        questionStartedAt:    questionStartedAt    ?? this.questionStartedAt,
      );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class LessonNotifier extends Notifier<LessonState> {
  @override
  LessonState build() => LessonState(
        lesson: kSeedLesson,
        status: LessonStatus.idle,
      );

  void startLesson() {
    state = state.copyWith(
      status:            LessonStatus.inProgress,
      currentIndex:      0,
      results:           [],
      questionStartedAt: DateTime.now(),
    );

    EventSensor.instance.emit('session_started', {
      'app_id':   'axiom',
      'platform': 'web',
    });
    EventSensor.instance.emit('lesson_started', {
      'lesson_id':      state.lesson.id,
      'cefr_level':     state.lesson.cefrLevel,
      'skill_tag':      state.lesson.skillTag,
      'question_count': state.totalQuestions,
    });
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

    EventSensor.instance.emit('lesson_completed', {
      'lesson_id':       state.lesson.id,
      'course_language': state.lesson.courseLanguage,
      'cefr_level':      state.lesson.cefrLevel,
      'skill_tag':       state.lesson.skillTag,
      'exercise_count':  state.totalQuestions,
      'correct_count':   state.correctCount,
      'accuracy_pct':    state.accuracy,
      'duration_seconds': 0,
      'xp_earned':       state.lesson.xpReward,
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
