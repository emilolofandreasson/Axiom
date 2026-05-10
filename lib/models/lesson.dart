import 'package:flutter/foundation.dart';
import 'question.dart';

enum LessonStatus { idle, inProgress, completed, abandoned, outOfHearts }

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

  bool get isAiGenerated => id.startsWith('ai-');
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
  'fr': [
    Lesson(
      id:               'fr-A1-greetings-01',
      title:            'Greetings',
      description:      'Learn basic French greetings and introductions.',
      courseLanguage:   'fr',
      cefrLevel:        'A1',
      skillTag:         'vocabulary/greetings',
      estimatedMinutes: 5,
      xpReward:         35,
      questions: const [
        MultipleChoiceQuestion(
          id: 'q1', lessonId: 'fr-A1-greetings-01',
          cefrLevel: 'A1', skillTag: 'vocabulary/greetings',
          prompt: '"Hello" in French is…',
          options: ['Bonjour', 'Bonsoir', 'Au revoir', 'Merci'],
          correctIndex: 0,
        ),
        MultipleChoiceQuestion(
          id: 'q2', lessonId: 'fr-A1-greetings-01',
          cefrLevel: 'A1', skillTag: 'vocabulary/greetings',
          prompt: '"Thank you" in French is…',
          options: ['Merci', 'S\'il vous plaît', 'Bonjour', 'De rien'],
          correctIndex: 0,
        ),
        WordOrderQuestion(
          id: 'q3', lessonId: 'fr-A1-greetings-01',
          cefrLevel: 'A1', skillTag: 'grammar/sentence-structure',
          prompt: 'Arrange into a correct sentence.',
          shuffledWords: ['m\'appelle', 'Je', 'Marie'],
          correctOrder:  [1, 0, 2],
        ),
        MultipleChoiceQuestion(
          id: 'q4', lessonId: 'fr-A1-greetings-01',
          cefrLevel: 'A1', skillTag: 'vocabulary/greetings',
          prompt: '"Goodbye" in French is…',
          options: ['Au revoir', 'Bonjour', 'Merci', 'Bonsoir'],
          correctIndex: 0,
        ),
      ],
    ),
    Lesson(
      id:               'fr-A1-numbers-01',
      title:            'Numbers',
      description:      'Count and use numbers in French.',
      courseLanguage:   'fr',
      cefrLevel:        'A1',
      skillTag:         'vocabulary/numbers',
      estimatedMinutes: 5,
      xpReward:         35,
      questions: const [
        MultipleChoiceQuestion(
          id: 'q1', lessonId: 'fr-A1-numbers-01',
          cefrLevel: 'A1', skillTag: 'vocabulary/numbers',
          prompt: '"Five" in French is…',
          options: ['Cinq', 'Six', 'Sept', 'Quatre'],
          correctIndex: 0,
        ),
        MultipleChoiceQuestion(
          id: 'q2', lessonId: 'fr-A1-numbers-01',
          cefrLevel: 'A1', skillTag: 'vocabulary/numbers',
          prompt: '"Twenty" in French is…',
          options: ['Vingt', 'Dix', 'Trente', 'Quinze'],
          correctIndex: 0,
        ),
        WordOrderQuestion(
          id: 'q3', lessonId: 'fr-A1-numbers-01',
          cefrLevel: 'A1', skillTag: 'grammar/sentence-structure',
          prompt: 'Arrange into a correct sentence.',
          shuffledWords: ['ans', 'J\'ai', 'vingt'],
          correctOrder:  [1, 2, 0],
        ),
        MultipleChoiceQuestion(
          id: 'q4', lessonId: 'fr-A1-numbers-01',
          cefrLevel: 'A1', skillTag: 'vocabulary/numbers',
          prompt: '"How old are you?" in French is…',
          options: ['Quel âge as-tu?', 'Comment t\'appelles-tu?', 'Tu vas bien?', 'D\'où viens-tu?'],
          correctIndex: 0,
        ),
      ],
    ),
    Lesson(
      id:               'fr-A1-family-01',
      title:            'Family',
      description:      'Talk about your family in French.',
      courseLanguage:   'fr',
      cefrLevel:        'A1',
      skillTag:         'vocabulary/family',
      estimatedMinutes: 5,
      xpReward:         35,
      questions: const [
        MultipleChoiceQuestion(
          id: 'q1', lessonId: 'fr-A1-family-01',
          cefrLevel: 'A1', skillTag: 'vocabulary/family',
          prompt: '"Mother" in French is…',
          options: ['Mère', 'Père', 'Sœur', 'Frère'],
          correctIndex: 0,
        ),
        MultipleChoiceQuestion(
          id: 'q2', lessonId: 'fr-A1-family-01',
          cefrLevel: 'A1', skillTag: 'vocabulary/family',
          prompt: '"Brother" in French is…',
          options: ['Frère', 'Sœur', 'Père', 'Fils'],
          correctIndex: 0,
        ),
        WordOrderQuestion(
          id: 'q3', lessonId: 'fr-A1-family-01',
          cefrLevel: 'A1', skillTag: 'grammar/sentence-structure',
          prompt: 'Arrange into a correct sentence.',
          shuffledWords: ['une', 'J\'ai', 'sœur'],
          correctOrder:  [1, 0, 2],
        ),
        MultipleChoiceQuestion(
          id: 'q4', lessonId: 'fr-A1-family-01',
          cefrLevel: 'A1', skillTag: 'vocabulary/family',
          prompt: '"My father" in French is…',
          options: ['Mon père', 'Ma mère', 'Mon frère', 'Ma sœur'],
          correctIndex: 0,
        ),
      ],
    ),
  ],
  'de': [
    Lesson(
      id:               'de-A1-greetings-01',
      title:            'Greetings',
      description:      'Learn basic German greetings and introductions.',
      courseLanguage:   'de',
      cefrLevel:        'A1',
      skillTag:         'vocabulary/greetings',
      estimatedMinutes: 5,
      xpReward:         35,
      questions: const [
        MultipleChoiceQuestion(
          id: 'q1', lessonId: 'de-A1-greetings-01',
          cefrLevel: 'A1', skillTag: 'vocabulary/greetings',
          prompt: '"Hello" in German is…',
          options: ['Hallo', 'Auf Wiedersehen', 'Danke', 'Bitte'],
          correctIndex: 0,
        ),
        MultipleChoiceQuestion(
          id: 'q2', lessonId: 'de-A1-greetings-01',
          cefrLevel: 'A1', skillTag: 'vocabulary/greetings',
          prompt: '"Thank you" in German is…',
          options: ['Danke', 'Bitte', 'Hallo', 'Tschüs'],
          correctIndex: 0,
        ),
        WordOrderQuestion(
          id: 'q3', lessonId: 'de-A1-greetings-01',
          cefrLevel: 'A1', skillTag: 'grammar/sentence-structure',
          prompt: 'Arrange into a correct sentence.',
          shuffledWords: ['heiße', 'Ich', 'Marie'],
          correctOrder:  [1, 0, 2],
        ),
        MultipleChoiceQuestion(
          id: 'q4', lessonId: 'de-A1-greetings-01',
          cefrLevel: 'A1', skillTag: 'vocabulary/greetings',
          prompt: '"Goodbye" in German is…',
          options: ['Auf Wiedersehen', 'Hallo', 'Danke', 'Guten Morgen'],
          correctIndex: 0,
        ),
      ],
    ),
    Lesson(
      id:               'de-A1-numbers-01',
      title:            'Numbers',
      description:      'Count and use numbers in German.',
      courseLanguage:   'de',
      cefrLevel:        'A1',
      skillTag:         'vocabulary/numbers',
      estimatedMinutes: 5,
      xpReward:         35,
      questions: const [
        MultipleChoiceQuestion(
          id: 'q1', lessonId: 'de-A1-numbers-01',
          cefrLevel: 'A1', skillTag: 'vocabulary/numbers',
          prompt: '"Five" in German is…',
          options: ['Fünf', 'Sechs', 'Sieben', 'Vier'],
          correctIndex: 0,
        ),
        MultipleChoiceQuestion(
          id: 'q2', lessonId: 'de-A1-numbers-01',
          cefrLevel: 'A1', skillTag: 'vocabulary/numbers',
          prompt: '"Twenty" in German is…',
          options: ['Zwanzig', 'Zehn', 'Dreißig', 'Fünfzehn'],
          correctIndex: 0,
        ),
        WordOrderQuestion(
          id: 'q3', lessonId: 'de-A1-numbers-01',
          cefrLevel: 'A1', skillTag: 'grammar/sentence-structure',
          prompt: 'Arrange into a correct sentence.',
          shuffledWords: ['Jahre', 'Ich', 'zwanzig', 'bin', 'alt'],
          correctOrder:  [1, 3, 2, 0, 4],
        ),
        MultipleChoiceQuestion(
          id: 'q4', lessonId: 'de-A1-numbers-01',
          cefrLevel: 'A1', skillTag: 'vocabulary/numbers',
          prompt: '"How old are you?" in German is…',
          options: ['Wie alt bist du?', 'Wie heißt du?', 'Woher kommst du?', 'Wie geht es dir?'],
          correctIndex: 0,
        ),
      ],
    ),
    Lesson(
      id:               'de-A1-daily-life-01',
      title:            'Daily Life',
      description:      'Essential German words for everyday situations.',
      courseLanguage:   'de',
      cefrLevel:        'A1',
      skillTag:         'vocabulary/daily-life',
      estimatedMinutes: 5,
      xpReward:         35,
      questions: const [
        MultipleChoiceQuestion(
          id: 'q1', lessonId: 'de-A1-daily-life-01',
          cefrLevel: 'A1', skillTag: 'vocabulary/daily-life',
          prompt: '"Water" in German is…',
          options: ['Wasser', 'Brot', 'Milch', 'Kaffee'],
          correctIndex: 0,
        ),
        MultipleChoiceQuestion(
          id: 'q2', lessonId: 'de-A1-daily-life-01',
          cefrLevel: 'A1', skillTag: 'vocabulary/daily-life',
          prompt: '"I am hungry" in German is…',
          options: ['Ich habe Hunger', 'Ich bin müde', 'Ich habe Durst', 'Ich bin krank'],
          correctIndex: 0,
        ),
        WordOrderQuestion(
          id: 'q3', lessonId: 'de-A1-daily-life-01',
          cefrLevel: 'A1', skillTag: 'grammar/sentence-structure',
          prompt: 'Arrange into a correct sentence.',
          shuffledWords: ['Kaffee', 'Ich', 'trinke', 'jeden', 'Morgen'],
          correctOrder:  [1, 2, 0, 3, 4],
        ),
        MultipleChoiceQuestion(
          id: 'q4', lessonId: 'de-A1-daily-life-01',
          cefrLevel: 'A1', skillTag: 'vocabulary/daily-life',
          prompt: '"Where is the toilet?" in German is…',
          options: ['Wo ist die Toilette?', 'Was kostet das?', 'Wie spät ist es?', 'Wo bin ich?'],
          correctIndex: 0,
        ),
      ],
    ),
    Lesson(
      id:               'de-A1-food-01',
      title:            'Food & Drink',
      description:      'Order food and drinks in German.',
      courseLanguage:   'de',
      cefrLevel:        'A1',
      skillTag:         'vocabulary/food',
      estimatedMinutes: 5,
      xpReward:         35,
      questions: const [
        MultipleChoiceQuestion(
          id: 'q1', lessonId: 'de-A1-food-01',
          cefrLevel: 'A1', skillTag: 'vocabulary/food',
          prompt: '"Bread" in German is…',
          options: ['Brot', 'Käse', 'Wurst', 'Butter'],
          correctIndex: 0,
        ),
        MultipleChoiceQuestion(
          id: 'q2', lessonId: 'de-A1-food-01',
          cefrLevel: 'A1', skillTag: 'vocabulary/food',
          prompt: '"I would like a beer" in German is…',
          options: ['Ich hätte gern ein Bier', 'Ich trinke Wein', 'Ein Kaffee bitte', 'Ich esse Wurst'],
          correctIndex: 0,
        ),
        WordOrderQuestion(
          id: 'q3', lessonId: 'de-A1-food-01',
          cefrLevel: 'A1', skillTag: 'vocabulary/food',
          prompt: 'Arrange into a correct sentence.',
          shuffledWords: ['bitte', 'Die', 'Rechnung'],
          correctOrder:  [1, 2, 0],
        ),
        MultipleChoiceQuestion(
          id: 'q4', lessonId: 'de-A1-food-01',
          cefrLevel: 'A1', skillTag: 'vocabulary/food',
          prompt: '"Breakfast" in German is…',
          options: ['Frühstück', 'Mittagessen', 'Abendessen', 'Snack'],
          correctIndex: 0,
        ),
      ],
    ),
  ],
};

Lesson get kSeedLesson => kLessonsByLanguage['es']!.first;
