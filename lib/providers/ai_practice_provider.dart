import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flick_sdk/flick_sdk.dart';
import '../models/language_level.dart';
import '../models/question.dart';
import '../providers/daily_goal_provider.dart';
import '../providers/language_provider.dart';
import '../providers/saga_provider.dart';
import '../providers/lesson_provider.dart' show AnswerState, QuestionResult;
import '../main.dart' show lessonGenerator;

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

enum AiPracticeStatus { idle, generating, inProgress, completed, failed }

class AiPracticeState {
  const AiPracticeState({
    this.status = AiPracticeStatus.idle,
    this.topicName,
    this.skillTag,
    this.questions = const [],
    this.currentIndex = 0,
    this.results = const [],
    this.currentAnswerState = AnswerState.unanswered,
  });

  final AiPracticeStatus     status;
  final String?              topicName;
  final String?              skillTag;
  final List<Question>       questions;
  final int                  currentIndex;
  final List<QuestionResult> results;
  final AnswerState          currentAnswerState;

  Question? get currentQuestion =>
      questions.isEmpty ? null : questions[currentIndex];
  bool get isLastQuestion =>
      questions.isEmpty || currentIndex >= questions.length - 1;
  int get totalQuestions => questions.length;
  int get correctCount =>
      results.where((r) => r.answerState == AnswerState.correct).length;
  double get accuracy =>
      results.isEmpty ? 0.0 : correctCount / results.length;

  AiPracticeState copyWith({
    AiPracticeStatus?     status,
    String?               topicName,
    String?               skillTag,
    List<Question>?       questions,
    int?                  currentIndex,
    List<QuestionResult>? results,
    AnswerState?          currentAnswerState,
  }) =>
      AiPracticeState(
        status:             status             ?? this.status,
        topicName:          topicName          ?? this.topicName,
        skillTag:           skillTag           ?? this.skillTag,
        questions:          questions          ?? this.questions,
        currentIndex:       currentIndex       ?? this.currentIndex,
        results:            results            ?? this.results,
        currentAnswerState: currentAnswerState ?? this.currentAnswerState,
      );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class AiPracticeNotifier extends Notifier<AiPracticeState> {
  @override
  AiPracticeState build() => const AiPracticeState();

  DateTime? _practiceStartedAt;

  Future<void> generate(String topicName, String skillTag) async {
    final language = ref.read(languageProvider);
    final saga     = ref.read(sagaProvider);
    _practiceStartedAt = DateTime.now();

    state = AiPracticeState(
      status:    AiPracticeStatus.generating,
      topicName: topicName,
      skillTag:  skillTag,
    );

    EventSensor.instance.emit('ai_practice_started', {
      'topic_name':      topicName,
      'skill_tag':       skillTag,
      'skill_category':  skillTag.split('/').first,
      'course_language': language.code,
      'cefr_level':      cefrCodeForXp(saga.xpForLanguage(language.code)),
      'hour_of_day':     _practiceStartedAt!.hour,
      'day_of_week':     _practiceStartedAt!.weekday,
    });

    final lesson = await lessonGenerator.generate(
      languageCode: language.code,
      languageName: language.name,
      userXp:       saga.xpForLanguage(language.code),
      forceSkill:   skillTag,
    );

    if (lesson == null || lesson.questions.isEmpty) {
      state = state.copyWith(status: AiPracticeStatus.failed);
      return;
    }

    state = state.copyWith(
      status:    AiPracticeStatus.inProgress,
      questions: lesson.questions,
    );
  }

  void submitAnswer(Object answer) {
    final q = state.currentQuestion;
    if (q == null) return;

    final isCorrect = switch (q) {
      MultipleChoiceQuestion mc =>
          answer is int && answer == mc.correctIndex,
      WordOrderQuestion wo =>
          answer is List<String> && _listEquals(answer, wo.correctSentence),
      SpeakingQuestion _ => true,
    };

    state = state.copyWith(
      currentAnswerState: isCorrect ? AnswerState.correct : AnswerState.wrong,
      results: [
        ...state.results,
        QuestionResult(
          question:    q,
          answerState: isCorrect ? AnswerState.correct : AnswerState.wrong,
          userAnswer:  answer,
        ),
      ],
    );

  }

  void advance() {
    if (state.isLastQuestion) {
      state = state.copyWith(status: AiPracticeStatus.completed);
      _awardXp();
    } else {
      state = state.copyWith(
        currentIndex:       state.currentIndex + 1,
        currentAnswerState: AnswerState.unanswered,
      );
    }
  }

  void _awardXp() {
    final language = ref.read(languageProvider);
    final saga     = ref.read(sagaProvider);
    final xp       = levelForXp(saga.xpForLanguage(language.code)).xpReward;
    ref.read(sagaProvider.notifier).awardLessonXp(xp, languageCode: language.code);
    ref.read(dailyGoalProvider.notifier).addXp(xp);

    final elapsed = _practiceStartedAt != null
        ? DateTime.now().difference(_practiceStartedAt!).inSeconds
        : 0;
    EventSensor.instance.emit('ai_practice_completed', {
      'topic_name':      state.topicName,
      'skill_tag':       state.skillTag,
      'skill_category':  state.skillTag?.split('/').first,
      'course_language': language.code,
      'question_count':  state.totalQuestions,
      'correct_count':   state.correctCount,
      'accuracy_pct':    state.accuracy,
      'duration_seconds':elapsed,
      'xp_earned':       xp,
    });
  }

  void reset() => state = const AiPracticeState();

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

final aiPracticeProvider =
    NotifierProvider<AiPracticeNotifier, AiPracticeState>(
        AiPracticeNotifier.new);
