import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/achievement.dart';
import '../providers/achievement_provider.dart';
import '../core/theme/app_theme.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlockedIds = ref.watch(unlockedAchievementsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        elevation: 0,
        backgroundColor: FlickColors.background,
      ),
      backgroundColor: FlickColors.background,
      body: unlockedIds.when(
        data: (ids) => _AchievementGrid(unlockedIds: ids),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _AchievementGrid extends StatelessWidget {
  const _AchievementGrid({required this.unlockedIds});

  final Set<String> unlockedIds;

  @override
  Widget build(BuildContext context) {
    final achievements = Achievement.getAllSorted();
    final unlockedCount = unlockedIds.length;
    final totalCount = achievements.length;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$unlockedCount / $totalCount Unlocked',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: unlockedCount / totalCount,
                  minHeight: 8,
                  backgroundColor: FlickColors.neutral200,
                  valueColor: AlwaysStoppedAnimation(FlickColors.success),
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final achievement = achievements[index];
                final isUnlocked = unlockedIds.contains(achievement.id);
                return _AchievementCard(
                  achievement: achievement,
                  isUnlocked: isUnlocked,
                );
              },
              childCount: achievements.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({
    required this.achievement,
    required this.isUnlocked,
  });

  final Achievement achievement;
  final bool isUnlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isUnlocked ? FlickColors.primary : FlickColors.neutral100,
        borderRadius: BorderRadius.circular(FlickRadius.lg),
        border: Border.all(
          color: isUnlocked ? FlickColors.primary : FlickColors.neutral200,
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                achievement.icon,
                style: TextStyle(
                  fontSize: 48,
                  opacity: isUnlocked ? 1.0 : 0.3,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  achievement.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isUnlocked ? Colors.white : FlickColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (!isUnlocked)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: FlickColors.textSecondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(FlickRadius.lg),
                ),
                child: const Center(
                  child: Icon(
                    Icons.lock,
                    color: FlickColors.textSecondary,
                    size: 24,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
