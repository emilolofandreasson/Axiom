import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// Research-backed 10-step language progression ladder.
//
// Thresholds are calibrated against Council of Europe CEFR data and
// Eurocentres hour estimates:
//   A1 ≈ 0–80 h, A2 ≈ 80–200 h, B1 ≈ 200–350 h,
//   B2 ≈ 350–600 h, C1 ≈ 600–1000 h
//
// Early gaps are generous (fast progress) to maintain motivation.
// Gaps widen polynomially in B/C bands to reflect real acquisition cost.
// ---------------------------------------------------------------------------

@immutable
class LanguageLevel {
  const LanguageLevel({
    required this.index,
    required this.label,
    required this.cefrCode,
    required this.xpThreshold,
    required this.xpReward,
  });

  final int    index;        // 0–9, position in kLanguageLevels
  final String label;        // "A1.1", "B2.2", etc.
  final String cefrCode;     // "A1" | "A2" | "B1" | "B2" | "C1"
  final int    xpThreshold;  // per-language XP needed to enter this level
  final int    xpReward;     // XP awarded per lesson at this level

  bool get isMax => index == kLanguageLevels.length - 1;

  /// XP still needed to reach the next level, given current per-language XP.
  int xpToNextLevel(int currentXp) {
    if (isMax) return 0;
    return kLanguageLevels[index + 1].xpThreshold - currentXp;
  }

  /// Fraction of progress through this level (0.0–1.0).
  double progressFraction(int currentXp) {
    if (isMax) return 1.0;
    final span = kLanguageLevels[index + 1].xpThreshold - xpThreshold;
    if (span <= 0) return 1.0;
    return ((currentXp - xpThreshold) / span).clamp(0.0, 1.0);
  }
}

const kLanguageLevels = <LanguageLevel>[
  LanguageLevel(index: 0, label: 'A1.1', cefrCode: 'A1', xpThreshold:     0, xpReward:  20),
  LanguageLevel(index: 1, label: 'A1.2', cefrCode: 'A1', xpThreshold:   200, xpReward:  25),
  LanguageLevel(index: 2, label: 'A2.1', cefrCode: 'A2', xpThreshold:   500, xpReward:  30),
  LanguageLevel(index: 3, label: 'A2.2', cefrCode: 'A2', xpThreshold:   950, xpReward:  38),
  LanguageLevel(index: 4, label: 'B1.1', cefrCode: 'B1', xpThreshold:  1800, xpReward:  50),
  LanguageLevel(index: 5, label: 'B1.2', cefrCode: 'B1', xpThreshold:  2900, xpReward:  60),
  LanguageLevel(index: 6, label: 'B2.1', cefrCode: 'B2', xpThreshold:  4400, xpReward:  75),
  LanguageLevel(index: 7, label: 'B2.2', cefrCode: 'B2', xpThreshold:  6500, xpReward:  90),
  LanguageLevel(index: 8, label: 'C1.1', cefrCode: 'C1', xpThreshold:  9000, xpReward: 110),
  LanguageLevel(index: 9, label: 'C1.2', cefrCode: 'C1', xpThreshold: 12000, xpReward: 130),
];

/// Returns the level the user currently occupies for a given per-language XP.
LanguageLevel levelForXp(int xp) {
  for (var i = kLanguageLevels.length - 1; i >= 0; i--) {
    if (xp >= kLanguageLevels[i].xpThreshold) return kLanguageLevels[i];
  }
  return kLanguageLevels.first;
}

/// Broad CEFR code for the given XP (passed to AI prompt).
String cefrCodeForXp(int xp) => levelForXp(xp).cefrCode;

/// Human-readable sub-level label, e.g. "B1.2".
String levelLabelForXp(int xp) => levelForXp(xp).label;

/// Numerisk ordning för CEFR-strängar. Används för jämförelser.
int cefrOrder(String cefr) => const {
  'A1': 0, 'A2': 1, 'B1': 2, 'B2': 3, 'C1': 4, 'C2': 5,
}[cefr] ?? 0;

/// Nästa CEFR-nivå i ordningen, eller null om C2.
String? nextCefrLevel(String cefr) => const {
  'A1': 'A2', 'A2': 'B1', 'B1': 'B2', 'B2': 'C1', 'C1': 'C2',
}[cefr];
