import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kDefaultDailyXpGoal = 20;
const kDailyXpGoal        = kDefaultDailyXpGoal; // kept for back-compat reads

class DailyGoalState {
  const DailyGoalState({
    this.xpToday = 0,
    this.goalXp  = kDefaultDailyXpGoal,
    this.goalMet = false,
  });

  final int  xpToday;
  final int  goalXp;
  final bool goalMet;

  double get progress => goalXp == 0 ? 0.0 : (xpToday / goalXp).clamp(0.0, 1.0);
}

class DailyGoalNotifier extends Notifier<DailyGoalState> {
  static const _kXpToday = 'daily_xp_today';
  static const _kDate    = 'daily_xp_date';
  static const _kGoal    = 'daily_xp_goal';

  @override
  DailyGoalState build() {
    _load();
    return const DailyGoalState();
  }

  Future<void> _load() async {
    final prefs     = await SharedPreferences.getInstance();
    final today     = _todayKey();
    final savedDate = prefs.getString(_kDate);
    final goalXp    = prefs.getInt(_kGoal) ?? kDefaultDailyXpGoal;

    if (savedDate != today) {
      await prefs.setInt(_kXpToday, 0);
      await prefs.setString(_kDate, today);
      state = DailyGoalState(goalXp: goalXp);
    } else {
      final xp = prefs.getInt(_kXpToday) ?? 0;
      state = DailyGoalState(xpToday: xp, goalXp: goalXp, goalMet: xp >= goalXp);
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
      goalXp:  state.goalXp,
      goalMet: newXp >= state.goalXp,
    );
  }

  Future<void> setGoal(int goalXp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kGoal, goalXp);
    state = DailyGoalState(
      xpToday: state.xpToday,
      goalXp:  goalXp,
      goalMet: state.xpToday >= goalXp,
    );
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

final dailyGoalProvider =
    NotifierProvider<DailyGoalNotifier, DailyGoalState>(DailyGoalNotifier.new);
