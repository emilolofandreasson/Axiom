import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/puzzle_level.dart';
import '../main.dart' show puzzleGenerator;

// State for a single language's generated puzzle levels.
enum GenerationStatus { idle, generating, done, failed }

class GeneratedPuzzlesState {
  const GeneratedPuzzlesState({
    this.levelsByLanguage = const {},
    this.generatingFor    = const {},
  });

  /// language code → AI-generated levels
  final Map<String, List<PuzzleLevel>> levelsByLanguage;
  /// codes currently being generated
  final Set<String> generatingFor;

  bool isGenerating(String code) => generatingFor.contains(code);
  bool hasCached(String code)    => levelsByLanguage.containsKey(code);

  GeneratedPuzzlesState copyWith({
    Map<String, List<PuzzleLevel>>? levelsByLanguage,
    Set<String>? generatingFor,
  }) =>
      GeneratedPuzzlesState(
        levelsByLanguage: levelsByLanguage ?? this.levelsByLanguage,
        generatingFor:    generatingFor    ?? this.generatingFor,
      );
}

class GeneratedPuzzlesNotifier extends Notifier<GeneratedPuzzlesState> {
  @override
  GeneratedPuzzlesState build() => const GeneratedPuzzlesState();

  /// Trigger level generation for a language if not already cached/generating.
  Future<void> ensureLevels({
    required String languageCode,
    required String languageName,
  }) async {
    if (state.hasCached(languageCode) || state.isGenerating(languageCode)) return;

    // Fast path: disk cache already exists — load silently, no spinner needed.
    final alreadyOnDisk = await puzzleGenerator.isCached(languageCode);
    if (alreadyOnDisk) {
      final levels = await puzzleGenerator.levelsForLanguage(
        languageCode: languageCode,
        languageName: languageName,
      );
      if (levels.isNotEmpty) {
        state = state.copyWith(
          levelsByLanguage: {...state.levelsByLanguage, languageCode: levels},
        );
      }
      return;
    }

    // Slow path: nothing on disk — show generating indicator, then call Gemini.
    state = state.copyWith(
      generatingFor: {...state.generatingFor, languageCode},
    );

    try {
      final levels = await puzzleGenerator.levelsForLanguage(
        languageCode: languageCode,
        languageName: languageName,
      );

      final updated = Map<String, List<PuzzleLevel>>.from(state.levelsByLanguage);
      if (levels.isNotEmpty) updated[languageCode] = levels;

      state = state.copyWith(
        levelsByLanguage: updated,
        generatingFor:    state.generatingFor.difference({languageCode}),
      );
    } catch (_) {
      state = state.copyWith(
        generatingFor: state.generatingFor.difference({languageCode}),
      );
    }
  }

  List<PuzzleLevel> levelsFor(String languageCode) =>
      state.levelsByLanguage[languageCode] ?? [];
}

final generatedPuzzlesProvider = NotifierProvider<GeneratedPuzzlesNotifier,
    GeneratedPuzzlesState>(GeneratedPuzzlesNotifier.new);
