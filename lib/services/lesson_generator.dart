import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flick_sdk/flick_sdk.dart';
import '../models/language_level.dart';
import '../models/lesson.dart';
import '../models/question.dart';

// Thin alias kept for any legacy call sites.
String cefrForXp(int xp) => cefrCodeForXp(xp);

class LessonGenerator {
  LessonGenerator({required this.bridge});
  final EdgeAiBridge bridge;

  // skill tags rotate in order; keeps content varied
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
    required int userXp,
    String? forceSkill,
  }) async {
    final cefr = cefrCodeForXp(userXp);
    final String skill;
    if (forceSkill != null) {
      skill = forceSkill;
    } else {
      // Offset by day so the daily lesson topic rotates each calendar day.
      final dayOffset = DateTime.now().difference(DateTime(2025, 1, 1)).inDays;
      skill = _skills[(dayOffset + _skillIndex) % _skills.length];
      _skillIndex++;
    }

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

      return _parse(result.text, languageCode, cefr, skill, userXp);
    } catch (e) {
      debugPrint('[LessonGenerator] error: $e');
      return null;
    }
  }

  // Static portion of every lesson prompt — compiled once at class definition,
  // never reallocated at runtime.
  static const _promptSuffix =
      'Return ONLY a valid JSON array — no markdown fences, no explanation. '
      'Use this exact schema:\n'
      '[\n'
      '  {"type":"multiple_choice","prompt":"...","options":["...","...","...","..."],"correct_index":0,"hint":null},\n'
      '  {"type":"word_order","prompt":"Arrange into a correct sentence.","shuffled_words":["...","...","..."],"correct_order":[0,1,2]},\n'
      '  {"type":"multiple_choice","prompt":"...","options":["...","...","...","..."],"correct_index":0,"hint":"..."},\n'
      '  {"type":"multiple_choice","prompt":"...","options":["...","...","...","..."],"correct_index":0,"hint":null}\n'
      ']\n'
      'Rules: 3 multiple_choice + 1 word_order. '
      'Correct answer for MC must always be at correct_index. '
      'shuffled_words for word_order: 3–6 words. '
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

  Lesson? _parse(
    String json,
    String languageCode,
    String cefr,
    String skill,
    int userXp,
  ) {
    try {
      // Strip any accidental markdown fences
      final clean = json
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();

      final list = jsonDecode(clean) as List<dynamic>;
      final lessonId = 'ai-$languageCode-${DateTime.now().millisecondsSinceEpoch}';
      final questions = <Question>[];

      for (var i = 0; i < list.length; i++) {
        final q = list[i] as Map<String, dynamic>;
        final qId = 'q${i + 1}';
        final type = q['type'] as String;

        if (type == 'multiple_choice') {
          final options = (q['options'] as List).cast<String>();
          final correct = (q['correct_index'] as num).toInt().clamp(0, options.length - 1);
          questions.add(MultipleChoiceQuestion(
            id:           qId,
            lessonId:     lessonId,
            cefrLevel:    cefr,
            skillTag:     skill,
            prompt:       q['prompt'] as String,
            options:      options,
            correctIndex: correct,
            hintText:     q['hint'] as String?,
          ));
        } else if (type == 'word_order') {
          final words = (q['shuffled_words'] as List).cast<String>();
          final rawOrder = q['correct_order'] as List;
          // Gemini sometimes returns words instead of integer indices — handle both.
          var order = rawOrder.first is String
              ? rawOrder.cast<String>().map((w) {
                  final idx = words.indexOf(w);
                  return idx >= 0 ? idx : 0;
                }).toList()
              : rawOrder.map((e) => (e as num).toInt()).toList();
          // Guard: filter out any out-of-range indices to prevent RangeError.
          order = order.where((idx) => idx >= 0 && idx < words.length).toList();
          if (order.isEmpty) continue;
          questions.add(WordOrderQuestion(
            id:            qId,
            lessonId:      lessonId,
            cefrLevel:     cefr,
            skillTag:      skill,
            prompt:        q['prompt'] as String? ?? 'Arrange into a correct sentence.',
            shuffledWords: words,
            correctOrder:  order,
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
      );
    } catch (e) {
      debugPrint('[LessonGenerator] parse error: $e\nRaw: $json');
      return null;
    }
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

  // XP reward now comes from levelForXp(userXp).xpReward in _parse().
}
