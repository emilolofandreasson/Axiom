import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flick_sdk/flick_sdk.dart';
import '../models/puzzle_level.dart';

class SagaState {
  const SagaState({
    this.completedIds  = const {},
    this.retries       = const {},
    this.totalXp       = 0,
    this.streakCount   = 0,
    this.revealPowerups = 1,
  });

  final Set<String> completedIds;
  final Map<String, int> retries; // levelId → retry count
  final int totalXp;
  final int streakCount;   // consecutive clean completions
  final int revealPowerups;

  bool isUnlocked(PuzzleLevel level) {
    if (level.unlocksAfter == null) return true;
    return completedIds.contains(level.unlocksAfter);
  }

  bool isCompleted(String levelId) => completedIds.contains(levelId);

  int retriesFor(String levelId) => retries[levelId] ?? 0;

  SagaState copyWith({
    Set<String>? completedIds,
    Map<String, int>? retries,
    int? totalXp,
    int? streakCount,
    int? revealPowerups,
  }) =>
      SagaState(
        completedIds:   completedIds   ?? this.completedIds,
        retries:        retries        ?? this.retries,
        totalXp:        totalXp        ?? this.totalXp,
        streakCount:    streakCount    ?? this.streakCount,
        revealPowerups: revealPowerups ?? this.revealPowerups,
      );
}

class SagaNotifier extends Notifier<SagaState> {
  @override
  SagaState build() => const SagaState();

  void completeLevel(String levelId, int xpReward) {
    final noRetries = (state.retries[levelId] ?? 0) == 0;
    final newStreak = noRetries ? state.streakCount + 1 : 0;
    // Award a Reveal powerup every 3 clean completions.
    final earnedPowerup = newStreak > 0 && newStreak % 3 == 0;
    final previousStreak = state.streakCount;

    state = state.copyWith(
      completedIds:   {...state.completedIds, levelId},
      totalXp:        state.totalXp + xpReward,
      streakCount:    newStreak,
      revealPowerups: state.revealPowerups + (earnedPowerup ? 1 : 0),
    );
    EventSensor.instance.emit('streak_updated', {
      'new_streak':      newStreak,
      'previous_streak': previousStreak,
      'level_id':        levelId,
      'clean_run':       noRetries,
    });
  }

  void recordRetry(String levelId) {
    final previousStreak = state.streakCount;
    final updated = Map<String, int>.from(state.retries);
    updated[levelId] = (updated[levelId] ?? 0) + 1;
    state = state.copyWith(retries: updated, streakCount: 0);
    EventSensor.instance.emit('streak_updated', {
      'new_streak':      0,
      'previous_streak': previousStreak,
      'level_id':        levelId,
      'clean_run':       false,
    });
  }

  // Returns false if no powerups remain.
  bool useRevealPowerup() {
    if (state.revealPowerups <= 0) return false;
    state = state.copyWith(revealPowerups: state.revealPowerups - 1);
    return true;
  }
}

final sagaProvider =
    NotifierProvider<SagaNotifier, SagaState>(SagaNotifier.new);
