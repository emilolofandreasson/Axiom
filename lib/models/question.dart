import 'package:flutter/foundation.dart';

/// Discriminated union — one sealed type per exercise variant.
@immutable
sealed class Question {
  const Question({
    required this.id,
    required this.lessonId,
    required this.cefrLevel,
    required this.skillTag,
    this.hintText,
    this.globalId,
  });

  final String  id;
  final String  lessonId;
  final String  cefrLevel;  // A1 | A2 | B1 | B2 | C1
  final String  skillTag;   // e.g. "grammar/verb-conjugation"
  final String? hintText;
  /// UUID in global_questions table. Null for freshly-generated questions
  /// that have not yet been persisted to the library.
  final String? globalId;
}

/// Translate sentence → pick one of 4 options.
@immutable
final class MultipleChoiceQuestion extends Question {
  const MultipleChoiceQuestion({
    required super.id,
    required super.lessonId,
    required super.cefrLevel,
    required super.skillTag,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    super.hintText,
    super.globalId,
  });

  final String       prompt;
  final List<String> options;
  final int          correctIndex;

  String get correctAnswer => options[correctIndex];

  MultipleChoiceQuestion withGlobalId(String id) => MultipleChoiceQuestion(
    id:           this.id,
    lessonId:     lessonId,
    cefrLevel:    cefrLevel,
    skillTag:     skillTag,
    prompt:       prompt,
    options:      options,
    correctIndex: correctIndex,
    hintText:     hintText,
    globalId:     id,
  );
}

/// Drag words into the correct sentence order.
@immutable
final class WordOrderQuestion extends Question {
  const WordOrderQuestion({
    required super.id,
    required super.lessonId,
    required super.cefrLevel,
    required super.skillTag,
    required this.prompt,
    required this.shuffledWords,
    required this.correctOrder,
    super.hintText,
    super.globalId,
  });

  final String       prompt;
  final List<String> shuffledWords;
  final List<int>    correctOrder;

  List<String> get correctSentence =>
      correctOrder.map((i) => shuffledWords[i]).toList();

  WordOrderQuestion withGlobalId(String id) => WordOrderQuestion(
    id:            this.id,
    lessonId:      lessonId,
    cefrLevel:     cefrLevel,
    skillTag:      skillTag,
    prompt:        prompt,
    shuffledWords: shuffledWords,
    correctOrder:  correctOrder,
    hintText:      hintText,
    globalId:      id,
  );
}

/// Open speaking / typing question answered via AI chat.
@immutable
final class SpeakingQuestion extends Question {
  const SpeakingQuestion({
    required super.id,
    required super.lessonId,
    required super.cefrLevel,
    required super.skillTag,
    required this.conversationContext,
    required this.promptText,
    super.hintText,
    super.globalId,
  });

  final String conversationContext;
  final String promptText;
}
