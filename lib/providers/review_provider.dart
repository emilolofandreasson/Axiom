import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question.dart';
import 'lesson_provider.dart' show QuestionResult, AnswerState;

/// A saved wrong-answer item for spaced repetition.
class ReviewItem {
  const ReviewItem({
    required this.question,
    required this.savedAt,
    required this.courseLanguage,
    this.reviewCount = 0,
  });

  final MultipleChoiceQuestion question; // only MC questions are reviewable
  final DateTime savedAt;
  final String courseLanguage;
  final int reviewCount;

  ReviewItem copyWith({int? reviewCount}) => ReviewItem(
        question:       question,
        savedAt:        savedAt,
        courseLanguage: courseLanguage,
        reviewCount:    reviewCount ?? this.reviewCount,
      );

  Map<String, dynamic> toJson() => {
        'question': {
          'id':           question.id,
          'lessonId':     question.lessonId,
          'prompt':       question.prompt,
          'options':      question.options,
          'correctIndex': question.correctIndex,
          'cefrLevel':    question.cefrLevel,
          'skillTag':     question.skillTag,
          if (question.hintText != null) 'hintText': question.hintText,
        },
        'courseLanguage': courseLanguage,
        'savedAt':        savedAt.toIso8601String(),
        'reviewCount':    reviewCount,
      };

  factory ReviewItem.fromJson(Map<String, dynamic> json) {
    final q = json['question'] as Map<String, dynamic>;
    return ReviewItem(
      question: MultipleChoiceQuestion(
        id:           q['id']           as String,
        lessonId:     q['lessonId']     as String? ?? '',
        prompt:       q['prompt']       as String,
        options:      List<String>.from(q['options'] as List),
        correctIndex: q['correctIndex'] as int,
        cefrLevel:    q['cefrLevel']    as String? ?? 'A1',
        skillTag:     q['skillTag']     as String? ?? 'vocabulary',
        hintText:     q['hintText']     as String?,
      ),
      courseLanguage: json['courseLanguage'] as String? ?? 'es',
      savedAt:        DateTime.parse(json['savedAt'] as String),
      reviewCount:    json['reviewCount'] as int? ?? 0,
    );
  }
}

class ReviewNotifier extends Notifier<List<ReviewItem>> {
  static const _kKey     = 'review_items';
  static const _kMaxSize = 50; // rolling window

  @override
  List<ReviewItem> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getStringList(_kKey) ?? [];
    state = raw
        .map((s) => ReviewItem.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _kKey, state.map((i) => jsonEncode(i.toJson())).toList());
  }

  /// Add wrong MC questions from a completed lesson.
  Future<void> addWrongAnswers(
      List<QuestionResult> results, String courseLanguage) async {
    final newItems = results
        .where((r) =>
            r.answerState == AnswerState.wrong &&
            r.question is MultipleChoiceQuestion)
        .map((r) => ReviewItem(
              question:       r.question as MultipleChoiceQuestion,
              savedAt:        DateTime.now(),
              courseLanguage: courseLanguage,
            ))
        .toList();

    if (newItems.isEmpty) return;

    // Deduplicate by question id, newest wins.
    final existingIds = {for (final i in state) i.question.id};
    final toAdd = newItems.where((i) => !existingIds.contains(i.question.id)).toList();

    var updated = [...state, ...toAdd];
    // Enforce rolling window — remove oldest if over limit.
    if (updated.length > _kMaxSize) {
      updated = updated.sublist(updated.length - _kMaxSize);
    }

    state = updated;
    await _save();
  }

  /// Mark an item as reviewed; remove after 3 successful reviews.
  Future<void> markReviewed(String questionId, {required bool correct}) async {
    if (!correct) return; // don't advance review count on wrong answers
    final updated = state
        .map((i) => i.question.id == questionId
            ? i.copyWith(reviewCount: i.reviewCount + 1)
            : i)
        .where((i) => i.reviewCount < 3) // graduate after 3 correct reviews
        .toList();
    state = updated;
    await _save();
  }

  Future<void> clear() async {
    state = [];
    await _save();
  }
}

final reviewProvider =
    NotifierProvider<ReviewNotifier, List<ReviewItem>>(ReviewNotifier.new);
