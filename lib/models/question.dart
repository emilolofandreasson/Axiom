import 'package:flutter/foundation.dart';

/// Discriminated union — one sealed type per exercise variant.
/// Add new variants here; the compiler forces exhaustive switches everywhere.
@immutable
sealed class Question {
  const Question({
    required this.id,
    required this.lessonId,
    required this.cefrLevel,
    required this.skillTag,
    this.hintText,
  });

  final String id;
  final String lessonId;
  final String cefrLevel;  // A1 | A2 | B1 | B2 | C1
  final String skillTag;   // e.g. "grammar/verb-conjugation"
  final String? hintText;
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
  });

  final String prompt;
  final List<String> options;
  final int correctIndex;

  String get correctAnswer => options[correctIndex];
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
  });

  final String prompt;           // "Put these words in order:"
  final List<String> shuffledWords;
  final List<int> correctOrder;  // indices into shuffledWords

  List<String> get correctSentence =>
      correctOrder.map((i) => shuffledWords[i]).toList();
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
  });

  final String conversationContext;  // fed to edge SLM as system prompt
  final String promptText;           // shown to user
}
