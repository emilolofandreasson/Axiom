import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kMaxHearts = 5;
const _kHearts   = 'hearts_count';
const _kRefillAt = 'hearts_refill_at_ms'; // timestamp when next refill happens

class HeartsState {
  const HeartsState({this.hearts = kMaxHearts, this.refillAt});
  final int      hearts;
  final DateTime? refillAt;

  bool get isFull    => hearts >= kMaxHearts;
  bool get isEmpty   => hearts <= 0;
  Duration get timeUntilRefill =>
      refillAt == null ? Duration.zero :
      refillAt!.isAfter(DateTime.now())
          ? refillAt!.difference(DateTime.now())
          : Duration.zero;
}

class HeartsNotifier extends Notifier<HeartsState> {
  @override
  HeartsState build() {
    _loadAndRefill();
    return const HeartsState();
  }

  Future<void> _loadAndRefill() async {
    final prefs      = await SharedPreferences.getInstance();
    int hearts       = prefs.getInt(_kHearts) ?? kMaxHearts;
    final refillMs   = prefs.getInt(_kRefillAt);
    DateTime? refillAt = refillMs != null
        ? DateTime.fromMillisecondsSinceEpoch(refillMs)
        : null;

    // Refill hearts that have accumulated since last open.
    // Use minute-precision to avoid truncation bug (inHours rounds toward zero).
    if (hearts < kMaxHearts && refillAt != null) {
      final now = DateTime.now();
      if (now.isAfter(refillAt)) {
        // +1 for the refill that was already due at refillAt.
        final earned    = (now.difference(refillAt).inMinutes ~/ 60) + 1;
        final newHearts = (hearts + earned).clamp(0, kMaxHearts);
        hearts   = newHearts;
        refillAt = newHearts >= kMaxHearts
            ? null
            : refillAt.add(Duration(hours: earned));
        await _save(prefs, hearts, refillAt);
      }
    }

    state = HeartsState(hearts: hearts, refillAt: refillAt);
  }

  Future<void> loseHeart() async {
    if (state.isEmpty) return;
    final prefs   = await SharedPreferences.getInstance();
    final hearts  = state.hearts - 1;
    final refillAt = state.refillAt ?? DateTime.now().add(const Duration(hours: 1));
    await _save(prefs, hearts, refillAt);
    state = HeartsState(hearts: hearts, refillAt: refillAt);
  }

  Future<void> refillAll() async {
    final prefs = await SharedPreferences.getInstance();
    await _save(prefs, kMaxHearts, null);
    state = const HeartsState(hearts: kMaxHearts);
  }

  Future<void> _save(SharedPreferences p, int hearts, DateTime? refillAt) async {
    await p.setInt(_kHearts, hearts);
    if (refillAt != null) {
      await p.setInt(_kRefillAt, refillAt.millisecondsSinceEpoch);
    } else {
      await p.remove(_kRefillAt);
    }
  }
}

final heartsProvider =
    NotifierProvider<HeartsNotifier, HeartsState>(HeartsNotifier.new);
