import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/achievement.dart';
import '../services/achievement_service.dart';

final achievementServiceProvider = Provider((ref) => AchievementService());

/// Stream of unlocked achievement IDs
final unlockedAchievementsProvider = StreamProvider.autoDispose<Set<String>>((ref) {
  final service = ref.watch(achievementServiceProvider);
  return service.watchUnlockedAchievements();
});

/// Specific achievement state: locked or unlocked with date
final achievementProvider = FutureProvider.autoDispose
    .family<Achievement?, String>((ref, id) async {
  final unlockedIds = await ref.watch(unlockedAchievementsProvider.future);
  final achievement = Achievement.get(id);
  if (achievement == null) return null;

  if (!unlockedIds.contains(id)) {
    return achievement;
  }

  // If unlocked, fetch the unlock date from Supabase
  // For now, just mark as unlocked
  return achievement.copyWith(unlockedAt: DateTime.now());
});

extension AchievementX on Achievement {
  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    DateTime? unlockedAt,
  }) =>
      Achievement(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        icon: icon ?? this.icon,
        unlockedAt: unlockedAt ?? this.unlockedAt,
      );
}

/// Notifier to handle unlocking achievements
final achievementNotifierProvider = StateNotifierProvider.autoDispose<
    AchievementNotifier,
    AsyncValue<void>>((ref) {
  final service = ref.watch(achievementServiceProvider);
  return AchievementNotifier(service);
});

class AchievementNotifier extends StateNotifier<AsyncValue<void>> {
  AchievementNotifier(this._service) : super(const AsyncValue.data(null));

  final AchievementService _service;

  Future<Achievement?> checkAndUnlock({
    required String id,
    required bool condition,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return _service.checkAndUnlock(achievementId: id, condition: condition);
    }).then((result) {
      return result.when(
        data: (_) => const AsyncValue.data(null),
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
      );
    });
    return await _service.checkAndUnlock(achievementId: id, condition: condition);
  }
}
