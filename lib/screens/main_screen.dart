import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flick_sdk/flick_sdk.dart';
import '../core/theme/app_theme.dart';
import '../providers/review_provider.dart';
import '../providers/achievement_provider.dart';
import '../models/achievement.dart';
import '../widgets/achievement_toast.dart';
import 'home_screen.dart';
import 'daily_lesson_screen.dart';
import 'review_screen.dart';
import 'saga_map_screen.dart';
import 'profile_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  late int _index;

  final _screens = const [
    HomeScreen(),
    DailyLessonScreen(),
    ReviewScreen(),
    SagaMapScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final reviewCount = ref.watch(reviewProvider).length;

    // Listen for achievement unlocks
    ref.listen(unlockedAchievementsProvider, (previous, next) {
      next.whenData((newIds) {
        if (previous == null) return; // Skip first build
        previous.whenData((oldIds) {
          final newly = newIds.difference(oldIds);
          for (final id in newly) {
            final achievement = Achievement.get(id);
            if (achievement != null) {
              _showAchievementToast(context, achievement);
            }
          }
        });
      });
    });

    return Scaffold(
      backgroundColor: FlickColors.background,
      body: IndexedStack(
        index: _index,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor:       FlickColors.background,
        indicatorColor:        FlickColors.primaryDim,
        selectedIndex:         _index,
        onDestinationSelected: (i) {
          setState(() => _index = i);
          const names = ['home', 'learn', 'review', 'path', 'profile'];
          EventSensor.instance.emit('tab_viewed', {
            'tab':         names[i],
            'hour_of_day': DateTime.now().hour,
          });
        },
        destinations: [
          const NavigationDestination(
            icon:         Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label:        'Home',
          ),
          const NavigationDestination(
            icon:         Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label:        'Learn',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: reviewCount > 0,
              label: Text('$reviewCount'),
              child: const Icon(Icons.replay_rounded),
            ),
            selectedIcon: Badge(
              isLabelVisible: reviewCount > 0,
              label: Text('$reviewCount'),
              child: const Icon(Icons.replay_rounded),
            ),
            label: 'Review',
          ),
          const NavigationDestination(
            icon:         Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route_rounded),
            label:        'Path',
          ),
          const NavigationDestination(
            icon:         Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label:        'Profile',
          ),
        ],
      ),
    );
  }

  void _showAchievementToast(BuildContext context, Achievement achievement) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: AchievementToast(achievement: achievement),
      ),
    );
    Future.delayed(const Duration(seconds: 4), () {
      if (context.mounted) Navigator.of(context).pop();
    });
  }
}
