import 'package:flutter/foundation.dart';

@immutable
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.unlockedAt,
  });

  final String id;
  final String title;
  final String description;
  final String icon; // emoji
  final DateTime? unlockedAt;

  bool get isUnlocked => unlockedAt != null;

  // Define all achievements
  static const all = {
    // Lessons
    'first_lesson': Achievement(
      id: 'first_lesson',
      title: 'First Step',
      description: 'Complete your first lesson',
      icon: '📚',
    ),
    'lessons_10': Achievement(
      id: 'lessons_10',
      title: 'Learner',
      description: 'Complete 10 lessons',
      icon: '🌱',
    ),
    'lessons_50': Achievement(
      id: 'lessons_50',
      title: 'Student',
      description: 'Complete 50 lessons',
      icon: '🎓',
    ),
    'lessons_100': Achievement(
      id: 'lessons_100',
      title: 'Scholar',
      description: 'Complete 100 lessons',
      icon: '📖',
    ),
    // Streaks
    'streak_3': Achievement(
      id: 'streak_3',
      title: 'On Fire',
      description: 'Build a 3-day streak',
      icon: '🔥',
    ),
    'streak_7': Achievement(
      id: 'streak_7',
      title: 'Week Warrior',
      description: 'Build a 7-day streak',
      icon: '⚔️',
    ),
    'streak_30': Achievement(
      id: 'streak_30',
      title: 'Unstoppable',
      description: 'Build a 30-day streak',
      icon: '🚀',
    ),
    // XP
    'xp_100': Achievement(
      id: 'xp_100',
      title: 'Century',
      description: 'Earn 100 XP',
      icon: '💯',
    ),
    'xp_500': Achievement(
      id: 'xp_500',
      title: 'Milestone',
      description: 'Earn 500 XP',
      icon: '🏔️',
    ),
    'xp_1000': Achievement(
      id: 'xp_1000',
      title: 'Legend',
      description: 'Earn 1,000 XP',
      icon: '👑',
    ),
    // Other
    'first_language': Achievement(
      id: 'first_language',
      title: 'Polyglot Beginner',
      description: 'Start learning your first language',
      icon: '🌍',
    ),
    'polyglot': Achievement(
      id: 'polyglot',
      title: 'Polyglot',
      description: 'Start learning 2 or more languages',
      icon: '🗣️',
    ),
    'perfectionist': Achievement(
      id: 'perfectionist',
      title: 'Perfectionist',
      description: 'Complete a lesson with 100% accuracy',
      icon: '✨',
    ),
  };

  static Achievement? get(String id) => all[id];
  static List<Achievement> getAllSorted() {
    return all.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
  }
}
