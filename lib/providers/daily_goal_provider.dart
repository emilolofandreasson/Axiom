import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kDailyXpGoal = 20;

class DailyGoalState {
  const DailyGoalState({this.xpToday = 0, this.goalMet = false});
  final int  xpToday;
  final bool goalMet;

  double get progress => (xpToday / kDailyXpGoal).clamp(0.0, 1.0);
}

class DailyGoalNotifier extends Notifier<DailyGoalState> {
  static const _kXpToday = 'daily_xp_today';
  static const _kDate    = 'daily_xp_date';

  @override
  DailyGoalState build() {
    _load();
    return const DailyGoalState();
  }

  Future<void> _load() async {
    final prefs     = await SharedPreferences.getInstance();
    final today     = _todayKey();
    final savedDate = prefs.getString(_kDate);

    if (savedDate != today) {
      // New day — reset
      await prefs.setInt(_kXpToday, 0);
      await prefs.setString(_kDate, today);
      state = const DailyGoalState();
    } else {
      final xp = prefs.getInt(_kXpToday) ?? 0;
      state = DailyGoalState(xpToday: xp, goalMet: xp >= kDailyXpGoal);
    }
  }

  Future<void> addXp(int amount) async {
    final prefs  = await SharedPreferences.getInstance();
    final today  = _todayKey();
    await prefs.setString(_kDate, today);
    final newXp  = state.xpToday + amount;
    await prefs.setInt(_kXpToday, newXp);
    state = DailyGoalState(
      xpToday: newXp,
      goalMet: newXp >= kDailyXpGoal,
    );
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

final dailyGoalProvider =
    NotifierProvider<DailyGoalNotifier, DailyGoalState>(DailyGoalNotifier.new);
