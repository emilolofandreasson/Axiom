import 'dart:async' show unawaited;
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flick_sdk/flick_sdk.dart';

import '../config/env.dart';
import '../models/language_level.dart';
import 'api_key_service.dart';
import 'question_library_service.dart';

/// Generates questions via the user's own Gemini API key and saves them
/// to global_questions in Supabase. All calls are fire-and-forget.
class QuestionContributorService {
  QuestionContributorService({required this.library});

  final QuestionLibraryService library;

  static const _questionsPerBatch = 8;

  /// Fire-and-forget: called after lesson completion.
  /// Loads the user's Gemini key from secure storage, then generates
  /// [_questionsPerBatch] questions and saves them to global_questions.
  void contributeAfterLesson({
    required String languageCode,
    required String languageName,
    required int    userXp,
    required String skillTag,
  }) {
    unawaited(_runContribution(
      languageCode: languageCode,
      languageName: languageName,
      userXp:       userXp,
      skillTag:     skillTag,
    ));
  }

  Future<void> _runContribution({
    required String languageCode,
    required String languageName,
    required int    userXp,
    required String skillTag,
  }) async {
    // Load key from secure storage — skip silently if not set.
    final geminiApiKey = await ApiKeyService().loadKey();
    if (geminiApiKey == null || geminiApiKey.isEmpty) return;

    final cefrLevel = cefrCodeForXp(userXp);

    try {
      final bridge = GeminiBridge(
        apiKey:   geminiApiKey,
        proxyUrl: Env.proxyUrl.isNotEmpty ? Env.proxyUrl : null,
      );

      final prompt = _buildPrompt(
        languageCode: languageCode,
        languageName: languageName,
        cefrLevel:    cefrLevel,
        skillTag:     skillTag,
        count:        _questionsPerBatch,
      );

      final result = await bridge.complete(InferenceRequest(
        prompt:      prompt,
        maxTokens:   2400,
        temperature: 0.7,
      ));

      if (!result.isSuccess || result.text.isEmpty) {
        debugPrint('[Contributor] Gemini failed: ${result.error}');
        return;
      }

      final questions = _parseQuestions(result.text);
      if (questions.isEmpty) {
        debugPrint('[Contributor] No parseable questions in response');
        return;
      }

      final ids = await library.saveQuestions(
        rawQuestions: questions,
        languageCode: languageCode,
        cefrLevel:    cefrLevel,
        skillTag:     skillTag,
      );

      debugPrint('[Contributor] Saved ${ids.length} questions to global_questions '
          '($languageCode/$cefrLevel/$skillTag)');
    } catch (e) {
      // Never surface errors to the user — this is background work.
      debugPrint('[Contributor] Error: $e');
    }
  }

  String _buildPrompt({
    required String languageCode,
    required String languageName,
    required String cefrLevel,
    required String skillTag,
    required int    count,
  }) =>
      '''
Generate $count language learning questions for the following parameters:
- Target language: $languageName ($languageCode)
- CEFR level: $cefrLevel
- Skill: $skillTag

Return ONLY a valid JSON array. Each element must be one of these types:

Type A — multiple_choice:
{
  "type": "multiple_choice",
  "prompt": "<question in English>",
  "options": ["<opt1>", "<opt2>", "<opt3>", "<opt4>"],
  "correct_index": <0-3>,
  "hint": "<optional short hint in English>"
}

Type B — word_order:
{
  "type": "word_order",
  "prompt": "Arrange into a correct sentence.",
  "shuffled_words": ["<word1>", "<word2>", "<word3>", "<word4>", "<word5>"],
  "correct_order": [<index0>, <index1>, <index2>, <index3>, <index4>]
}

Rules:
- Mix both types (roughly 60% multiple_choice, 40% word_order)
- All questions must be appropriate for $cefrLevel learners
- Make questions varied — do not repeat the same vocabulary
- For multiple_choice: wrong options must be plausible but clearly incorrect
- For word_order: shuffled_words must be in a random order, correct_order contains the indices that form the correct sentence
- Return ONLY the JSON array, no markdown, no explanation
''';

  List<Map<String, dynamic>> _parseQuestions(String raw) {
    try {
      // Strip markdown code fences if present
      var text = raw.trim();
      if (text.startsWith('```')) {
        text = text.replaceAll(RegExp(r'```[a-z]*\n?'), '').trim();
      }

      final parsed = jsonDecode(text);
      if (parsed is! List) return [];

      return parsed
          .whereType<Map<String, dynamic>>()
          .where((q) => q['type'] == 'multiple_choice' || q['type'] == 'word_order')
          .toList();
    } catch (e) {
      debugPrint('[Contributor] JSON parse error: $e');
      return [];
    }
  }
}
