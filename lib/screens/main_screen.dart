import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import 'home_screen.dart';
import 'daily_lesson_screen.dart';
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
    return Scaffold(
      backgroundColor: FlickColors.background,
      body: IndexedStack(
        index: _index,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor:      FlickColors.surface,
        indicatorColor:       FlickColors.primaryDim,
        selectedIndex:        _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon:          Icon(Icons.home_outlined),
            selectedIcon:  Icon(Icons.home_rounded),
            label:         'Home',
          ),
          NavigationDestination(
            icon:          Icon(Icons.menu_book_outlined),
            selectedIcon:  Icon(Icons.menu_book_rounded),
            label:         'Learn',
          ),
          NavigationDestination(
            icon:          Icon(Icons.route_outlined),
            selectedIcon:  Icon(Icons.route_rounded),
            label:         'Path',
          ),
          NavigationDestination(
            icon:          Icon(Icons.person_outline_rounded),
            selectedIcon:  Icon(Icons.person_rounded),
            label:         'Profile',
          ),
        ],
      ),
    );
  }
}
