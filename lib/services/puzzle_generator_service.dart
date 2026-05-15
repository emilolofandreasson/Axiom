import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flick_sdk/flick_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/puzzle_level.dart';

/// Generates AI-based puzzle levels for languages that have no hardcoded content.
/// Levels are cached in SharedPreferences so generation only happens once per language.
class PuzzleGeneratorService {
  PuzzleGeneratorService({required this.bridge});

  final EdgeAiBridge bridge;

  static const _kCachePrefix  = 'ai_puzzle_levels_';
  static const _kPairsPerLevel = 6;
  static const _kLevelCount    = 5;

  // ----- public API -------------------------------------------------------

  /// Returns cached levels if available, otherwise generates and caches them.
  Future<List<PuzzleLevel>> levelsForLanguage({
    required String languageCode,
    required String languageName,
  }) async {
    final cached = await _loadCache(languageCode);
    if (cached != null) return cached;

    final generated = await _generate(
      languageCode: languageCode,
      languageName: languageName,
    );
    if (generated.isNotEmpty) {
      await _saveCache(languageCode, generated);
    }
    return generated;
  }

  /// Returns true if levels are already cached (no network needed).
  Future<bool> isCached(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('$_kCachePrefix$languageCode');
  }

  /// Clear cached levels (e.g., for refresh / debug).
  Future<void> clearCache(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_kCachePrefix$languageCode');
  }

  // ----- private helpers --------------------------------------------------

  Future<List<PuzzleLevel>?> _loadCache(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw   = prefs.getString('$_kCachePrefix$languageCode');
      if (raw == null) return null;
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return list.map(_levelFromMap).toList();
    } catch (e) {
      debugPrint('[PuzzleGenerator] cache read error: $e');
      return null;
    }
  }

  Future<void> _saveCache(String languageCode, List<PuzzleLevel> levels) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data  = levels.map(_levelToMap).toList();
      await prefs.setString('$_kCachePrefix$languageCode', jsonEncode(data));
    } catch (e) {
      debugPrint('[PuzzleGenerator] cache write error: $e');
    }
  }

  Future<List<PuzzleLevel>> _generate({
    required String languageCode,
    required String languageName,
  }) async {
    // CEFR tiers for the 5 levels
    const cefrTiers = ['A1', 'A1', 'A2', 'A2', 'B1'];

    final allLevels = <PuzzleLevel>[];

    for (var i = 0; i < _kLevelCount; i++) {
      final cefr    = cefrTiers[i];
      final prompt  = _buildPrompt(
        languageName: languageName,
        languageCode: languageCode,
        cefrLevel:    cefr,
        levelNumber:  i + 1,
        totalPairs:   _kPairsPerLevel,
      );

      try {
        final result = await bridge.complete(InferenceRequest(
          prompt:      prompt,
          maxTokens:   600,
          temperature: 0.4,
        ));

        if (!result.isSuccess || result.text.isEmpty) continue;

        final pairs = _parsePairs(result.text);
        if (pairs.isEmpty) continue;

        allLevels.add(PuzzleLevel(
          id:             'ai-$languageCode-l${i + 1}',
          levelNumber:    i + 1,
          title:          _titleForLevel(i, languageName),
          courseLanguage: languageCode,
          cefrLevel:      cefr,
          pairs:          pairs,
          xpReward:       10 + i * 5,
          unlocksAfter:   i == 0 ? null : 'ai-$languageCode-l$i',
        ));
      } catch (e) {
        debugPrint('[PuzzleGenerator] level $i error: $e');
      }
    }

    return allLevels;
  }

  String _buildPrompt({
    required String languageName,
    required String languageCode,
    required String cefrLevel,
    required int levelNumber,
    required int totalPairs,
  }) =>
      'Generate $totalPairs unique translation word pairs for a student learning '
      '$languageName ($languageCode) at CEFR level $cefrLevel. '
      'Level $levelNumber — use ${cefrLevel == "A1" ? "very basic everyday" : cefrLevel == "A2" ? "common" : "intermediate"} vocabulary.\n\n'
      'Return ONLY a valid JSON array, no markdown fences:\n'
      '[{"source":"hello","target":"hola"},{"source":"goodbye","target":"adiós"},...]\n'
      'source = English word/phrase, target = $languageName word/phrase.\n'
      'Use short words (1–3 words each). Do not repeat vocabulary across pairs.';

  List<WordPair> _parsePairs(String raw) {
    try {
      final clean = raw
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();
      final list = jsonDecode(clean) as List;
      return list
          .whereType<Map>()
          .map((m) {
            final src = m['source']?.toString().trim() ?? '';
            final tgt = m['target']?.toString().trim() ?? '';
            if (src.isEmpty || tgt.isEmpty) return null;
            return WordPair(
              id:         '${src}_$tgt'.replaceAll(' ', '_'),
              sourceWord: src,
              targetWord: tgt,
            );
          })
          .whereType<WordPair>()
          .toList();
    } catch (e) {
      debugPrint('[PuzzleGenerator] pair parse error: $e\nRaw: $raw');
      return [];
    }
  }

  String _titleForLevel(int index, String language) {
    const titles = [
      'First Words',
      'Everyday Basics',
      'Getting Around',
      'Useful Phrases',
      'Building Fluency',
    ];
    return titles[index % titles.length];
  }

  // ----- serialisation helpers --------------------------------------------

  Map<String, dynamic> _levelToMap(PuzzleLevel l) => {
        'id':             l.id,
        'levelNumber':    l.levelNumber,
        'title':          l.title,
        'courseLanguage': l.courseLanguage,
        'cefrLevel':      l.cefrLevel,
        'xpReward':       l.xpReward,
        'unlocksAfter':   l.unlocksAfter,
        'pairs': l.pairs
            .map((p) => {
                  'id':         p.id,
                  'sourceWord': p.sourceWord,
                  'targetWord': p.targetWord,
                })
            .toList(),
      };

  PuzzleLevel _levelFromMap(Map<String, dynamic> m) => PuzzleLevel(
        id:             m['id']             as String,
        levelNumber:    m['levelNumber']    as int,
        title:          m['title']          as String,
        courseLanguage: m['courseLanguage'] as String,
        cefrLevel:      m['cefrLevel']      as String,
        xpReward:       m['xpReward']       as int? ?? 20,
        unlocksAfter:   m['unlocksAfter']   as String?,
        pairs: (m['pairs'] as List)
            .cast<Map<String, dynamic>>()
            .map((p) => WordPair(
                  id:         p['id']         as String,
                  sourceWord: p['sourceWord'] as String,
                  targetWord: p['targetWord'] as String,
                ))
            .toList(),
      );
}
