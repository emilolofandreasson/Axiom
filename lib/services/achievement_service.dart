import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/achievement.dart';

class AchievementService {
  SupabaseClient get _db => Supabase.instance.client;

  String? get _uid => _db.auth.currentUser?.id;

  /// Fetch all unlocked achievements for the current user.
  Future<Set<String>> getUnlockedAchievementIds() async {
    final uid = _uid;
    if (uid == null) return {};

    try {
      final rows = await _db
          .from('achievements')
          .select('id')
          .eq('user_id', uid);
      return Set.from((rows as List).map((r) => r['id'] as String));
    } catch (e) {
      debugPrint('[AchievementService] fetch error: $e');
      return {};
    }
  }

  /// Stream of unlocked achievement IDs (realtime).
  Stream<Set<String>> watchUnlockedAchievements() {
    final uid = _uid;
    if (uid == null) {
      return Stream.value({});
    }

    return _db
        .from('achievements')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .map((rows) => Set.from(rows.map((r) => r['id'] as String)))
        .handleError((e) {
          debugPrint('[AchievementService] stream error: $e');
        });
  }

  /// Unlock an achievement. Returns true if newly unlocked, false if already unlocked.
  Future<bool> unlock(String achievementId) async {
    final uid = _uid;
    if (uid == null) return false;

    // Check if already unlocked
    final existing = await _db
        .from('achievements')
        .select('id')
        .eq('user_id', uid)
        .eq('id', achievementId)
        .maybeSingle();

    if (existing != null) {
      return false; // Already unlocked
    }

    try {
      await _db.from('achievements').insert({
        'id': achievementId,
        'user_id': uid,
      });
      return true; // Newly unlocked
    } catch (e) {
      debugPrint('[AchievementService] unlock error: $e');
      return false;
    }
  }

  /// Check and unlock an achievement if condition is met.
  /// Returns the achievement if newly unlocked, null otherwise.
  Future<Achievement?> checkAndUnlock({
    required String achievementId,
    required bool condition,
  }) async {
    if (!condition) return null;
    final unlocked = await unlock(achievementId);
    if (unlocked) {
      return Achievement.get(achievementId);
    }
    return null;
  }
}
