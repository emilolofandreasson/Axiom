import 'dart:async' show unawaited;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/question.dart';

/// Manages the Global Question Library in Supabase.
///
/// Responsibilities:
///  • fetch_unanswered_questions RPC — cache-first serving
///  • Batch INSERT of Gemini-generated questions
///  • Fire-and-forget INSERT into user_progress for calibration
class QuestionLibraryService {
  SupabaseClient get _db  => Supabase.instance.client;
  String?        get _uid => _db.auth.currentUser?.id;

  // ── Read ────────────────────────────────────────────────────────────────────

  /// Returns up to [limit] questions for [languageCode]/[cefrLevel]/[skillTag]
  /// that [userId] (defaults to current user) has not yet answered.
  /// Returns [] on any error so the caller can fall back to Gemini.
  Future<List<Question>> fetchUnanswered({
    required String languageCode,
    required String cefrLevel,
    required String skillTag,
    int limit = 4,
  }) async {
    final uid = _uid;
    if (uid == null) return [];

    try {
      final rows = await _db.rpc('fetch_unanswered_questions', params: {
        'p_user_id':    uid,
        'p_language':   languageCode,
        'p_cefr_level': cefrLevel,
        'p_skill_tag':  skillTag,
        'p_limit':      limit,
      });

      return (rows as List)
          .map((r) => _rowToQuestion(r as Map<String, dynamic>))
          .whereType<Question>()
          .toList();
    } catch (e) {
      debugPrint('[QuestionLibrary] fetchUnanswered error: $e');
      return [];
    }
  }

  /// Fetches up to [limit] non-answered questions for a Path level.
  /// Filters by language + CEFR only — no skill_tag constraint.
  /// Returns empty list on error or if bank has no content for this level.
  Future<List<Question>> fetchForLevel({
    required String languageCode,
    required String cefrLevel,
    int limit = 5,
  }) async {
    try {
      final uid  = _db.auth.currentUser?.id;
      final rows = await _db.rpc('fetch_questions_for_level', params: {
        'p_user_id':    uid,
        'p_language':   languageCode,
        'p_cefr_level': cefrLevel,
        'p_limit':      limit,
      });
      if (rows == null) return [];
      return (rows as List)
          .map((r) => _rowToQuestion(r as Map<String, dynamic>))
          .whereType<Question>()
          .toList();
    } catch (e) {
      debugPrint('[QuestionLibrary] fetchForLevel error: $e');
      return [];
    }
  }

  // ── Write ───────────────────────────────────────────────────────────────────

  /// Saves a batch of JSON questions (Gemini output format) to the library.
  /// Returns the assigned UUIDs in insertion order. Returns [] on error.
  Future<List<String>> saveQuestions({
    required List<Map<String, dynamic>> rawQuestions,
    required String languageCode,
    required String cefrLevel,
    required String skillTag,
  }) async {
    final uid = _uid;
    if (uid == null || rawQuestions.isEmpty) return [];

    try {
      // created_by is set server-side via DEFAULT auth.uid() + BEFORE INSERT trigger.
      // Never sent from the client to prevent spoofing.
      final rows = rawQuestions.map((q) => {
        'language':  languageCode,
        'cefr_level': cefrLevel,
        'skill_tag':  skillTag,
        'type':       q['type'] as String,
        'content':    q,
      }).toList();

      final result = await _db
          .from('global_questions')
          .insert(rows)
          .select('id');

      return (result as List).map((r) => r['id'] as String).toList();
    } catch (e) {
      debugPrint('[QuestionLibrary] saveQuestions error: $e');
      return [];
    }
  }

  /// Fire-and-forget: records one answer in user_progress.
  /// Only called when [question.globalId] is non-null.
  void recordAnswer({
    required String questionId,
    required bool   isCorrect,
    String?         lessonId,
  }) {
    final uid = _uid;
    if (uid == null) return;
    unawaited(_db.from('user_progress').insert({
      'user_id':     uid,
      'question_id': questionId,
      'is_correct':  isCorrect,
      'lesson_id':   lessonId,
    }));
  }

  // ── Conversion ──────────────────────────────────────────────────────────────

  Question? _rowToQuestion(Map<String, dynamic> row) {
    try {
      final globalId  = row['id']        as String;
      final cefrLevel = row['cefr_level'] as String;
      final skillTag  = row['skill_tag']  as String;
      final content   = row['content']    as Map<String, dynamic>;
      final type      = row['type']       as String? ?? content['type'] as String;
      final lessonId  = 'lib-${row['language']}-${globalId.substring(0, 8)}';
      final shortId   = globalId.substring(0, 8);

      if (type == 'multiple_choice') {
        var options  = (content['options'] as List).cast<String>();
        var correct  = (content['correct_index'] as num).toInt()
            .clamp(0, options.length - 1);

        // Shuffle so correct answer isn't predictably at position 0
        final rng     = Random();
        final indexed = options.asMap().entries.toList()..shuffle(rng);
        options       = indexed.map((e) => e.value).toList();
        correct       = indexed.indexWhere((e) => e.key == correct);

        return MultipleChoiceQuestion(
          id:           shortId,
          lessonId:     lessonId,
          cefrLevel:    cefrLevel,
          skillTag:     skillTag,
          prompt:       content['prompt'] as String,
          options:      options,
          correctIndex: correct,
          hintText:     content['hint'] as String?,
          globalId:     globalId,
        );

      } else if (type == 'word_order') {
        final words    = (content['shuffled_words'] as List).cast<String>();
        final rawOrder = content['correct_order'] as List;
        var order = rawOrder.first is String
            ? rawOrder.cast<String>().map((w) {
                final idx = words.indexOf(w);
                return idx >= 0 ? idx : 0;
              }).toList()
            : rawOrder.map((e) => (e as num).toInt()).toList();
        order = order
            .where((idx) => idx >= 0 && idx < words.length)
            .toList();
        if (order.isEmpty) return null;

        return WordOrderQuestion(
          id:            shortId,
          lessonId:      lessonId,
          cefrLevel:     cefrLevel,
          skillTag:      skillTag,
          prompt:        content['prompt'] as String? ??
              'Arrange into a correct sentence.',
          shuffledWords: words,
          correctOrder:  order,
          globalId:      globalId,
        );
      }
    } catch (e) {
      debugPrint('[QuestionLibrary] row parse error: $e\nRow: $row');
    }
    return null;
  }
}
