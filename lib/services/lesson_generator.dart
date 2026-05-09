import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flick_sdk/flick_sdk.dart';
import '../models/lesson.dart';
import '../models/question.dart';

String cefrForXp(int xp) {
  if (xp < 100)  return 'A1';
  if (xp < 300)  return 'A2';
  if (xp < 700)  return 'B1';
  if (xp < 1500) return 'B2';
  return 'C1';
}

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
  }) async {
    final cefr  = cefrForXp(userXp);
    final skill = _skills[_skillIndex % _skills.length];
    _skillIndex++;

    final prompt = _buildPrompt(
      languageCode: languageCode,
      languageName: languageName,
      cefr:         cefr,
      skill:        skill,
    );

    try {
      final result = await bridge.complete(InferenceRequest(
        prompt:      prompt,
        maxTokens:   800,
        temperature: 0.4,
      ));

      if (!result.isSuccess || result.text.isEmpty) {
        debugPrint('[LessonGenerator] inference failed: ${result.error}');
        return null;
      }

      return _parse(result.text, languageCode, cefr, skill);
    } catch (e) {
      debugPrint('[LessonGenerator] error: $e');
      return null;
    }
  }

  String _buildPrompt({
    required String languageCode,
    required String languageName,
    required String cefr,
    required String skill,
  }) =>
      'Generate exactly 4 language learning exercises for a student learning '
      '$languageName ($languageCode) at CEFR level $cefr. '
      'Skill focus: $skill. '
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
      'shuffled_words for word_order: 3–6 words, correct_order = indices in correct sequence. '
      'Keep difficulty appropriate for $cefr. '
      'Vary vocabulary — do not repeat words from previous exercises.';

  Lesson? _parse(
    String json,
    String languageCode,
    String cefr,
    String skill,
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
          final order = (q['correct_order'] as List)
              .map((e) => (e as num).toInt())
              .toList();
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
        xpReward:         _xpFor(cefr),
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

  int _xpFor(String cefr) => switch (cefr) {
    'A1' => 30,
    'A2' => 40,
    'B1' => 55,
    'B2' => 70,
    _    => 90,
  };
}
