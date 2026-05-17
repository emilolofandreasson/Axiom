import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flick_sdk/flick_sdk.dart';
import '../models/language_level.dart';
import '../models/lesson.dart';
import '../models/question.dart';
import 'question_library_service.dart';

// Thin alias kept for any legacy call sites.
String cefrForXp(int xp) => cefrCodeForXp(xp);

class LessonGenerator {
  LessonGenerator({required this.bridge, this.library});

  final EdgeAiBridge           bridge;
  final QuestionLibraryService? library;

  static const _skills = [
    'vocabulary/greetings',
    'vocabulary/numbers',
    'grammar/verb-conjugation',
    'vocabulary/daily-life',
    'grammar/sentence-structure',
    'vocabulary/food',
    'vocabulary/family',
    'conversation/questions',
  ];

  int _skillIndex = 0;

  Future<Lesson?> generate({
    required String languageCode,
    required String languageName,
    required int    userXp,
    String?         forceSkill,
  }) async {
    final cefr  = cefrCodeForXp(userXp);
    final skill = _resolveSkill(forceSkill);

    // ── Cache-first: try global library before hitting Gemini ────────────────
    if (library != null) {
      final cached = await library!.fetchUnanswered(
        languageCode: languageCode,
        cefrLevel:    cefr,
        skillTag:     skill,
        limit:        4,
      );
      if (cached.length >= 4) {
        debugPrint('[LessonGenerator] cache hit: ${cached.length} questions '
            'from library ($languageCode/$cefr/$skill)');
        return _lessonFromQuestions(
          questions:    cached.take(4).toList(),
          languageCode: languageCode,
          cefr:         cefr,
          skill:        skill,
          userXp:       userXp,
        );
      }
      debugPrint('[LessonGenerator] cache miss ($languageCode/$cefr/$skill), '
          'calling Gemini');
    }

    // ── Cache miss: generate from Gemini ────────────────────────────────────
    final prompt = _buildPrompt(
      languageCode: languageCode,
      languageName: languageName,
      cefr:         cefr,
      skill:        skill,
    );

    try {
      final result = await bridge.complete(InferenceRequest(
        prompt:      prompt,
        maxTokens:   1200,
        temperature: 0.4,
      ));

      if (!result.isSuccess || result.text.isEmpty) {
        debugPrint('[LessonGenerator] inference failed: ${result.error}');
        return null;
      }

      final rawList = _extractJsonList(result.text);
      if (rawList == null) return null;

      // Save the entire batch to the library (fire-and-forget, with UUID attach)
      List<String> globalIds = [];
      if (library != null) {
        globalIds = await library!.saveQuestions(
          rawQuestions: rawList,
          languageCode: languageCode,
          cefrLevel:    cefr,
          skillTag:     skill,
        );
        debugPrint('[LessonGenerator] saved ${globalIds.length} questions to library');
      }

      return _parse(rawList, globalIds, languageCode, cefr, skill, userXp);
    } catch (e) {
      debugPrint('[LessonGenerator] error: $e');
      return null;
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  String _resolveSkill(String? forceSkill) {
    if (forceSkill != null) return forceSkill;
    final dayOffset =
        DateTime.now().difference(DateTime(2025, 1, 1)).inDays;
    final skill = _skills[(dayOffset + _skillIndex) % _skills.length];
    _skillIndex++;
    return skill;
  }

  static const _promptSuffix =
      'Return ONLY a valid JSON array — no markdown fences, no explanation. '
      'Use this exact schema:\n'
      '[\n'
      '  {"type":"multiple_choice","prompt":"...","options":["wrong","wrong","correct","wrong"],"correct_index":2,"hint":null},\n'
      '  {"type":"word_order","prompt":"Arrange into a correct sentence.","translation":"English meaning of the sentence","shuffled_words":["...","...","..."],"correct_order":[1,0,2]},\n'
      '  {"type":"multiple_choice","prompt":"...","options":["wrong","correct","wrong","wrong"],"correct_index":1,"hint":"..."},\n'
      '  {"type":"multiple_choice","prompt":"...","options":["correct","wrong","wrong","wrong"],"correct_index":0,"hint":null}\n'
      ']\n'
      'CRITICAL: correct_index MUST vary across questions — never use the same index for all questions. '
      'Place the correct answer at different positions (0, 1, 2 or 3) for each MC question. '
      'Rules: 3 multiple_choice + 1 word_order. '
      'Correct answer for MC must always be at correct_index (0-based). '
      'shuffled_words for word_order: 3–6 words. '
      'translation for word_order: English meaning of the complete sentence. '
      'correct_order = INTEGER INDICES (0-based positions in shuffled_words) in the correct sequence. '
      'Example: shuffled_words:["café","Yo","tomo"] correct_order:[1,2,0] NOT the words themselves. '
      'Vary vocabulary — do not repeat words from previous exercises.';

  String _buildPrompt({
    required String languageCode,
    required String languageName,
    required String cefr,
    required String skill,
  }) =>
      'Generate exactly 4 language learning exercises for a student learning '
      '$languageName ($languageCode) at CEFR level $cefr. '
      'Skill focus: $skill. '
      'Keep difficulty appropriate for $cefr. '
      '$_promptSuffix';

  List<Map<String, dynamic>>? _extractJsonList(String raw) {
    try {
      final clean = raw
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();
      return (jsonDecode(clean) as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('[LessonGenerator] JSON extract error: $e\nRaw: $raw');
      return null;
    }
  }

  /// Parse a raw JSON list (from Gemini) into a Lesson.
  /// [globalIds] are the UUIDs returned after saving to the library (may be empty).
  Lesson? _parse(
    List<Map<String, dynamic>> list,
    List<String>               globalIds,
    String languageCode,
    String cefr,
    String skill,
    int    userXp,
  ) {
    try {
      final lessonId = 'ai-$languageCode-${DateTime.now().millisecondsSinceEpoch}';
      final questions = <Question>[];

      for (var i = 0; i < list.length; i++) {
        final q    = list[i];
        final qId  = 'q${i + 1}';
        final type = q['type'] as String;
        final gid  = i < globalIds.length ? globalIds[i] : null;

        if (type == 'multiple_choice') {
          var options = (q['options'] as List).cast<String>();
          var correct = (q['correct_index'] as num)
              .toInt()
              .clamp(0, options.length - 1);

          // Shuffle so correct answer isn't predictably at position 0.
          final rng     = Random();
          final indexed = options.asMap().entries.toList()..shuffle(rng);
          options       = indexed.map((e) => e.value).toList();
          correct       = indexed.indexWhere((e) => e.key == correct);

          questions.add(MultipleChoiceQuestion(
            id:           qId,
            lessonId:     lessonId,
            cefrLevel:    cefr,
            skillTag:     skill,
            prompt:       q['prompt'] as String,
            options:      options,
            correctIndex: correct,
            hintText:     q['hint'] as String?,
            globalId:     gid,
          ));

        } else if (type == 'word_order') {
          final words    = (q['shuffled_words'] as List).cast<String>();
          final rawOrder = q['correct_order'] as List;
          var order = rawOrder.first is String
              ? rawOrder.cast<String>().map((w) {
                  final idx = words.indexOf(w);
                  return idx >= 0 ? idx : 0;
                }).toList()
              : rawOrder.map((e) => (e as num).toInt()).toList();
          order = order
              .where((idx) => idx >= 0 && idx < words.length)
              .toList();
          if (order.isEmpty) continue;
          questions.add(WordOrderQuestion(
            id:            qId,
            lessonId:      lessonId,
            cefrLevel:     cefr,
            skillTag:      skill,
            prompt:        q['prompt'] as String? ??
                'Arrange into a correct sentence.',
            shuffledWords: words,
            correctOrder:  order,
            translation:   q['translation'] as String?,
            globalId:      gid,
          ));
        }
      }

      if (questions.isEmpty) return null;

      return Lesson(
        id:               lessonId,
        title:            _titleFor(skill),
        description:      _descFor(skill, languageCode),
        courseLanguage:   languageCode,
        cefrLevel:        cefr,
        skillTag:         skill,
        questions:        questions,
        estimatedMinutes: 5,
        xpReward:         levelForXp(userXp).xpReward,
        // isAiGenerated is derived from id.startsWith('ai-')
      );
    } catch (e) {
      debugPrint('[LessonGenerator] parse error: $e');
      return null;
    }
  }

  /// Build a lesson directly from library-fetched Question objects.
  Lesson _lessonFromQuestions({
    required List<Question> questions,
    required String languageCode,
    required String cefr,
    required String skill,
    required int    userXp,
  }) {
    // 'ai-lib-' prefix so isAiGenerated getter returns true for library lessons.
    final lessonId = 'ai-lib-$languageCode-${DateTime.now().millisecondsSinceEpoch}';
    return Lesson(
      id:               lessonId,
      title:            _titleFor(skill),
      description:      _descFor(skill, languageCode),
      courseLanguage:   languageCode,
      cefrLevel:        cefr,
      skillTag:         skill,
      questions:        questions,
      estimatedMinutes: 5,
      xpReward:         levelForXp(userXp).xpReward,
      // isAiGenerated is derived from id.startsWith('ai-')
    );
  }

  String _titleFor(String skill) => switch (skill) {
    'vocabulary/greetings'         => 'Greetings',
    'vocabulary/numbers'           => 'Numbers',
    'grammar/verb-conjugation'     => 'Verb Forms',
    'vocabulary/daily-life'        => 'Daily Life',
    'grammar/sentence-structure'   => 'Sentence Building',
    'vocabulary/food'              => 'Food & Drink',
    'vocabulary/family'            => 'Family',
    'conversation/questions'       => 'Asking Questions',
    _                              => 'Practice',
  };

  String _descFor(String skill, String lang) => switch (skill) {
    'vocabulary/greetings'       => 'Essential $lang greetings for everyday use.',
    'vocabulary/numbers'         => 'Count and use numbers in $lang.',
    'grammar/verb-conjugation'   => 'Master $lang verb forms.',
    'vocabulary/daily-life'      => 'Words you need every day in $lang.',
    'grammar/sentence-structure' => 'Build correct $lang sentences.',
    'vocabulary/food'            => 'Order food and talk about meals in $lang.',
    'vocabulary/family'          => 'Talk about family in $lang.',
    'conversation/questions'     => 'Ask and answer questions in $lang.',
    _                            => 'Practise your $lang skills.',
  };
}
