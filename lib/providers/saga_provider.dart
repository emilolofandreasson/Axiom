import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flick_sdk/flick_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/language_level.dart';
import '../models/puzzle_level.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class SagaState {
  const SagaState({
    this.completedIds   = const {},
    this.retries        = const {},
    this.xpByLanguage   = const {},
    this.streakCount    = 0,
    this.revealPowerups = 1,
    this.lastActiveDate,
    this.isLoading      = false,
  });

  final Set<String>      completedIds;
  final Map<String, int> retries;
  final Map<String, int> xpByLanguage;   // language code → per-language XP
  final int              streakCount;
  final int              revealPowerups;
  final String?          lastActiveDate; // 'yyyy-MM-dd'
  final bool             isLoading;

  /// Total XP across all languages — used for streaks / leaderboard.
  int get totalXp => xpByLanguage.values.fold(0, (s, v) => s + v);

  /// XP for a single language (0 if never studied).
  int xpForLanguage(String langCode) => xpByLanguage[langCode] ?? 0;

  bool isUnlocked(PuzzleLevel level) {
    if (level.unlocksAfter == null) return true;
    return completedIds.contains(level.unlocksAfter);
  }

  bool isCompleted(String levelId) => completedIds.contains(levelId);
  int  retriesFor(String levelId)  => retries[levelId] ?? 0;

  SagaState copyWith({
    Set<String>?      completedIds,
    Map<String, int>? retries,
    Map<String, int>? xpByLanguage,
    int?              streakCount,
    int?              revealPowerups,
    String?           lastActiveDate,
    bool?             isLoading,
  }) =>
      SagaState(
        completedIds:   completedIds   ?? this.completedIds,
        retries:        retries        ?? this.retries,
        xpByLanguage:   xpByLanguage   ?? this.xpByLanguage,
        streakCount:    streakCount    ?? this.streakCount,
        revealPowerups: revealPowerups ?? this.revealPowerups,
        lastActiveDate: lastActiveDate ?? this.lastActiveDate,
        isLoading:      isLoading      ?? this.isLoading,
      );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class SagaNotifier extends Notifier<SagaState> {
  static const _kXpMap      = 'saga_xp_by_language';
  static const _kLegacyXp   = 'saga_total_xp';
  static const _kIds        = 'saga_completed_ids';
  static const _kStreak     = 'saga_streak_count';
  static const _kPowers     = 'saga_reveal_powerups';
  static const _kLastDate   = 'saga_last_active_date';

  static String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  @override
  SagaState build() {
    _load();
    return const SagaState(isLoading: true);
  }

  // ---------------------------------------------------------------------------
  // Load — SharedPreferences first, Firestore fallback
  // ---------------------------------------------------------------------------

  Future<void> _load() async {
    final prefs  = await SharedPreferences.getInstance();
    final xpJson = prefs.getString(_kXpMap);

    Map<String, int> xpByLanguage;

    if (xpJson != null) {
      final decoded = jsonDecode(xpJson) as Map<String, dynamic>;
      xpByLanguage  = decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
    } else {
      // Migration: old clients stored a single global int under saga_total_xp.
      // Attribute it to Spanish — the app default and most common test language.
      final legacy = prefs.getInt(_kLegacyXp) ?? 0;
      xpByLanguage  = legacy > 0 ? {'es': legacy} : {};
      if (legacy > 0) {
        await prefs.setString(_kXpMap, jsonEncode(xpByLanguage));
      }
    }

    final streak   = prefs.getInt(_kStreak)              ?? 0;
    final powers   = prefs.getInt(_kPowers)              ?? 1;
    final ids      = prefs.getStringList(_kIds)          ?? [];
    final lastDate = prefs.getString(_kLastDate);

    if (xpByLanguage.isEmpty && ids.isEmpty) {
      // Local data is empty — try Firestore as the authoritative source.
      await _loadFromSupabase(prefs);
    } else {
      state = SagaState(
        xpByLanguage:   xpByLanguage,
        completedIds:   Set<String>.from(ids),
        streakCount:    streak,
        revealPowerups: powers,
        lastActiveDate: lastDate,
        isLoading:      false,
      );
      _checkDailyStreak(prefs, streak, lastDate);
    }
  }

  Future<void> _loadFromSupabase(SharedPreferences prefs) async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) { state = const SagaState(isLoading: false); return; }

      final row = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', uid)
          .maybeSingle();

      if (row == null) { state = const SagaState(isLoading: false); return; }

      // xp_by_language is JSONB — Supabase client returns it as Map<String, dynamic>.
      final rawMap = row['xp_by_language'] as Map<String, dynamic>?;
      final xpByLanguage = rawMap != null
          ? rawMap.map((k, v) => MapEntry(k, (v as num).toInt()))
          : <String, int>{};

      final streak   = (row['streak_count']    as num?)?.toInt() ?? 0;
      final powers   = (row['reveal_powerups'] as num?)?.toInt() ?? 1;
      final ids      = (row['completed_ids']   as List?)?.cast<String>() ?? [];
      final lastDate = row['last_active_date'] as String?;

      await prefs.setString(_kXpMap, jsonEncode(xpByLanguage));
      await prefs.setInt(_kStreak,             streak);
      await prefs.setInt(_kPowers,             powers);
      await prefs.setStringList(_kIds,         ids);
      if (lastDate != null) await prefs.setString(_kLastDate, lastDate);

      state = SagaState(
        xpByLanguage:   xpByLanguage,
        completedIds:   Set<String>.from(ids),
        streakCount:    streak,
        revealPowerups: powers,
        lastActiveDate: lastDate,
        isLoading:      false,
      );
      _checkDailyStreak(prefs, streak, lastDate);
      debugPrint('[SagaNotifier] loaded from Supabase — totalXp: ${state.totalXp}');
    } catch (e) {
      debugPrint('[SagaNotifier] Supabase load failed: $e');
      state = const SagaState(isLoading: false);
    }
  }

  void _checkDailyStreak(
      SharedPreferences prefs, int currentStreak, String? lastDate) {
    final today = _todayKey();
    if (lastDate == today) return; // already active today

    final yesterday = () {
      final y = DateTime.now().subtract(const Duration(days: 1));
      return '${y.year}-${y.month.toString().padLeft(2, '0')}-${y.day.toString().padLeft(2, '0')}';
    }();

    // Only reset streak if user missed a day — do NOT update lastActiveDate here.
    // lastActiveDate is updated when the user actually completes a lesson/puzzle.
    if (lastDate != yesterday) {
      state = state.copyWith(streakCount: 0);
      prefs.setInt(_kStreak, 0);
    }
  }

  // ---------------------------------------------------------------------------
  // Save — local + Firestore
  // ---------------------------------------------------------------------------

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_kXpMap,    jsonEncode(state.xpByLanguage)),
      prefs.setStringList(_kIds,  state.completedIds.toList()),
      prefs.setInt(_kStreak,      state.streakCount),
      prefs.setInt(_kPowers,      state.revealPowerups),
      if (state.lastActiveDate != null)
        prefs.setString(_kLastDate, state.lastActiveDate!),
    ]);
    unawaited(_syncToSupabase());
    unawaited(_enrichUserProfile());
  }

  Future<void> _syncToSupabase() async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;
      await Supabase.instance.client.from('users').upsert({
        'id':              uid,
        'xp_by_language':  state.xpByLanguage,
        'streak_count':    state.streakCount,
        'reveal_powerups': state.revealPowerups,
        'completed_ids':   state.completedIds.toList(),
        'last_active_date':state.lastActiveDate,
        'updated_at':      DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[SagaNotifier] Supabase sync failed: $e');
    }
  }

  // Derived profile fields written to Supabase users table.
  // Used for partner data exports — see DataSteve in AGENTS.md.
  Future<void> _enrichUserProfile() async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;

      // Language with most XP = strongest destination intent signal.
      String? preferredLanguage;
      if (state.xpByLanguage.isNotEmpty) {
        preferredLanguage = state.xpByLanguage.entries
            .reduce((a, b) => a.value >= b.value ? a : b)
            .key;
      }

      // Engagement tier based on streak count.
      final tier = state.streakCount >= 10
          ? 'dedicated'
          : state.streakCount >= 3
              ? 'regular'
              : 'casual';

      // Highest CEFR across all languages.
      String learningStage = 'beginner';
      if (state.xpByLanguage.isNotEmpty) {
        final maxXp = state.xpByLanguage.values.reduce((a, b) => a > b ? a : b);
        final cefr  = cefrCodeForXp(maxXp);
        learningStage = switch (cefr) {
          'B1' || 'B2' => 'intermediate',
          'C1' || 'C2' => 'advanced',
          _            => 'beginner',
        };
      }

      // language_count: number of distinct languages studied (partner signal).
      final languageCount = state.xpByLanguage.values
          .where((xp) => xp > 0)
          .length;

      await Supabase.instance.client.from('users').update({
        'preferred_language': preferredLanguage,
        'engagement_tier':    tier,
        'learning_stage':     learningStage,
        'last_active_at':     DateTime.now().toUtc().toIso8601String(),
        'total_xp':           state.totalXp,
        'streak_count':       state.streakCount,
        // DataSteve: derived signals for partner exports
        'language_count':     languageCount,
      }).eq('id', uid);
    } catch (e) {
      debugPrint('[SagaNotifier] profile enrichment failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Public mutations
  // ---------------------------------------------------------------------------

  Future<void> completeLevel(
    String levelId,
    int xpReward, {
    required String languageCode,
  }) async {
    final noRetries      = (state.retries[levelId] ?? 0) == 0;
    final today          = _todayKey();
    final previousStreak = state.streakCount;
    // Guard: only increment streak once per calendar day (same logic as awardLessonXp).
    final newStreak = noRetries
        ? (state.lastActiveDate == today ? state.streakCount : state.streakCount + 1)
        : 0;
    final earnedPowerup  = newStreak > 0 && newStreak % 3 == 0;

    final updated = Map<String, int>.from(state.xpByLanguage);
    updated[languageCode] = (updated[languageCode] ?? 0) + xpReward;

    state = state.copyWith(
      completedIds:   {...state.completedIds, levelId},
      xpByLanguage:   updated,
      streakCount:    newStreak,
      revealPowerups: state.revealPowerups + (earnedPowerup ? 1 : 0),
      lastActiveDate: today,
    );

    EventSensor.instance.emit('streak_updated', {
      'new_streak':      newStreak,
      'previous_streak': previousStreak,
      'level_id':        levelId,
      'clean_run':       noRetries,
    });
    await _save();
  }

  Future<void> awardLessonXp(
    int xpReward, {
    required String languageCode,
  }) async {
    final today          = _todayKey();
    final previousStreak = state.streakCount;
    final newStreak      = state.lastActiveDate == today
        ? state.streakCount
        : state.streakCount + 1;

    final updated = Map<String, int>.from(state.xpByLanguage);
    updated[languageCode] = (updated[languageCode] ?? 0) + xpReward;

    state = state.copyWith(
      xpByLanguage:   updated,
      streakCount:    newStreak,
      lastActiveDate: today,
    );

    if (newStreak != previousStreak) {
      EventSensor.instance.emit('streak_updated', {
        'new_streak':      newStreak,
        'previous_streak': previousStreak,
        'level_id':        'lesson',
        'clean_run':       true,
      });
    }
    await _save();
  }

  Future<void> recordRetry(String levelId) async {
    final previousStreak = state.streakCount;
    final updated        = Map<String, int>.from(state.retries);
    updated[levelId]     = (updated[levelId] ?? 0) + 1;
    state = state.copyWith(retries: updated, streakCount: 0);
    EventSensor.instance.emit('streak_updated', {
      'new_streak':      0,
      'previous_streak': previousStreak,
      'level_id':        levelId,
      'clean_run':       false,
    });
    await _save();
  }

  Future<bool> useRevealPowerup() async {
    if (state.revealPowerups <= 0) return false;
    state = state.copyWith(revealPowerups: state.revealPowerups - 1);
    await _save();
    return true;
  }
}

void unawaited(Future<void> future) => future;

final sagaProvider =
    NotifierProvider<SagaNotifier, SagaState>(SagaNotifier.new);
