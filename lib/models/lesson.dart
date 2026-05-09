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
final kSeedLesson = Lesson(
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
);
