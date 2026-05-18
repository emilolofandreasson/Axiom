import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flick_sdk/flick_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/language.dart';
import 'achievement_provider.dart';

class LanguageNotifier extends Notifier<Language> {
  @override
  Language build() {
    _loadFromPrefs();
    return kLanguages.first;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('selected_language_code');
    if (code != null) {
      state = kLanguages.firstWhere(
        (l) => l.code == code,
        orElse: () => kLanguages.first,
      );
    }
  }

  Future<void> selectLanguage(Language language) async {
    final previous = state.code;
    final now = DateTime.now();
    final isFirstLanguage = previous == language.code; // No change
    state = language;
    EventSensor.instance.emit('language_selected', {
      'language_code':  language.code,
      'language_name':  language.name,
      'previous_code':  previous,
      'hour_of_day':    now.hour,
      'day_of_week':    now.weekday,
    });
    await _saveToPrefs();

    // Check language achievements
    await _checkLanguageAchievements(language.code, previous);
  }

  Future<void> _checkLanguageAchievements(
    String currentLang,
    String previousLang,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final selectedLangsJson = prefs.getString('_selected_languages') ?? '[]';
    final selectedLangs =
        (selectedLangsJson as String).split(',').where((s) => s.isNotEmpty).toSet();

    if (previousLang != currentLang) {
      selectedLangs.add(currentLang);
      await prefs.setString('_selected_languages', selectedLangs.join(','));

      // Unlock achievements
      final achievementService = ref.read(achievementServiceProvider);
      if (selectedLangs.length == 1) {
        await achievementService.unlock('first_language');
      } else if (selectedLangs.length >= 2) {
        await achievementService.unlock('polyglot');
      }
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language_code', state.code);
  }
}

final languageProvider =
    NotifierProvider<LanguageNotifier, Language>(LanguageNotifier.new);
