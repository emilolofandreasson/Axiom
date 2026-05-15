import 'package:flutter/foundation.dart';

@immutable
class UserProfile {
  const UserProfile({
    required this.uid,
    this.name           = '',
    this.bio            = '',
    this.nativeLanguage = 'en',
    this.photoUrl,
    this.totalXp        = 0,
    this.streakCount    = 0,
    this.geminiApiKey,
    // Persona fields (DataSteve — partner targeting signals)
    this.motivation,
    this.learningGoal,
    this.interests      = const [],
    this.country,
    this.birthYear,
    this.availability,
  });

  final String  uid;
  final String  name;
  final String  bio;
  final String  nativeLanguage;
  final String? photoUrl;
  final int     totalXp;
  final int     streakCount;
  /// User's own Gemini API key — used to contribute questions to global_questions.
  final String? geminiApiKey;

  /// Why they're learning: travel | work | family | culture | fun
  final String?       motivation;
  /// What outcome they want: conversational | business | travel | academic
  final String?       learningGoal;
  /// Interest tags e.g. [food, music, sports]
  final List<String>  interests;
  /// ISO-3166 country code
  final String?       country;
  /// Birth year (analytics only, never displayed)
  final int?          birthYear;
  /// When they prefer to study: morning | afternoon | evening | flexible
  final String?       availability;

  UserProfile copyWith({
    String? name,
    String? bio,
    String? nativeLanguage,
    String? photoUrl,
    int?    totalXp,
    int?    streakCount,
    String?      geminiApiKey,
    String?      motivation,
    String?      learningGoal,
    List<String>? interests,
    String?      country,
    int?         birthYear,
    String?      availability,
  }) => UserProfile(
    uid:            uid,
    name:           name           ?? this.name,
    bio:            bio            ?? this.bio,
    nativeLanguage: nativeLanguage ?? this.nativeLanguage,
    photoUrl:       photoUrl       ?? this.photoUrl,
    totalXp:        totalXp        ?? this.totalXp,
    streakCount:    streakCount    ?? this.streakCount,
    geminiApiKey:   geminiApiKey   ?? this.geminiApiKey,
    motivation:     motivation     ?? this.motivation,
    learningGoal:   learningGoal   ?? this.learningGoal,
    interests:      interests      ?? this.interests,
    country:        country        ?? this.country,
    birthYear:      birthYear      ?? this.birthYear,
    availability:   availability   ?? this.availability,
  );

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) =>
      UserProfile(
        uid:            uid,
        name:           data['name']            as String? ?? '',
        bio:            data['bio']             as String? ?? '',
        nativeLanguage: data['native_language'] as String? ?? 'en',
        photoUrl:       data['photo_url']       as String?,
        totalXp:        data['total_xp']        as int?    ?? 0,
        streakCount:    data['streak_count']    as int?    ?? 0,
        geminiApiKey:   data['gemini_key']       as String?,
        motivation:     data['motivation']      as String?,
        learningGoal:   data['learning_goal']   as String?,
        interests:      (data['interests']      as List?)?.cast<String>() ?? [],
        country:        data['country']         as String?,
        birthYear:      data['birth_year']      as int?,
        availability:   data['availability']    as String?,
      );

  Map<String, dynamic> toMap() => {
    'name':            name,
    'bio':             bio,
    'native_language': nativeLanguage,
    if (photoUrl      != null) 'photo_url':      photoUrl,
    if (geminiApiKey  != null) 'gemini_key':     geminiApiKey,
    if (motivation    != null) 'motivation':     motivation,
    if (learningGoal  != null) 'learning_goal':  learningGoal,
    'interests':       interests,
    if (country       != null) 'country':        country,
    if (birthYear     != null) 'birth_year':     birthYear,
    if (availability  != null) 'availability':   availability,
  };
}
