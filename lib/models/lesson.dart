import 'package:flutter/foundation.dart';
import 'question.dart';

enum LessonStatus { idle, inProgress, completed, abandoned }

@immutable
class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.courseLanguage,
    required this.cefrLevel,
    required this.skillTag,
    required this.questions,
    this.estimatedMinutes = 5,
    this.xpReward = 30,
  });

  final String id;
  final String title;
  final String description;
  final String courseLanguage;  // ISO 639-1, e.g. "es"
  final String cefrLevel;
  final String skillTag;
  final List<Question> questions;
  final int estimatedMinutes;
  final int xpReward;
}

@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
  });

  final String id;
  final ChatRole role;
  final String text;
  final DateTime timestamp;
}

enum ChatRole { user, assistant }

// ---------------------------------------------------------------------------
// Seed data — used until the backend lesson API is wired up.
// ---------------------------------------------------------------------------
final kLessonsByLanguage = <String, List<Lesson>>{
  'es': [
    Lesson(
      id:             'es-A2-present-tense-04',
      title:          'Present Tense',
      description:    'Conjugate regular -AR verbs in everyday sentences.',
      courseLanguage: 'es',
      cefrLevel:      'A2',
      skillTag:       'grammar/verb-conjugation',
      estimatedMinutes: 5,
      xpReward:       45,
      questions: const [
        MultipleChoiceQuestion(
          id:           'q1',
          lessonId:     'es-A2-present-tense-04',
          cefrLevel:    'A2',
          skillTag:     'grammar/verb-conjugation',
          prompt:       'Which sentence is correct?',
          options: [
            'Ella habla español muy bien.',
            'Ella hablar español muy bien.',
            'Ella hablamos español muy bien.',
            'Ella hablo español muy bien.',
          ],
          correctIndex: 0,
          hintText:     'Third person singular -AR: drop -ar, add -a.',
        ),
        MultipleChoiceQuestion(
          id:           'q2',
          lessonId:     'es-A2-present-tense-04',
          cefrLevel:    'A2',
          skillTag:     'grammar/verb-conjugation',
          prompt:       '"We work every day" in Spanish is…',
          options: [
            'Trabajamos todos los días.',
            'Trabajan todos los días.',
            'Trabajáis todos los días.',
            'Trabajo todos los días.',
          ],
          correctIndex: 0,
        ),
        WordOrderQuestion(
          id:           'q3',
          lessonId:     'es-A2-present-tense-04',
          cefrLevel:    'A2',
          skillTag:     'grammar/sentence-structure',
          prompt:       'Arrange the words to form a correct sentence.',
          shuffledWords: ['café', 'Yo', 'tomo', 'por', 'la', 'mañana'],
          correctOrder:  [1, 2, 0, 3, 4, 5],
        ),
        MultipleChoiceQuestion(
          id:           'q4',
          lessonId:     'es-A2-present-tense-04',
          cefrLevel:    'A2',
          skillTag:     'vocabulary/daily-life',
          prompt:       'What does "vivir" mean?',
          options: ['to live', 'to leave', 'to love', 'to give'],
          correctIndex: 0,
        ),
        SpeakingQuestion(
          id:           'q5',
          lessonId:     'es-A2-present-tense-04',
          cefrLevel:    'A2',
          skillTag:     'speaking/conversation',
          conversationContext:
              'You are a patient Spanish tutor. The student is A2 level. '
              'Keep corrections short and encouraging. Respond in English.',
          promptText:
              'Tell me one thing you do every morning — in Spanish!',
          hintText: 'Try: "Yo ___ todos los días."',
        ),
      ],
    ),
    Lesson(
      id:             'es-A2-numbers-01',
      title:          'Numbers & Time',
      description:    'Count and tell the time in Spanish.',
      courseLanguage: 'es',
      cefrLevel:      'A2',
      skillTag:       'vocabulary/numbers',
      estimatedMinutes: 5,
      xpReward:       40,
      questions: const [
        MultipleChoiceQuestion(
          id:           'q1',
          lessonId:     'es-A2-numbers-01',
          cefrLevel:    'A2',
          skillTag:     'vocabulary/numbers',
          prompt:       '"Twenty-five" in Spanish is…',
          options: ['Veinticinco', 'Veintitrés', 'Veintiocho', 'Treinta'],
          correctIndex: 0,
        ),
        MultipleChoiceQuestion(
          id:           'q2',
          lessonId:     'es-A2-numbers-01',
          cefrLevel:    'A2',
          skillTag:     'vocabulary/numbers',
          prompt:       'What time is "Son las tres"?',
          options: ['3:00', '13:00', '3:30', '2:00'],
          correctIndex: 0,
        ),
        WordOrderQuestion(
          id:           'q3',
          lessonId:     'es-A2-numbers-01',
          cefrLevel:    'A2',
          skillTag:     'vocabulary/numbers',
          prompt:       'Arrange into a correct sentence.',
          shuffledWords: ['a', 'Voy', 'las', 'trabajo', 'ocho', 'al'],
          correctOrder:  [1, 0, 5, 4, 3, 2],
        ),
        MultipleChoiceQuestion(
          id:           'q4',
          lessonId:     'es-A2-numbers-01',
          cefrLevel:    'A2',
          skillTag:     'vocabulary/numbers',
          prompt:       '"Fifty" in Spanish is…',
          options: ['Cincuenta', 'Cuarenta', 'Sesenta', 'Setenta'],
          correctIndex: 0,
        ),
      ],
    ),
    Lesson(
      id:             'es-A2-family-01',
      title:          'Family',
      description:    'Talk about your family in Spanish.',
      courseLanguage: 'es',
      cefrLevel:      'A2',
      skillTag:       'vocabulary/family',
      estimatedMinutes: 5,
      xpReward:       40,
      questions: const [
        MultipleChoiceQuestion(
          id:           'q1',
          lessonId:     'es-A2-family-01',
          cefrLevel:    'A2',
          skillTag:     'vocabulary/family',
          prompt:       '"Mother" in Spanish is…',
          options: ['Madre', 'Hermana', 'Abuela', 'Tía'],
          correctIndex: 0,
        ),
        MultipleChoiceQuestion(
          id:           'q2',
          lessonId:     'es-A2-family-01',
          cefrLevel:    'A2',
          skillTag:     'vocabulary/family',
          prompt:       '"Brother" in Spanish is…',
          options: ['Hermano', 'Padre', 'Abuelo', 'Hijo'],
          correctIndex: 0,
        ),
        WordOrderQuestion(
          id:           'q3',
          lessonId:     'es-A2-family-01',
          cefrLevel:    'A2',
          skillTag:     'vocabulary/family',
          prompt:       'Arrange into a correct sentence.',
          shuffledWords: ['hermanos', 'Tengo', 'dos'],
          correctOrder:  [1, 0, 2],
        ),
        MultipleChoiceQuestion(
          id:           'q4',
          lessonId:     'es-A2-family-01',
          cefrLevel:    'A2',
          skillTag:     'vocabulary/family',
          prompt:       '"My grandmother" in Spanish is…',
          options: ['Mi abuela', 'Mi madre', 'Mi hermana', 'Mi tía'],
          correctIndex: 0,
        ),
      ],
    ),
    Lesson(
      id:             'es-A2-food-01',
      title:          'Food & Restaurant',
      description:    'Order food and talk about meals.',
      courseLanguage: 'es',
      cefrLevel:      'A2',
      skillTag:       'vocabulary/food',
      estimatedMinutes: 6,
      xpReward:       45,
      questions: const [
        MultipleChoiceQuestion(
          id:           'q1',
          lessonId:     'es-A2-food-01',
          cefrLevel:    'A2',
          skillTag:     'vocabulary/food',
          prompt:       '"I would like a coffee" in Spanish is…',
          options: ['Quisiera un café', 'Quiero un té', 'Me gusta el café', 'Tomo agua'],
          correctIndex: 0,
        ),
        MultipleChoiceQuestion(
          id:           'q2',
          lessonId:     'es-A2-food-01',
          cefrLevel:    'A2',
          skillTag:     'vocabulary/food',
          prompt:       '"The bill, please" in Spanish is…',
          options: ['La cuenta, por favor', 'El menú, por favor', 'Una mesa, por favor', 'El agua, por favor'],
          correctIndex: 0,
        ),
        WordOrderQuestion(
          id:           'q3',
          lessonId:     'es-A2-food-01',
          cefrLevel:    'A2',
          skillTag:     'vocabulary/food',
          prompt:       'Arrange into a correct sentence.',
          shuffledWords: ['hambre', 'Tengo', 'mucha'],
          correctOrder:  [1, 0, 2],
        ),
        MultipleChoiceQuestion(
          id:           'q4',
          lessonId:     'es-A2-food-01',
          cefrLevel:    'A2',
          skillTag:     'vocabulary/food',
          prompt:       '"Breakfast" in Spanish is…',
          options: ['Desayuno', 'Almuerzo', 'Cena', 'Merienda'],
          correctIndex: 0,
        ),
      ],
    ),
  ],
};

Lesson get kSeedLesson => kLessonsByLanguage['es']!.first;
